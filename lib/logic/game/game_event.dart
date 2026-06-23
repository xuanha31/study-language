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

/// Đồng hồ boss đếm ngược [dtMs] mili-giây (do màn hình bơm vào).
class TimeTick extends GameEvent {
  final int dtMs;
  const TimeTick(this.dtMs);
  @override
  List<Object?> get props => [dtMs];
}

/// Power-up: ẩn 1 đáp án sai (tốn nấm).
class UseHint extends GameEvent {
  const UseHint();
}

/// Power-up: đóng băng đồng hồ boss (tốn nấm).
class UseFreeze extends GameEvent {
  const UseFreeze();
}

/// Power-up: hồi 1 mạng (tốn nấm).
class UseExtraLife extends GameEvent {
  const UseExtraLife();
}
