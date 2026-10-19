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
  final bool isBoss; // thuộc chặng boss cuối vòng
  final bool isRetry; // câu hỏi lại từ đã sai (không tính SRS/độ chính xác lần 2)

  const Question({
    required this.card,
    required this.type,
    required this.promptMain,
    required this.promptSub,
    required this.options,
    required this.correctIndex,
    this.isAudioPrompt = false,
    this.audioText = '',
    this.isBoss = false,
    this.isRetry = false,
  });

  /// Nút loa ở đề bài có làm lộ đáp án không (Nghĩa → Hán: đọc chính đáp án).
  bool get speakRevealsAnswer => type == QuestionType.meaningToHanzi;

  Question copyWith({bool? isBoss, bool? isRetry, List<String>? options, int? correctIndex}) =>
      Question(
        card: card,
        type: type,
        promptMain: promptMain,
        promptSub: promptSub,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
        isAudioPrompt: isAudioPrompt,
        audioText: audioText,
        isBoss: isBoss ?? this.isBoss,
        isRetry: isRetry ?? this.isRetry,
      );

  /// Bản hỏi lại: xáo lại vị trí đáp án để không nhớ theo ô.
  Question asRetry(Random rng, {bool? boss}) {
    final correct = options[correctIndex];
    final shuffled = [...options]..shuffle(rng);
    return copyWith(
      isRetry: true,
      isBoss: boss ?? isBoss,
      options: shuffled,
      correctIndex: shuffled.indexOf(correct),
    );
  }
}

/// Dựng câu hỏi + 3 đáp án nhiễu (ưu tiên cùng distractor_group để "đáng tin").
class AnswerService {
  final Random _rng;
  AnswerService([Random? rng]) : _rng = rng ?? Random();

  /// Bỏ dạng cần nghe (Nghe/Thanh điệu) khi máy không có giọng tiếng Trung —
  /// nếu không người chơi chỉ còn cách đoán mò. Luôn giữ tối thiểu 1 dạng.
  static Set<QuestionType> playableTypes(Set<QuestionType> allowed, {required bool hasVoice}) {
    if (hasVoice) return allowed;
    final set = allowed.where((t) => !t.needsAudio).toSet();
    return set.isEmpty ? {QuestionType.hanziToMeaning} : set;
  }

  /// Dựng câu hỏi cho cả vòng: **xáo thứ tự** để không học thuộc theo vị trí trong bài.
  List<Question> buildRound(List<VocabCard> cards, List<VocabCard> pool,
      {required Set<QuestionType> allowed}) {
    final order = [...cards]..shuffle(_rng);
    return [for (final c in order) build(c, pool, allowed: allowed)];
  }

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

    // Đáp án là chữ Hán / Hán Việt thì độ dài nhìn thấy được -> phải khớp độ dài.
    final distractors = _pickDistractors(card, pool, 3, optionValue,
        matchLength: t != QuestionType.hanziToMeaning);
    final options = <String>[optionValue(card), ...distractors.map(optionValue)];
    options.shuffle(_rng);
    final correctIndex = options.indexOf(optionValue(card));

    final (String main, String sub, bool audio) = switch (t) {
      // Chỉ hiện pinyin: Hán Việt hay trùng nghĩa (北京 → Bắc Kinh) => lộ đáp án.
      QuestionType.hanziToMeaning => (card.target, card.reading, false),
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
    String Function(VocabCard) valueOf, {
    bool matchLength = true,
  }) {
    final correctValue = valueOf(card);
    final len = card.target.runes.length;
    bool usable(VocabCard c) => c.id != card.id && valueOf(c) != correctValue;
    bool sameLen(VocabCard c) => c.target.runes.length == len;
    int byLength(VocabCard a, VocabCard b) =>
        (a.target.runes.length - len).abs().compareTo((b.target.runes.length - len).abs());

    final sameGroup = pool
        .where((c) => usable(c) && c.distractorGroup == card.distractorGroup)
        .toList()
      ..shuffle(_rng);
    final rest = pool
        .where((c) => usable(c) && c.distractorGroup != card.distractorGroup)
        .toList()
      ..shuffle(_rng);
    // Đáp án hiện chữ Hán/Hán Việt: ưu tiên cùng số chữ để không loại trừ được chỉ
    // bằng độ dài (本 vs 一点儿). Thứ tự: cùng nhóm+cùng độ dài > khác nhóm+cùng độ dài
    // > cùng nhóm > còn lại (gần độ dài trước).
    final ordered = matchLength
        ? [
            ...sameGroup.where(sameLen),
            ...rest.where(sameLen),
            ...(sameGroup.where((c) => !sameLen(c)).toList()..sort(byLength)),
            ...(rest.where((c) => !sameLen(c)).toList()..sort(byLength)),
          ]
        : [...sameGroup, ...rest];
    final picked = <VocabCard>[];
    final pickedValues = {correctValue};
    for (final c in ordered) {
      if (picked.length >= n) break;
      if (pickedValues.add(valueOf(c))) picked.add(c);
    }
    return picked;
  }
}
