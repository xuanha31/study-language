import 'package:hive/hive.dart';

import '../core/game_speed.dart';
import '../logic/question_type.dart';

/// Cài đặt + dữ liệu streak của người dùng (immutable).
class AppSettings {
  final GameSpeed speed;
  final Set<QuestionType> enabledTypes; // dạng câu hỏi đang bật
  final bool audioEnabled; // bật phát âm (TTS)
  final bool sfxEnabled; // hiệu ứng âm thanh + rung trong vòng chơi
  final int mushroomBank; // ví nấm tích lũy qua các vòng
  final Set<String> ownedItems; // id vật phẩm đã mua ở cửa hàng ("character:green"...)
  final String character; // nhân vật đang dùng
  final String scene; // phong cảnh đang dùng
  final bool reminderEnabled; // nhắc học hằng ngày
  final int reminderHour;
  final int reminderMinute;
  // Streak (E9-4) — tính theo "ngày kể từ epoch" (UTC-agnostic ở mức ngày local).
  final int lastStudyEpochDay;
  final int currentStreak;
  final int longestStreak;

  const AppSettings({
    this.speed = GameSpeed.medium,
    this.enabledTypes = const {
      QuestionType.hanziToMeaning,
      QuestionType.meaningToHanzi,
      QuestionType.hanviet,
    },
    this.audioEnabled = true,
    this.sfxEnabled = true,
    this.mushroomBank = 0,
    this.ownedItems = const {},
    this.character = 'beige',
    this.scene = 'hills',
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.lastStudyEpochDay = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  AppSettings copyWith({
    GameSpeed? speed,
    Set<QuestionType>? enabledTypes,
    bool? audioEnabled,
    bool? sfxEnabled,
    int? mushroomBank,
    Set<String>? ownedItems,
    String? character,
    String? scene,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? lastStudyEpochDay,
    int? currentStreak,
    int? longestStreak,
  }) =>
      AppSettings(
        speed: speed ?? this.speed,
        enabledTypes: enabledTypes ?? this.enabledTypes,
        audioEnabled: audioEnabled ?? this.audioEnabled,
        sfxEnabled: sfxEnabled ?? this.sfxEnabled,
        mushroomBank: mushroomBank ?? this.mushroomBank,
        ownedItems: ownedItems ?? this.ownedItems,
        character: character ?? this.character,
        scene: scene ?? this.scene,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        lastStudyEpochDay: lastStudyEpochDay ?? this.lastStudyEpochDay,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  Map<String, dynamic> toMap() => {
        'speed': speed.name,
        'enabledTypes': enabledTypes.map((e) => e.name).toList(),
        'audioEnabled': audioEnabled,
        'sfxEnabled': sfxEnabled,
        'mushroomBank': mushroomBank,
        'ownedItems': ownedItems.toList(),
        'character': character,
        'scene': scene,
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'lastStudyEpochDay': lastStudyEpochDay,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  factory AppSettings.fromMap(Map map) {
    GameSpeed parseSpeed(Object? v) =>
        GameSpeed.values.firstWhere((e) => e.name == v, orElse: () => GameSpeed.medium);
    Set<QuestionType> parseTypes(Object? v) {
      if (v is! List) return const AppSettings().enabledTypes;
      final set = <QuestionType>{};
      for (final name in v) {
        final t = QuestionType.values.where((e) => e.name == name);
        if (t.isNotEmpty) set.add(t.first);
      }
      return set.isEmpty ? const AppSettings().enabledTypes : set;
    }

    return AppSettings(
      speed: parseSpeed(map['speed']),
      enabledTypes: parseTypes(map['enabledTypes']),
      audioEnabled: map['audioEnabled'] as bool? ?? true,
      sfxEnabled: map['sfxEnabled'] as bool? ?? true,
      mushroomBank: (map['mushroomBank'] as num?)?.toInt() ?? 0,
      ownedItems: {
        if (map['ownedItems'] is List)
          for (final e in map['ownedItems'] as List)
            if (e is String) e,
      },
      character: map['character'] as String? ?? 'beige',
      scene: map['scene'] as String? ?? 'hills',
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderHour: (map['reminderHour'] as num?)?.toInt() ?? 20,
      reminderMinute: (map['reminderMinute'] as num?)?.toInt() ?? 0,
      lastStudyEpochDay: (map['lastStudyEpochDay'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Lưu cài đặt bằng Hive (box `settings`, một bản ghi dưới key `app`).
class SettingsRepository {
  static const boxName = 'settings';
  static const _key = 'app';
  final Box _box;

  SettingsRepository(this._box);

  static Future<SettingsRepository> open() async {
    final box = await Hive.openBox(boxName);
    return SettingsRepository(box);
  }

  AppSettings load() {
    final raw = _box.get(_key);
    if (raw is Map) return AppSettings.fromMap(raw);
    return const AppSettings();
  }

  Future<void> save(AppSettings s) => _box.put(_key, s.toMap());
}
