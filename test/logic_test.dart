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

  group('AnswerService chống lộ đáp án', () {
    VocabCard c(String id, String target, String hv, String group) => VocabCard(
          id: id,
          type: 'vocab',
          level: 'HSK1',
          lesson: 1,
          verified: false,
          target: target,
          reading: 'r$id',
          meaningVi: 'nghĩa $id',
          meaningEn: '',
          hanviet: hv,
          distractorGroup: group,
          audio: '',
          chars: const <CharInfo>[],
        );
    final pool = [
      c('1', '本', 'bản', 'measure'),
      c('2', '一点儿', 'nhất điểm nhi', 'measure'),
      c('3', '个', 'cá', 'measure'),
      c('4', '块', 'khối', 'measure'),
      c('5', '岁', 'tuế', 'measure'),
      c('6', '北京', 'Bắc Kinh', 'place'),
    ];

    test('Hán -> nghĩa không hiện Hán Việt ở đề', () {
      final q = AnswerService(Random(3)).build(pool[5], pool, type: QuestionType.hanziToMeaning);
      expect(q.promptSub, 'r6');
    });

    test('Hán Việt: đáp án nhiễu cùng số chữ khi có đủ', () {
      for (var seed = 0; seed < 20; seed++) {
        final q = AnswerService(Random(seed)).build(pool[0], pool, type: QuestionType.hanviet);
        expect(q.options.contains('nhất điểm nhi'), isFalse, reason: 'seed $seed');
        expect(q.options.contains('Bắc Kinh'), isFalse, reason: 'seed $seed');
      }
    });

    test('Nghĩa -> Hán: loa ở đề bị ẩn trước khi trả lời', () {
      final q = AnswerService(Random(1)).build(pool[0], pool, type: QuestionType.meaningToHanzi);
      expect(q.speakRevealsAnswer, isTrue);
    });

    test('Không có giọng tiếng Trung -> bỏ dạng nghe', () {
      final all = QuestionType.values.toSet();
      final t = AnswerService.playableTypes(all, hasVoice: false);
      expect(t.any((e) => e.needsAudio), isFalse);
      expect(AnswerService.playableTypes({QuestionType.listening}, hasVoice: false),
          {QuestionType.hanziToMeaning});
      expect(AnswerService.playableTypes(all, hasVoice: true), all);
    });

    test('buildRound xáo thứ tự nhưng đủ từ', () {
      final cards = pool.sublist(0, 5);
      final orders = {
        for (var seed = 0; seed < 10; seed++)
          AnswerService(Random(seed))
              .buildRound(cards, pool, allowed: {QuestionType.hanziToMeaning})
              .map((q) => q.card.id)
              .join(),
      };
      expect(orders.length, greaterThan(1));
      for (final o in orders) {
        expect(o.split('')..sort(), ['1', '2', '3', '4', '5']);
      }
    });
  });

  group('SrsService', () {
    final srs = SrsService();
    test('đúng + nhanh -> lên 2 bậc, giãn ngày', () {
      final r = srs.review(const ProgressEntry(cardId: 'a', level: 1, correct: 1),
          correct: true, relativeSpeed: 0.9, nowMs: 0);
      expect(r.level, 3);
      expect(r.nextReviewMs, greaterThan(0));
      expect(r.correct, 2);
    });

    test('thẻ mới đúng nhanh -> chỉ lên 1 bậc (lần đầu có thể đoán mò)', () {
      final r = srs.review(const ProgressEntry(cardId: 'a'),
          correct: true, relativeSpeed: 0.9, nowMs: 0);
      expect(r.level, 1);
    });

    test('đúng nhờ gợi ý -> giữ bậc', () {
      final r = srs.review(const ProgressEntry(cardId: 'a', level: 4, correct: 3),
          correct: true, relativeSpeed: 0.9, nowMs: 0, hinted: true);
      expect(r.level, 4);
    });

    test('sai -> rớt về bậc 1, ôn sớm', () {
      final r = srs.review(const ProgressEntry(cardId: 'a', level: 5),
          correct: false, relativeSpeed: 0.0, nowMs: 0);
      expect(r.level, 1);
      expect(r.wrong, 1);
    });
  });
}
