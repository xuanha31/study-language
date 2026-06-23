import 'package:flutter_test/flutter_test.dart';
import 'package:study_language/core/game_speed.dart';
import 'package:study_language/data/models/vocab_card.dart';
import 'package:study_language/logic/answer_service.dart';
import 'package:study_language/logic/game/game_bloc.dart';

VocabCard _card() => const VocabCard(
      id: 'x',
      type: 'vocab',
      level: 'HSK1',
      lesson: 1,
      verified: false,
      target: '爱',
      reading: 'ài',
      meaningVi: 'yêu',
      meaningEn: '',
      hanviet: 'ái',
      distractorGroup: 'g',
      audio: '',
      chars: [],
    );

Question _q(int correct) => Question(
      card: _card(),
      type: QuestionType.hanziToMeaning,
      promptMain: '爱',
      promptSub: '',
      options: const ['a', 'b', 'c', 'd'],
      correctIndex: correct,
    );

void main() {
  group('GameBloc power-up', () {
    test('Hint ẩn 1 đáp án sai và trừ nấm', () async {
      final bloc = GameBloc(GameState(questions: [_q(0), _q(0)], mushrooms: 5));
      bloc.add(const UseHint());
      final s = await bloc.stream.first;
      expect(s.mushrooms, 5 - GameBloc.hintCost);
      expect(s.hiddenOptions.length, 1);
      expect(s.hiddenOptions.contains(0), isFalse); // không ẩn đáp án đúng
      await bloc.close();
    });

    test('Hết nấm thì không dùng được power-up', () async {
      final bloc = GameBloc(GameState(questions: [_q(0), _q(0)], mushrooms: 1));
      // không có emit nào -> kiểm tra state giữ nguyên
      bloc.add(const UseHint());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.mushrooms, 1);
      expect(bloc.state.hiddenOptions, isEmpty);
      await bloc.close();
    });

    test('Hồi mạng tốn nấm', () async {
      final bloc = GameBloc(GameState(questions: [_q(0), _q(0)], mushrooms: 6, lives: 1));
      bloc.add(const UseExtraLife());
      final s = await bloc.stream.first;
      expect(s.lives, 2);
      expect(s.mushrooms, 6 - GameBloc.extraLifeCost);
      await bloc.close();
    });
  });

  group('GameBloc boss', () {
    test('Đóng băng dừng đồng hồ (chỉ ở câu boss)', () async {
      // 1 câu => index 0 là boss
      final bloc = GameBloc(GameState(
        questions: [_q(0)],
        speed: GameSpeed.medium,
        mushrooms: 3,
        timeLeftMs: 1000,
      ));
      expect(bloc.state.isBoss, isTrue);
      bloc.add(const UseFreeze());
      final s = await bloc.stream.first;
      expect(s.frozen, isTrue);
      expect(s.mushrooms, 3 - GameBloc.freezeCost);
      await bloc.close();
    });

    test('Hết giờ boss tính như trả lời sai (-1 mạng)', () async {
      final bloc = GameBloc(GameState(
        questions: [_q(0)],
        speed: GameSpeed.medium,
        timeLeftMs: 200,
        lives: 2,
      ));
      bloc.add(const TimeTick(200));
      final s = await bloc.stream.first;
      expect(s.timeLeftMs, 0);
      expect(s.answered, isTrue);
      expect(s.lastCorrect, isFalse);
      expect(s.lives, 1);
      await bloc.close();
    });
  });

  group('GameBloc combo', () {
    test('Đủ 5 combo thưởng 1 mạng', () async {
      final bloc = GameBloc(GameState(
        questions: [_q(0), _q(0)],
        combo: 4,
        lives: 3,
      ));
      bloc.add(const AnswerPicked(0));
      final s = await bloc.stream.first;
      expect(s.combo, 5);
      expect(s.lives, 4); // +1 mạng thưởng
      expect(s.gainedLife, isTrue);
      expect(s.mushrooms, 1);
      await bloc.close();
    });
  });
}
