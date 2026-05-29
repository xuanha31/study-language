/// Tiến độ học của một thẻ (lưu local, phục vụ SRS).
class ProgressEntry {
  final String cardId;
  final int level; // bậc trí nhớ SRS (0 = mới)
  final int nextReviewMs; // mốc ôn kế tiếp (epoch ms)
  final int correct;
  final int wrong;

  const ProgressEntry({
    required this.cardId,
    this.level = 0,
    this.nextReviewMs = 0,
    this.correct = 0,
    this.wrong = 0,
  });

  ProgressEntry copyWith({int? level, int? nextReviewMs, int? correct, int? wrong}) =>
      ProgressEntry(
        cardId: cardId,
        level: level ?? this.level,
        nextReviewMs: nextReviewMs ?? this.nextReviewMs,
        correct: correct ?? this.correct,
        wrong: wrong ?? this.wrong,
      );

  Map<String, dynamic> toMap() => {
        'level': level,
        'nextReviewMs': nextReviewMs,
        'correct': correct,
        'wrong': wrong,
      };

  factory ProgressEntry.fromMap(String cardId, Map map) => ProgressEntry(
        cardId: cardId,
        level: (map['level'] as num?)?.toInt() ?? 0,
        nextReviewMs: (map['nextReviewMs'] as num?)?.toInt() ?? 0,
        correct: (map['correct'] as num?)?.toInt() ?? 0,
        wrong: (map['wrong'] as num?)?.toInt() ?? 0,
      );
}
