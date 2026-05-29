import 'package:hive/hive.dart';

import 'models/progress_entry.dart';

/// Lưu tiến độ học từng thẻ bằng Hive (key = cardId, value = Map).
/// Truy vấn SRS (thẻ đến hạn ôn) chạy trong bộ nhớ — đủ nhanh cho ~5000 thẻ.
class ProgressRepository {
  static const boxName = 'progress';
  final Box _box;

  ProgressRepository(this._box);

  static Future<ProgressRepository> open() async {
    final box = await Hive.openBox(boxName);
    return ProgressRepository(box);
  }

  ProgressEntry get(String cardId) {
    final raw = _box.get(cardId);
    if (raw is Map) return ProgressEntry.fromMap(cardId, raw);
    return ProgressEntry(cardId: cardId);
  }

  Future<void> put(ProgressEntry entry) =>
      _box.put(entry.cardId, entry.toMap());

  /// Danh sách cardId đến hạn ôn (nextReviewMs <= now).
  List<String> dueCardIds(int nowMs) {
    final result = <String>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final e = ProgressEntry.fromMap(key as String, raw);
        if (e.nextReviewMs <= nowMs) result.add(e.cardId);
      }
    }
    return result;
  }
}
