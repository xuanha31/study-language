import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_language/data/models/char_info.dart';
import 'package:study_language/data/models/vocab_card.dart';
import 'package:study_language/logic/answer_service.dart';
import 'package:study_language/logic/pinyin_util.dart';

VocabCard card(String id, String target, String reading, String hanviet,
        {String meaning = 'x', String group = 'g'}) =>
    VocabCard(
      id: id,
      type: 'vocab',
      level: 'HSK1',
      lesson: 1,
      verified: false,
      target: target,
      reading: reading,
      meaningVi: meaning,
      meaningEn: '',
      hanviet: hanviet,
      distractorGroup: group,
      audio: '',
      chars: const <CharInfo>[],
    );

void main() {
  group('PinyinUtil', () {
    test('toneOf nhận đúng thanh', () {
      expect(PinyinUtil.toneOf('mā'), 1);
      expect(PinyinUtil.toneOf('má'), 2);
      expect(PinyinUtil.toneOf('mǎ'), 3);
      expect(PinyinUtil.toneOf('mà'), 4);
      expect(PinyinUtil.toneOf('ma'), 0);
      expect(PinyinUtil.toneOf('ài'), 4);
    });

    test('stripTones bỏ dấu', () {
      expect(PinyinUtil.stripTones('mǎ'), 'ma');
      expect(PinyinUtil.stripTones('ài'), 'ai');
    });

    test('fourTones tạo 4 biến thể, chứa âm gốc', () {
      final v = PinyinUtil.fourTones('ài');
      expect(v, ['āi', 'ái', 'ǎi', 'ài']);
      expect(v.contains('ài'), isTrue);
    });

    test('applyTone theo quy tắc a/e/ou', () {
      expect(PinyinUtil.applyTone('hao', 3), 'hǎo'); // có 'a'
      expect(PinyinUtil.applyTone('hou', 4), 'hòu'); // ou -> o
      expect(PinyinUtil.applyTone('lei', 2), 'léi'); // có 'e'
    });
  });

  group('AnswerService dạng mới', () {
    final pool = [
      card('1', '爱', 'ài', 'ái', meaning: 'yêu', group: 'emo'),
      card('2', '八', 'bā', 'bát', meaning: 'tám', group: 'num'),
      card('3', '好', 'hǎo', 'hảo', meaning: 'tốt', group: 'adj'),
      card('4', 'big', 'dà', 'đại', meaning: 'to', group: 'adj'),
      card('5', '小', 'xiǎo', 'tiểu', meaning: 'nhỏ', group: 'adj'),
    ];

    test('tone: 4 đáp án là 4 thanh, đúng là âm thật', () {
      final s = AnswerService(Random(1));
      final q = s.build(pool[0], pool, type: QuestionType.tone);
      expect(q.options.length, 4);
      expect(q.options, ['āi', 'ái', 'ǎi', 'ài']);
      expect(q.options[q.correctIndex], 'ài');
      expect(q.isAudioPrompt, isTrue);
    });

    test('hanviet: đáp án là âm Hán Việt, đúng là của card', () {
      final s = AnswerService(Random(2));
      final q = s.build(pool[1], pool, type: QuestionType.hanviet);
      expect(q.options.length, 4);
      expect(q.options[q.correctIndex], 'bát');
      expect(q.options.toSet().length, 4);
    });

    test('listening: đáp án là chữ Hán, có audioText', () {
      final s = AnswerService(Random(3));
      final q = s.build(pool[1], pool, type: QuestionType.listening);
      expect(q.options[q.correctIndex], '八');
      expect(q.isAudioPrompt, isTrue);
      expect(q.audioText, '八');
    });

    test('_pickType bỏ tone với từ nhiều âm tiết', () {
      final multi = card('m', '爸爸', 'bàba', 'ba ba', meaning: 'bố', group: 'fam');
      final s = AnswerService(Random(4));
      // chỉ cho phép tone -> phải fallback (vì 2 âm tiết không hợp tone)
      final q = s.build(multi, pool, allowed: {QuestionType.tone});
      expect(q.type, isNot(QuestionType.tone));
    });
  });
}
