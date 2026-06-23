import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'sync_service.dart';

/// Sao lưu local (E6): lưu snapshot vào thư mục app, chia sẻ ra ngoài, nhập từ file.
/// Snapshot có nhãn thời gian, giữ tối đa ~10 bản (tự dọn bản cũ).
class LocalBackupService implements SyncService {
  static const _prefix = 'backup-';
  static const _ext = '.json';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/backups');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<Snapshot>> list() async {
    final d = await _dir();
    final entries =
        await d.list().where((e) => e is File && e.path.endsWith(_ext)).toList();
    final snaps = <Snapshot>[];
    for (final f in entries.cast<File>()) {
      final stat = await f.stat();
      snaps.add(Snapshot(
        id: f.uri.pathSegments.last,
        createdAt: stat.modified,
        sizeBytes: stat.size,
      ));
    }
    snaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snaps;
  }

  @override
  Future<Snapshot> create(String json, {int keepLatest = 10}) async {
    final d = await _dir();
    final name = '$_prefix${DateTime.now().millisecondsSinceEpoch}$_ext';
    final f = File('${d.path}/$name');
    await f.writeAsString(json);
    await _prune(keepLatest);
    final stat = await f.stat();
    return Snapshot(id: name, createdAt: stat.modified, sizeBytes: stat.size);
  }

  @override
  Future<String> restore(String id) async {
    final d = await _dir();
    return File('${d.path}/$id').readAsString();
  }

  @override
  Future<void> delete(String id) async {
    final d = await _dir();
    final f = File('${d.path}/$id');
    if (await f.exists()) await f.delete();
  }

  Future<void> _prune(int keep) async {
    final snaps = await list();
    for (final s in snaps.skip(keep)) {
      await delete(s.id);
    }
  }

  /// Chia sẻ nội dung sao lưu ra ngoài (lưu Drive/email/...).
  Future<void> share(String json) async {
    final tmp = await getTemporaryDirectory();
    final f = File('${tmp.path}/study-language-backup$_ext');
    await f.writeAsString(json);
    await Share.shareXFiles([XFile(f.path)], subject: 'Sao lưu Học tiếng Trung');
  }

  /// Chọn file .json từ máy để khôi phục; trả nội dung JSON (null nếu hủy).
  Future<String?> importFromFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = res?.files.single.path;
    if (path == null) return null;
    return File(path).readAsString();
  }
}
