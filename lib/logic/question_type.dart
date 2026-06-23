/// Các dạng câu hỏi (đảo chiều để học sâu — xem design.md §4).
enum QuestionType {
  hanziToMeaning, // hiện chữ Hán -> chọn nghĩa Việt
  meaningToHanzi, // hiện nghĩa Việt -> chọn chữ Hán
  listening, // 🔊 nghe -> chọn chữ Hán đúng
  tone, // 🔊 nghe/đọc -> chọn đúng thanh điệu (mā/má/mǎ/mà)
  hanviet, // hiện chữ Hán -> chọn âm Hán Việt
}

extension QuestionTypeX on QuestionType {
  String get labelVi => switch (this) {
        QuestionType.hanziToMeaning => 'Hán → nghĩa',
        QuestionType.meaningToHanzi => 'Nghĩa → Hán',
        QuestionType.listening => 'Nghe → Hán',
        QuestionType.tone => 'Thanh điệu',
        QuestionType.hanviet => 'Hán → Hán Việt',
      };

  /// Dạng cần phát audio (TTS) cho phần đề bài.
  bool get needsAudio =>
      this == QuestionType.listening || this == QuestionType.tone;
}
