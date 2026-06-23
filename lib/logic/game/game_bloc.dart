import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../answer_service.dart';

part 'game_event.dart';
part 'game_state.dart';

/// Quản lý 1 vòng chơi (mặc định 20 câu). Xem design.md §2.
/// - Đúng: +1 nấm, +combo; mỗi [comboForBonusLife] combo -> thưởng 1 mạng.
/// - Sai:  -1 mạng, reset combo; hết mạng -> thua.
/// - Câu 20 = boss: có đồng hồ đếm ngược, hết giờ tính như sai (E3-5).
/// - Power-up (tốn nấm): gợi ý / đóng băng / hồi mạng.
class GameBloc extends Bloc<GameEvent, GameState> {
  static const comboForBonusLife = 5;
  static const hintCost = 3;
  static const freezeCost = 2;
  static const extraLifeCost = 5;

  GameBloc(super.initial) {
    on<AnswerPicked>(_onAnswer);
    on<NextQuestion>(_onNext);
    on<TimeTick>(_onTick);
    on<UseHint>(_onHint);
    on<UseFreeze>(_onFreeze);
    on<UseExtraLife>(_onExtraLife);
  }

  void _onAnswer(AnswerPicked e, Emitter<GameState> emit) {
    if (state.answered || state.status != GameStatus.playing) return;
    final correct = e.index == state.current.correctIndex;

    if (correct) {
      final combo = state.combo + 1;
      final bonus = combo % comboForBonusLife == 0;
      emit(state.copyWith(
        answered: true,
        selectedIndex: e.index,
        lastCorrect: true,
        mushrooms: state.mushrooms + 1,
        combo: combo,
        lives: state.lives + (bonus ? 1 : 0),
        gainedLife: bonus,
      ));
    } else {
      final lives = state.lives - 1;
      emit(state.copyWith(
        answered: true,
        selectedIndex: e.index,
        lastCorrect: false,
        combo: 0,
        lives: lives,
        gainedLife: false,
        status: lives <= 0 ? GameStatus.lost : GameStatus.playing,
      ));
    }
  }

  void _onNext(NextQuestion e, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final nextIndex = state.index + 1;
    if (nextIndex >= state.total) {
      emit(state.copyWith(
          status: GameStatus.won, answered: false, clearSelection: true, gainedLife: false));
    } else {
      final boss = nextIndex == state.total - 1;
      emit(state.copyWith(
        index: nextIndex,
        answered: false,
        clearSelection: true,
        gainedLife: false,
        frozen: false,
        timeLeftMs: boss ? state.bossTotalMs : 0,
      ));
    }
  }

  /// Đồng hồ boss chạy; hết giờ -> tính như trả lời sai.
  void _onTick(TimeTick e, Emitter<GameState> emit) {
    if (!state.isBoss ||
        state.answered ||
        state.frozen ||
        state.status != GameStatus.playing) {
      return;
    }
    final left = state.timeLeftMs - e.dtMs;
    if (left > 0) {
      emit(state.copyWith(timeLeftMs: left));
      return;
    }
    final lives = state.lives - 1;
    emit(state.copyWith(
      timeLeftMs: 0,
      answered: true,
      selectedIndex: -1, // hết giờ: không chọn gì
      lastCorrect: false,
      combo: 0,
      lives: lives,
      gainedLife: false,
      status: lives <= 0 ? GameStatus.lost : GameStatus.playing,
    ));
  }

  void _onHint(UseHint e, Emitter<GameState> emit) {
    if (state.answered ||
        state.status != GameStatus.playing ||
        state.mushrooms < hintCost) {
      return;
    }
    final q = state.current;
    final wrong = [
      for (var i = 0; i < q.options.length; i++)
        if (i != q.correctIndex && !state.hiddenOptions.contains(i)) i,
    ];
    if (wrong.isEmpty) return;
    emit(state.copyWith(
      mushrooms: state.mushrooms - hintCost,
      hiddenOptions: {...state.hiddenOptions, wrong.first},
    ));
  }

  void _onFreeze(UseFreeze e, Emitter<GameState> emit) {
    if (!state.isBoss ||
        state.frozen ||
        state.answered ||
        state.status != GameStatus.playing ||
        state.mushrooms < freezeCost) {
      return;
    }
    emit(state.copyWith(mushrooms: state.mushrooms - freezeCost, frozen: true));
  }

  void _onExtraLife(UseExtraLife e, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing || state.mushrooms < extraLifeCost) {
      return;
    }
    emit(state.copyWith(
      mushrooms: state.mushrooms - extraLifeCost,
      lives: state.lives + 1,
    ));
  }
}
