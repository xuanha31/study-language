/// Tốc độ chơi (E3-7). Ảnh hưởng: delay tự chuyển câu, mốc đo tốc độ tương đối
/// cho SRS, và thời lượng đếm giờ của boss. Bài mới nên chậm, ôn lại nên nhanh.
enum GameSpeed { slow, medium, fast }

extension GameSpeedX on GameSpeed {
  String get labelVi => switch (this) {
        GameSpeed.slow => 'Chậm',
        GameSpeed.medium => 'Vừa',
        GameSpeed.fast => 'Nhanh',
      };

  /// Thời gian chờ trước khi tự chuyển sang câu kế (ms).
  int get autoNextMs => switch (this) {
        GameSpeed.slow => 1400,
        GameSpeed.medium => 950,
        GameSpeed.fast => 650,
      };

  /// Mốc thời lượng "tối đa" của một câu để đo tốc độ TƯƠNG ĐỐI (ms).
  /// Trả lời nhanh hơn mốc này nhiều -> SRS coi là "nhanh".
  int get maxAnswerMs => switch (this) {
        GameSpeed.slow => 12000,
        GameSpeed.medium => 8000,
        GameSpeed.fast => 5000,
      };

  /// Thời gian trả lời mỗi câu (giây) = nhịp quái tiến tới nhân vật.
  /// Nhanh -> quái tới nhanh -> phải trả lời gấp.
  int get answerSeconds => switch (this) {
        GameSpeed.slow => 14,
        GameSpeed.medium => 9,
        GameSpeed.fast => 6,
      };

  /// Thời lượng đếm ngược cho câu boss (câu 20) — giây (gắt hơn câu thường).
  int get bossSeconds => switch (this) {
        GameSpeed.slow => 12,
        GameSpeed.medium => 8,
        GameSpeed.fast => 5,
      };

  /// Hệ số nhịp cảnh (chạy/cuộn) — để tốc độ cảm nhận được rõ.
  double get sceneFactor => switch (this) {
        GameSpeed.slow => 0.6,
        GameSpeed.medium => 1.0,
        GameSpeed.fast => 1.7,
      };
}
