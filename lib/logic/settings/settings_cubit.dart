import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../data/settings_repository.dart';
import '../question_type.dart';

/// Quản lý cài đặt + streak, phát [AppSettings] cho UI và lưu xuống Hive.
class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository repo;
  SettingsCubit(this.repo) : super(repo.load());

  Future<void> _update(AppSettings next) async {
    emit(next);
    await repo.save(next);
  }

  Future<void> setSpeed(GameSpeed speed) => _update(state.copyWith(speed: speed));

  /// Bật/tắt một dạng câu hỏi; luôn giữ tối thiểu 1 dạng.
  Future<void> toggleType(QuestionType type, bool enabled) {
    final set = {...state.enabledTypes};
    if (enabled) {
      set.add(type);
    } else {
      set.remove(type);
      if (set.isEmpty) set.add(QuestionType.hanziToMeaning);
    }
    return _update(state.copyWith(enabledTypes: set));
  }

  Future<void> setAudioEnabled(bool v) => _update(state.copyWith(audioEnabled: v));

  Future<void> setReminder({required bool enabled, int? hour, int? minute}) =>
      _update(state.copyWith(
        reminderEnabled: enabled,
        reminderHour: hour ?? state.reminderHour,
        reminderMinute: minute ?? state.reminderMinute,
      ));

  /// Khôi phục toàn bộ cài đặt (dùng khi restore backup).
  Future<void> replace(AppSettings s) => _update(s);

  /// Ghi nhận đã học hôm nay -> cập nhật streak (E9-4).
  Future<void> recordStudyToday() {
    final today = _todayEpochDay();
    if (state.lastStudyEpochDay == today) return Future.value();
    final continued = state.lastStudyEpochDay == today - 1;
    final streak = continued ? state.currentStreak + 1 : 1;
    return _update(state.copyWith(
      lastStudyEpochDay: today,
      currentStreak: streak,
      longestStreak: max(streak, state.longestStreak),
    ));
  }

  /// Streak còn hiệu lực nếu lần học gần nhất là hôm nay hoặc hôm qua.
  int get displayStreak {
    final today = _todayEpochDay();
    if (state.lastStudyEpochDay >= today - 1) return state.currentStreak;
    return 0;
  }

  static int _todayEpochDay() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).millisecondsSinceEpoch ~/ 86400000;
  }
}
