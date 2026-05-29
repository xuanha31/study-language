import '../data/models/progress_entry.dart';

/// SRS kiểu Leitner/SM-2 rút gọn (xem design.md §6).
/// - Đúng + nhanh  -> lên bậc, giãn khoảng ôn.
/// - Đúng + chậm   -> lên 0/1 bậc.
/// - Sai           -> rớt về bậc 1, ôn lại sớm.
///
/// "Nhanh/chậm" đo TƯƠNG ĐỐI so với thời lượng tối đa của câu (do người gọi tính),
/// KHÔNG theo giây tuyệt đối — vì chế độ tốc độ nhanh ép mọi người chọn nhanh.
class SrsService {
  /// Khoảng ôn (ngày) theo bậc trí nhớ.
  static const intervalsDays = [0, 1, 3, 7, 16, 35, 75, 150];

  static const _dayMs = 24 * 60 * 60 * 1000;

  /// Tính tiến độ mới sau một lần trả lời.
  /// [relativeSpeed]: 0..1 (1 = trả lời rất nhanh so với thời lượng cho phép).
  ProgressEntry review(
    ProgressEntry prev, {
    required bool correct,
    required double relativeSpeed,
    required int nowMs,
  }) {
    int level;
    if (!correct) {
      level = 1; // rớt bậc, ôn sớm
    } else {
      final step = relativeSpeed >= 0.5 ? 2 : 1; // nhanh -> nhảy 2 bậc
      level = (prev.level + step).clamp(1, intervalsDays.length - 1);
    }
    final days = intervalsDays[level];
    return prev.copyWith(
      level: level,
      nextReviewMs: nowMs + days * _dayMs,
      correct: prev.correct + (correct ? 1 : 0),
      wrong: prev.wrong + (correct ? 0 : 1),
    );
  }
}
