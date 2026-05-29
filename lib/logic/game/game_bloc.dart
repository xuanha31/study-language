import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../answer_service.dart';

part 'game_event.dart';
part 'game_state.dart';

/// Quản lý 1 vòng chơi (mặc định 20 câu). Xem design.md §2.
/// - Đúng: +1 nấm, +combo; mỗi [comboForBonusLife] combo -> thưởng 1 mạng.
/// - Sai:  -1 mạng, reset combo; hết mạng -> thua.
class GameBloc extends Bloc<GameEvent, GameState> {
  static const comboForBonusLife = 5;

  GameBloc(super.initial) {
    on<AnswerPicked>(_onAnswer);
    on<NextQuestion>(_onNext);
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
    if (state.index + 1 >= state.total) {
      emit(state.copyWith(status: GameStatus.won, answered: false, clearSelection: true, gainedLife: false));
    } else {
      emit(state.copyWith(
        index: state.index + 1,
        answered: false,
        clearSelection: true,
        gainedLife: false,
      ));
    }
  }
}
