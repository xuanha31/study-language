import 'dart:math';

import '../data/models/vocab_card.dart';
import 'pinyin_util.dart';
import 'question_type.dart';

export 'question_type.dart';

/// Một câu hỏi 4 đáp án đã dựng sẵn.
class Question {
  final VocabCard card;
  final QuestionType type;
  final String promptMain; // dòng to (chữ Hán / nghĩa / 🔊)
  final String promptSub; // dòng phụ (pinyin/Hán Việt/hướng dẫn) — có thể rỗng
  final List<String> options;
  final int correctIndex;
  final bool isAudioPrompt; // đề bài cần phát audio (nghe/thanh điệu)
  final String audioText; // văn bản để TTS đọc (chữ Hán)

  const Question({
    required this.card,
    required this.type,
    required this.promptMain,
    required this.promptSub,
    required this.options,
    required this.correctIndex,
    this.isAudioPrompt = false,
    this.audioText = '',
  });
}

/// Dựng câu hỏi + 3 đáp án nhiễu (ưu tiên cùng distractor_group để "đáng tin").
class AnswerService {
  final Random _rng;
  AnswerService([Random? rng]) : _rng = rng ?? Random();

  /// [allowed]: tập dạng câu hỏi được phép (theo cài đặt). Mặc định tất cả.
  Question build(
    VocabCard card,
    List<VocabCard> pool, {
    QuestionType? type,
    Set<QuestionType>? allowed,
  }) {
    final t = type ?? _pickType(card, allowed ?? QuestionType.values.toSet());
    if (t == QuestionType.tone) return _buildTone(card);

    // Các dạng còn lại: đáp án là một thuộc tính của card.
    String optionValue(VocabCard c) => switch (t) {
          QuestionType.hanziToMeaning => c.meaningVi,
          QuestionType.meaningToHanzi => c.target,
          QuestionType.listening => c.target,
          QuestionType.hanviet => c.hanviet,
          QuestionType.tone => c.reading, // không tới đây
        };

    final distractors = _pickDistractors(card, pool, 3, optionValue);
    final options = <String>[optionValue(card), ...distractors.map(optionValue)];
    options.shuffle(_rng);
    final correctIndex = options.indexOf(optionValue(card));

    final (String main, String sub, bool audio) = switch (t) {
      QuestionType.hanziToMeaning =>
        (card.target, '${card.reading}  ·  ${card.hanviet}', false),
      QuestionType.meaningToHanzi => (card.meaningVi, '', false),
      QuestionType.listening => ('🔊', 'Nghe và chọn chữ đúng', true),
      QuestionType.hanviet => (card.target, card.reading, false),
      QuestionType.tone => ('', '', false),
    };

    return Question(
      card: card,
      type: t,
      promptMain: main,
      promptSub: sub,
      options: options,
      correctIndex: correctIndex,
      isAudioPrompt: audio,
      audioText: card.target,
    );
  }

  /// Câu thanh điệu: 4 đáp án là 4 biến thể thanh của âm tiết (mā/má/mǎ/mà).
  Question _buildTone(VocabCard card) {
    final options = PinyinUtil.fourTones(card.reading);
    var correctIndex = options.indexOf(card.reading);
    if (correctIndex < 0) correctIndex = PinyinUtil.toneOf(card.reading) - 1;
    if (correctIndex < 0 || correctIndex >= options.length) correctIndex = 0;
    return Question(
      card: card,
      type: QuestionType.tone,
      promptMain: card.target,
      promptSub: 'Nghe và chọn đúng thanh điệu',
      options: options,
      correctIndex: correctIndex,
      isAudioPrompt: true,
      audioText: card.target,
    );
  }

  /// Chọn ngẫu nhiên một dạng trong [allowed], loại dạng không hợp với card.
  QuestionType _pickType(VocabCard card, Set<QuestionType> allowed) {
    final candidates = <QuestionType>[
      for (final t in allowed)
        if (!(t == QuestionType.tone && !_toneEligible(card))) t,
    ];
    if (candidates.isEmpty) return QuestionType.hanziToMeaning;
    return candidates[_rng.nextInt(candidates.length)];
  }

  /// Câu thanh điệu chỉ áp dụng cho từ 1 âm tiết và pinyin có thanh 1..4.
  static bool _toneEligible(VocabCard card) {
    final tone = PinyinUtil.toneOf(card.reading);
    return card.target.runes.length == 1 && tone >= 1 && tone <= 4;
  }

  List<VocabCard> _pickDistractors(
    VocabCard card,
    List<VocabCard> pool,
    int n,
    String Function(VocabCard) valueOf,
  ) {
    final correctValue = valueOf(card);
    bool usable(VocabCard c) => c.id != card.id && valueOf(c) != correctValue;

    final sameGroup = pool
        .where((c) => usable(c) && c.distractorGroup == card.distractorGroup)
        .toList()
      ..shuffle(_rng);
    final picked = <VocabCard>[...sameGroup.take(n)];
    final pickedValues = {correctValue, ...picked.map(valueOf)};

    if (picked.length < n) {
      final rest = pool
          .where((c) => usable(c) && !pickedValues.contains(valueOf(c)))
          .toList()
        ..shuffle(_rng);
      for (final c in rest) {
        if (picked.length >= n) break;
        if (pickedValues.add(valueOf(c))) picked.add(c);
      }
    }
    return picked;
  }
}
