import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_language/core/game_speed.dart';
import 'package:study_language/data/models/vocab_card.dart';
import 'package:study_language/logic/answer_service.dart';
import 'package:study_language/logic/game/game_bloc.dart';

VocabCard _card([String id = 'x']) => VocabCard(
  id: id,
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
  chars: const [],
);

Question _q(int correct, [String id = 'x']) => Question(
  card: _card(id),
  type: QuestionType.hanziToMeaning,
  promptMain: '爱',
  promptSub: '',
  options: const ['a', 'b', 'c', 'd'],
  correctIndex: correct,
);

List<Question> _qs(int n) => [for (var i = 0; i < n; i++) _q(0, 'c$i')];

GameBloc _bloc(GameState s) => GameBloc(s, rng: Random(1));

void main() {
  group('GameBloc power-up', () {
    test('Hint ẩn 1 đáp án sai và trừ nấm', () async {
      final bloc = _bloc(GameState(questions: [_q(0), _q(0)], mushrooms: 5));
      bloc.add(const UseHint());
      final s = await bloc.stream.first;
      expect(s.mushrooms, 5 - GameBloc.hintCost);
      expect(s.hiddenOptions.length, 1);
      expect(s.hiddenOptions.contains(0), isFalse); // không ẩn đáp án đúng
      await bloc.close();
    });

    test('Hết nấm thì không dùng được power-up', () async {
      final bloc = _bloc(GameState(questions: [_q(0), _q(0)], mushrooms: 1));
      // không có emit nào -> kiểm tra state giữ nguyên
      bloc.add(const UseHint());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.mushrooms, 1);
      expect(bloc.state.hiddenOptions, isEmpty);
      await bloc.close();
    });

    test('Hồi mạng tốn nấm', () async {
      final bloc = _bloc(GameState(questions: [_q(0), _q(0)], mushrooms: 6, lives: 1));
      bloc.add(const UseExtraLife());
      final s = await bloc.stream.first;
      expect(s.lives, 2);
      expect(s.mushrooms, 6 - GameBloc.extraLifeCost);
      await bloc.close();
    });
  });

  group('GameState.start', () {
    test('Vòng 20 câu: 3 câu cuối là boss, boss 3 HP', () {
      final s = GameState.start(questions: _qs(20));
      expect(s.bossMax, 3);
      expect(s.bossHp, 3);
      expect(s.questions.where((q) => q.isBoss).length, 3);
      expect(s.questions.sublist(17).every((q) => q.isBoss), isTrue);
      expect(s.isBoss, isFalse);
    });

    test('Vòng 1 câu: câu đầu là boss và đồng hồ theo giờ boss', () {
      final s = GameState.start(questions: _qs(1), speed: GameSpeed.medium);
      expect(s.isBoss, isTrue);
      expect(s.timeLeftMs, GameSpeed.medium.bossSeconds * 1000);
      expect(s.timeLeftMs, s.windowMs);
    });
  });

  group('GameBloc boss', () {
    test('Đóng băng dừng đồng hồ 5 giây rồi chạy tiếp', () async {
      final bloc = _bloc(GameState.start(questions: _qs(1), mushrooms: 3));
      final start = bloc.state.timeLeftMs;
      bloc.add(const UseFreeze());
      final s = await bloc.stream.first;
      expect(s.frozen, isTrue);
      expect(s.mushrooms, 3 - GameBloc.freezeCost);

      bloc.add(const TimeTick(GameBloc.freezeMs));
      final thawed = await bloc.stream.first;
      expect(thawed.frozen, isFalse);
      expect(thawed.timeLeftMs, start); // thời gian băng không bị trừ

      bloc.add(const TimeTick(100));
      expect((await bloc.stream.first).timeLeftMs, start - 100);
      await bloc.close();
    });

    test('Không đóng băng được ở câu thường', () async {
      final bloc = _bloc(GameState.start(questions: _qs(20), mushrooms: 9));
      bloc.add(const UseFreeze());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.frozen, isFalse);
      expect(bloc.state.mushrooms, 9);
      await bloc.close();
    });

    test('Hết giờ boss tính như trả lời sai (-1 mạng)', () async {
      final bloc = _bloc(GameState.start(questions: _qs(1), lives: 2));
      bloc.add(TimeTick(bloc.state.timeLeftMs));
      final s = await bloc.stream.first;
      expect(s.timeLeftMs, 0);
      expect(s.answered, isTrue);
      expect(s.lastCorrect, isFalse);
      expect(s.lives, 1);
      await bloc.close();
    });

    test('Đúng ở câu boss trừ 1 HP; sai ở boss thêm 1 câu boss', () async {
      final bloc = _bloc(GameState.start(questions: _qs(10), lives: 5).copyWith(index: 7));
      expect(bloc.state.isBoss, isTrue);
      bloc.add(const AnswerPicked(0));
      expect((await bloc.stream.first).bossHp, 2);

      bloc.add(const NextQuestion());
      await bloc.stream.first;
      bloc.add(const AnswerPicked(1)); // sai
      final s = await bloc.stream.first;
      expect(s.bossHp, 2);
      expect(s.total, 11);
      expect(s.questions.last.isBoss, isTrue);
      expect(s.questions.last.isRetry, isTrue);
      await bloc.close();
    });
  });

  group('GameBloc hỏi lại từ sai', () {
    test('Sai câu thường -> chèn câu hỏi lại ngay trước chặng boss', () async {
      final bloc = _bloc(GameState.start(questions: _qs(20)));
      bloc.add(const AnswerPicked(2)); // câu 1 sai
      final s = await bloc.stream.first;
      expect(s.total, 21);
      final retry = s.questions[17];
      expect(retry.isRetry, isTrue);
      expect(retry.isBoss, isFalse);
      expect(retry.card.id, 'c0');
      expect(retry.options[retry.correctIndex], 'a'); // xáo nhưng giữ đúng đáp án
      expect(s.questions.sublist(18).every((q) => q.isBoss), isTrue);
      expect(s.missed.map((c) => c.id), ['c0']);
      expect(s.firstTried, 1);
      expect(s.firstCorrect, 0);
      await bloc.close();
    });

    test('Hết mạng thì không xếp thêm câu hỏi lại, thua', () async {
      final bloc = _bloc(GameState.start(questions: _qs(20), lives: 1));
      bloc.add(const AnswerPicked(1));
      final s = await bloc.stream.first;
      expect(s.status, GameStatus.lost);
      expect(s.total, 20);
      await bloc.close();
    });

    test('Câu hỏi lại đúng không tính vào độ chính xác lần đầu', () async {
      final qs = [_q(0, 'a'), _q(0, 'a').copyWith(isRetry: true)];
      final bloc = _bloc(GameState(questions: qs, index: 1, firstTried: 1));
      bloc.add(const AnswerPicked(0));
      final s = await bloc.stream.first;
      expect(s.firstTried, 1);
      expect(s.firstCorrect, 0);
      await bloc.close();
    });
  });

  group('GameBloc tạm dừng', () {
    test('Tạm dừng: đồng hồ đứng, không trả lời được', () async {
      final bloc = _bloc(GameState.start(questions: _qs(5)));
      final left = bloc.state.timeLeftMs;
      bloc.add(const PauseGame());
      expect((await bloc.stream.first).paused, isTrue);
      bloc.add(const TimeTick(500));
      bloc.add(const AnswerPicked(0));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.timeLeftMs, left);
      expect(bloc.state.answered, isFalse);
      bloc.add(const ResumeGame());
      expect((await bloc.stream.first).paused, isFalse);
      await bloc.close();
    });
  });

  group('GameState sao', () {
    test('Sao theo độ chính xác lần đầu', () {
      GameState won(int correct) => GameState(
        questions: [_q(0)],
        status: GameStatus.won,
        firstTried: 10,
        firstCorrect: correct,
      );
      expect(won(10).stars, 3);
      expect(won(9).stars, 3);
      expect(won(7).stars, 2);
      expect(won(5).stars, 1);
      expect(GameState(questions: [_q(0)], status: GameStatus.lost).stars, 0);
    });
  });

  group('GameBloc combo', () {
    test('Đủ 5 combo thưởng 1 mạng', () async {
      final bloc = _bloc(GameState(questions: [_q(0), _q(0)], combo: 4, lives: 3));
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
