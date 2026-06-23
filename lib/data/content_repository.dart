import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'models/course.dart';
import 'models/vocab_card.dart';

/// Đọc nội dung học (manifest + các khóa HSK) từ assets bundle.
/// Bản dev: content/ bundle sẵn. Sau này thay bằng tải từ server (xem design.md §7).
class ContentRepository {
  static const _base = 'content/';

  List<Course>? _coursesCache;
  final Map<String, List<VocabCard>> _cardsCache = {};

  Future<List<Course>> loadCourses() async {
    if (_coursesCache != null) return _coursesCache!;
    final raw = await rootBundle.loadString('${_base}manifest.json');
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
    final raw = await rootBundle.loadString('$_base${course.url}');
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

  /// Toàn bộ thẻ của mọi khóa (cho Ôn tập / Thống kê). Cache theo khóa nên rẻ ở lần sau.
  Future<List<VocabCard>> loadAllCards() async {
    final courses = await loadCourses();
    final all = <VocabCard>[];
    for (final c in courses) {
      all.addAll(await loadCards(c));
    }
    return all;
  }

  /// Map id -> thẻ (cho tra cứu nhanh khi ôn theo SRS).
  Future<Map<String, VocabCard>> loadIndex() async {
    final all = await loadAllCards();
    return {for (final c in all) c.id: c};
  }
}
