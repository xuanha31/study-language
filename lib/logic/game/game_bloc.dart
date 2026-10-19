import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../data/models/vocab_card.dart';
import '../answer_service.dart';

part 'game_event.dart';
part 'game_state.dart';

/// Quản lý 1 vòng chơi (mặc định 20 câu). Xem design.md §2.
/// - Đúng: +1 nấm, +combo; mỗi [comboForBonusLife] combo -> thưởng 1 mạng.
/// - Sai:  -1 mạng, reset combo; hết mạng -> thua. Từ sai được **hỏi lại** trước
///   chặng boss (sai ở boss thì boss thêm 1 câu) để học tới khi đúng.
/// - Chặng boss = các câu cuối ([GameState.bossCountFor]): mỗi câu đúng trừ 1 HP boss.
/// - Power-up (tốn nấm): gợi ý / đóng băng 5 giây (chỉ boss) / hồi mạng.
class GameBloc extends Bloc<GameEvent, GameState> {
  static const comboForBonusLife = 5;
  static const hintCost = 3;
  static const freezeCost = 2;
  static const freezeMs = 5000;
  static const extraLifeCost = 5;

  final Random _rng;

  GameBloc(super.initial, {Random? rng}) : _rng = rng ?? Random() {
    on<AnswerPicked>(_onAnswer);
    on<NextQuestion>(_onNext);
    on<TimeTick>(_onTick);
    on<UseHint>(_onHint);
    on<UseFreeze>(_onFreeze);
    on<UseExtraLife>(_onExtraLife);
    on<PauseGame>((e, emit) {
      if (state.status == GameStatus.playing && !state.paused) emit(state.copyWith(paused: true));
    });
    on<ResumeGame>((e, emit) {
      if (state.paused) emit(state.copyWith(paused: false));
    });
  }

  bool get _canAct => !state.answered && !state.paused && state.status == GameStatus.playing;

  void _onAnswer(AnswerPicked e, Emitter<GameState> emit) {
    if (!_canAct) return;
    final q = state.current;
    if (e.index != q.correctIndex) {
      emit(_miss(selectedIndex: e.index));
      return;
    }
    final combo = state.combo + 1;
    final bonus = combo % comboForBonusLife == 0;
    emit(
      state.copyWith(
        answered: true,
        selectedIndex: e.index,
        lastCorrect: true,
        mushrooms: state.mushrooms + 1,
        combo: combo,
        lives: state.lives + (bonus ? 1 : 0),
        gainedLife: bonus,
        bossHp: q.isBoss ? max(0, state.bossHp - 1) : state.bossHp,
        firstTried: state.firstTried + (q.isRetry ? 0 : 1),
        firstCorrect: state.firstCorrect + (q.isRetry ? 0 : 1),
      ),
    );
  }

  /// Sai hoặc hết giờ: -1 mạng, ghi từ sai, xếp câu hỏi lại vào hàng đợi.
  GameState _miss({required int selectedIndex}) {
    final q = state.current;
    final lives = state.lives - 1;
    final firstTime = !q.isRetry;
    return state.copyWith(
      answered: true,
      selectedIndex: selectedIndex,
      lastCorrect: false,
      combo: 0,
      lives: lives,
      gainedLife: false,
      status: lives <= 0 ? GameStatus.lost : GameStatus.playing,
      questions: lives > 0 ? _withRetry() : null,
      firstTried: state.firstTried + (firstTime ? 1 : 0),
      missed: firstTime && !state.missed.any((c) => c.id == q.card.id)
          ? [...state.missed, q.card]
          : null,
    );
  }

  /// Từ thường sai -> hỏi lại ngay trước chặng boss; câu boss sai -> boss thêm 1 câu.
  List<Question> _withRetry() {
    final q = state.current;
    final list = [...state.questions];
    if (q.isBoss) {
      list.add(q.asRetry(_rng, boss: true));
    } else {
      final bossAt = list.indexWhere((x) => x.isBoss, state.index + 1);
      list.insert(bossAt < 0 ? list.length : bossAt, q.asRetry(_rng, boss: false));
    }
    return list;
  }

  void _onNext(NextQuestion e, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final nextIndex = state.index + 1;
    if (nextIndex >= state.total) {
      emit(
        state.copyWith(
          status: GameStatus.won,
          answered: false,
          clearSelection: true,
          gainedLife: false,
        ),
      );
    } else {
      final boss = state.questions[nextIndex].isBoss;
      final win = (boss ? state.speed.bossSeconds : state.speed.answerSeconds) * 1000;
      emit(
        state.copyWith(
          index: nextIndex,
          answered: false,
          clearSelection: true,
          gainedLife: false,
          frozenMs: 0,
          timeLeftMs: win,
        ),
      );
    }
  }

  /// Đồng hồ mỗi câu (quái tiến tới) chạy; hết giờ -> quái ăn = trả lời sai.
  void _onTick(TimeTick e, Emitter<GameState> emit) {
    if (!_canAct) return;
    if (state.frozen) {
      emit(state.copyWith(frozenMs: max(0, state.frozenMs - e.dtMs)));
      return;
    }
    final left = state.timeLeftMs - e.dtMs;
    if (left > 0) {
      emit(state.copyWith(timeLeftMs: left));
      return;
    }
    emit(_miss(selectedIndex: -1).copyWith(timeLeftMs: 0)); // hết giờ: không chọn gì
  }

  void _onHint(UseHint e, Emitter<GameState> emit) {
    if (!_canAct || state.mushrooms < hintCost) return;
    final q = state.current;
    final wrong = [
      for (var i = 0; i < q.options.length; i++)
        if (i != q.correctIndex && !state.hiddenOptions.contains(i)) i,
    ];
    if (wrong.isEmpty) return;
    emit(
      state.copyWith(
        mushrooms: state.mushrooms - hintCost,
        hiddenOptions: {...state.hiddenOptions, wrong[_rng.nextInt(wrong.length)]},
      ),
    );
  }

  /// Đóng băng đồng hồ boss [freezeMs] (không còn dừng hẳn cả câu).
  void _onFreeze(UseFreeze e, Emitter<GameState> emit) {
    if (!_canAct || !state.isBoss || state.frozen || state.mushrooms < freezeCost) return;
    emit(state.copyWith(mushrooms: state.mushrooms - freezeCost, frozenMs: freezeMs));
  }

  void _onExtraLife(UseExtraLife e, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing || state.paused || state.mushrooms < extraLifeCost) {
      return;
    }
    emit(state.copyWith(mushrooms: state.mushrooms - extraLifeCost, lives: state.lives + 1));
  }
}
