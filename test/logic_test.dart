import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_language/data/models/char_info.dart';
import 'package:study_language/data/models/progress_entry.dart';
import 'package:study_language/data/models/vocab_card.dart';
import 'package:study_language/logic/answer_service.dart';
import 'package:study_language/logic/srs_service.dart';

VocabCard card(String id, String target, String meaning, String group) => VocabCard(
      id: id,
      type: 'vocab',
      level: 'HSK1',
      lesson: 1,
      verified: false,
      target: target,
      reading: 'x',
      meaningVi: meaning,
      meaningEn: '',
      hanviet: 'x',
      distractorGroup: group,
      audio: '',
      chars: const <CharInfo>[],
    );

void main() {
  group('AnswerService', () {
    final pool = [
      card('1', '一', 'một', 'number'),
      card('2', '二', 'hai', 'number'),
      card('3', '三', 'ba', 'number'),
      card('4', '四', 'bốn', 'number'),
      card('5', '猫', 'mèo', 'animal'),
    ];

    test('luôn có 4 đáp án, 1 đúng, không trùng', () {
      final s = AnswerService(Random(1));
      final q = s.build(pool[0], pool, type: QuestionType.hanziToMeaning);
      expect(q.options.length, 4);
      expect(q.options[q.correctIndex], 'một');
      expect(q.options.toSet().length, 4); // không trùng
    });

    test('ưu tiên distractor cùng nhóm', () {
      final s = AnswerService(Random(2));
      final q = s.build(pool[0], pool, type: QuestionType.hanziToMeaning);
      // 3 distractor nên là số (cùng group 'number')
      final numbers = {'hai', 'ba', 'bốn'};
      final picked = q.options.where((o) => o != 'một').toSet();
      expect(picked.every(numbers.contains), isTrue);
    });
  });

  group('SrsService', () {
    final srs = SrsService();
    test('đúng + nhanh -> lên bậc, giãn ngày', () {
      final r = srs.review(const ProgressEntry(cardId: 'a'),
          correct: true, relativeSpeed: 0.9, nowMs: 0);
      expect(r.level, 2);
      expect(r.nextReviewMs, greaterThan(0));
      expect(r.correct, 1);
    });

    test('sai -> rớt về bậc 1, ôn sớm', () {
      final r = srs.review(const ProgressEntry(cardId: 'a', level: 5),
          correct: false, relativeSpeed: 0.0, nowMs: 0);
      expect(r.level, 1);
      expect(r.wrong, 1);
    });
  });
}
