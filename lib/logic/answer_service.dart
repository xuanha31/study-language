import 'dart:math';

import '../data/models/vocab_card.dart';
import 'question_type.dart';

export 'question_type.dart';

/// Một câu hỏi 4 đáp án đã dựng sẵn.
class Question {
  final VocabCard card;
  final QuestionType type;
  final String promptMain; // dòng to (chữ Hán hoặc nghĩa)
  final String promptSub; // dòng phụ (pinyin + Hán Việt) — rỗng nếu hỏi ngược
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.card,
    required this.type,
    required this.promptMain,
    required this.promptSub,
    required this.options,
    required this.correctIndex,
  });
}

/// Dựng câu hỏi + 3 đáp án nhiễu (ưu tiên cùng distractor_group để "đáng tin").
class AnswerService {
  final Random _rng;
  AnswerService([Random? rng]) : _rng = rng ?? Random();

  Question build(VocabCard card, List<VocabCard> pool, {QuestionType? type}) {
    final t = type ?? (_rng.nextBool() ? QuestionType.hanziToMeaning : QuestionType.meaningToHanzi);
    final distractors = _pickDistractors(card, pool, 3);

    String valueOf(VocabCard c) =>
        t == QuestionType.hanziToMeaning ? c.meaningVi : c.target;

    final options = <String>[valueOf(card), ...distractors.map(valueOf)];
    options.shuffle(_rng);
    final correctIndex = options.indexOf(valueOf(card));

    return Question(
      card: card,
      type: t,
      promptMain: t == QuestionType.hanziToMeaning ? card.target : card.meaningVi,
      promptSub: t == QuestionType.hanziToMeaning
          ? '${card.reading}  ·  ${card.hanviet}'
          : '',
      options: options,
      correctIndex: correctIndex,
    );
  }

  List<VocabCard> _pickDistractors(VocabCard card, List<VocabCard> pool, int n) {
    bool sameValue(VocabCard a, VocabCard b) =>
        a.target == b.target || a.meaningVi == b.meaningVi;

    final sameGroup = pool
        .where((c) => c.id != card.id && c.distractorGroup == card.distractorGroup && !sameValue(c, card))
        .toList()
      ..shuffle(_rng);
    final picked = <VocabCard>[...sameGroup.take(n)];

    if (picked.length < n) {
      final rest = pool
          .where((c) => c.id != card.id && !picked.contains(c) && !sameValue(c, card))
          .toList()
        ..shuffle(_rng);
      picked.addAll(rest.take(n - picked.length));
    }
    return picked;
  }
}
