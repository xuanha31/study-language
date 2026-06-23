import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'models/course.dart';
import 'models/vocab_card.dart';

/// Đọc nội dung học (manifest + các khóa HSK). Offline-first:
/// ưu tiên bản đã tải về (thư mục app) > bundle assets (design.md §7).
/// Cập nhật online (E7): so version từng khóa trong manifest, chỉ tải khóa đổi.
/// Cấu hình server qua --dart-define=CONTENT_BASE_URL=https://...
class ContentRepository {
  static const _base = 'content/';
  static const remoteBaseUrl =
      String.fromEnvironment('CONTENT_BASE_URL', defaultValue: '');

  List<Course>? _coursesCache;
  final Map<String, List<VocabCard>> _cardsCache = {};
  Directory? _dir;

  Future<Directory> _contentDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/content');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  /// Đọc 1 file nội dung: ưu tiên bản đã tải > assets bundle.
  Future<String> _loadRaw(String file) async {
    try {
      final f = File('${(await _contentDir()).path}/$file');
      if (await f.exists()) return await f.readAsString();
    } catch (_) {
      // không truy cập được thư mục -> rơi về bundle
    }
    return rootBundle.loadString('$_base$file');
  }

  Future<List<Course>> loadCourses() async {
    if (_coursesCache != null) return _coursesCache!;
    final raw = await _loadRaw('manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final courses = (json['courses'] as List<dynamic>)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
    return _coursesCache = courses;
  }

  /// Tải toàn bộ thẻ của một khóa (cache theo url).
  Future<List<VocabCard>> loadCards(Course course) async {
    final cached = _cardsCache[course.url];
    if (cached != null) return cached;
    final raw = await _loadRaw(course.url);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cards = (json['cards'] as List<dynamic>)
        .map((e) => VocabCard.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cardsCache[course.url] = cards;
  }

  /// Thẻ của một bài (lesson) cụ thể.
  Future<List<VocabCard>> loadLesson(Course course, int lesson) async {
    final cards = await loadCards(course);
    return cards.where((c) => c.lesson == lesson).toList();
  }

  /// Toàn bộ thẻ của mọi khóa (cho Ôn tập / Thống kê).
  Future<List<VocabCard>> loadAllCards() async {
    final courses = await loadCourses();
    final all = <VocabCard>[];
    for (final c in courses) {
      all.addAll(await loadCards(c));
    }
    return all;
  }

  /// Map id -> thẻ (tra cứu nhanh khi ôn theo SRS).
  Future<Map<String, VocabCard>> loadIndex() async {
    final all = await loadAllCards();
    return {for (final c in all) c.id: c};
  }

  /// Cập nhật nội dung từ server (E7). So `version` từng khóa với manifest hiện
  /// có; chỉ tải khóa thay đổi (giữ nguyên id -> tiến độ học không mất).
  /// Trả về số khóa đã cập nhật. Khi chưa cấu hình URL -> trả 0 (no-op, offline).
  Future<int> checkAndUpdate() async {
    if (remoteBaseUrl.isEmpty) return 0;
    final base = remoteBaseUrl.endsWith('/')
        ? remoteBaseUrl.substring(0, remoteBaseUrl.length - 1)
        : remoteBaseUrl;

    final manRes = await http.get(Uri.parse('$base/manifest.json'));
    if (manRes.statusCode != 200) return 0;
    final remote = jsonDecode(manRes.body) as Map<String, dynamic>;
    final remoteCourses = {
      for (final e in (remote['courses'] as List<dynamic>? ?? []))
        (e as Map<String, dynamic>)['code'] as String: e,
    };

    final local = await loadCourses();
    final dir = await _contentDir();
    var updated = 0;
    for (final lc in local) {
      final rc = remoteCourses[lc.code];
      if (rc == null) continue;
      final rv = (rc['version'] as num?)?.toInt() ?? 1;
      if (rv <= lc.version) continue;
      final url = rc['url'] as String? ?? '';
      if (url.isEmpty) continue;
      final res = await http.get(Uri.parse('$base/$url'));
      if (res.statusCode != 200) continue;
      await File('${dir.path}/$url').writeAsBytes(res.bodyBytes);
      _cardsCache.remove(url);
      updated++;
    }
    if (updated > 0) {
      await File('${dir.path}/manifest.json').writeAsBytes(manRes.bodyBytes);
      _coursesCache = null; // nạp lại manifest mới ở lần sau
    }
    return updated;
  }
}
