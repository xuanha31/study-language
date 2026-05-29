part of 'game_bloc.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

/// Người chơi chọn 1 đáp án.
class AnswerPicked extends GameEvent {
  final int index;
  const AnswerPicked(this.index);
  @override
  List<Object?> get props => [index];
}

/// Chuyển sang câu tiếp theo (sau khi đã hiện đúng/sai).
class NextQuestion extends GameEvent {
  const NextQuestion();
}
