import 'dart:convert';

import '../../data/models/progress_entry.dart';
import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';
import '../settings/settings_cubit.dart';

/// Mã hóa/giải mã dữ liệu sao lưu (tiến độ + cài đặt) sang JSON — dùng chung cho
/// sao lưu local (E6) và Google Drive.
class BackupData {
  static const schemaVersion = 1;

  static String encode({
    required ProgressRepository progress,
    required SettingsRepository settings,
    required String createdAtIso,
  }) {
    final map = {
      'schema': schemaVersion,
      'createdAt': createdAtIso,
      'progress': {for (final e in progress.all()) e.cardId: e.toMap()},
      'settings': settings.load().toMap(),
    };
    return jsonEncode(map);
  }

  /// Khôi phục: XÓA tiến độ hiện tại rồi nạp từ bản sao lưu (đè hoàn toàn).
  static Future<void> restore(
    String json, {
    required ProgressRepository progress,
    required SettingsCubit settings,
  }) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final prog = map['progress'];
    if (prog is Map) {
      await progress.clear();
      for (final entry in prog.entries) {
        if (entry.value is Map) {
          await progress.put(ProgressEntry.fromMap(entry.key as String, entry.value as Map));
        }
      }
    }
    if (map['settings'] is Map) {
      await settings.replace(AppSettings.fromMap(map['settings'] as Map));
    }
  }
}
