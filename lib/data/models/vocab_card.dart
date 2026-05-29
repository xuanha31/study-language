import 'char_info.dart';

/// Một "thẻ" học: từ vựng (hoặc về sau là hội thoại).
/// Khớp schema trong content/README.md.
class VocabCard {
  final String id;
  final String type; // "vocab" | "dialogue"
  final String level; // "HSK1".."HSK6"
  final int lesson;
  final bool verified;
  final String target; // chữ Hán
  final String reading; // pinyin có thanh điệu
  final String meaningVi;
  final String meaningEn;
  final String hanviet;
  final String distractorGroup;
  final String audio;
  final List<CharInfo> chars;

  const VocabCard({
    required this.id,
    required this.type,
    required this.level,
    required this.lesson,
    required this.verified,
    required this.target,
    required this.reading,
    required this.meaningVi,
    required this.meaningEn,
    required this.hanviet,
    required this.distractorGroup,
    required this.audio,
    required this.chars,
  });

  factory VocabCard.fromJson(Map<String, dynamic> json) => VocabCard(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'vocab',
        level: json['level'] as String? ?? '',
        lesson: json['lesson'] as int? ?? 1,
        verified: json['verified'] as bool? ?? false,
        target: json['target'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaningVi: json['meaning_vi'] as String? ?? '',
        meaningEn: json['meaning_en'] as String? ?? '',
        hanviet: json['hanviet'] as String? ?? '',
        distractorGroup: json['distractor_group'] as String? ?? 'other',
        audio: json['audio'] as String? ?? '',
        chars: (json['chars'] as List<dynamic>? ?? [])
            .map((e) => CharInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
