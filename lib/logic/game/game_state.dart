part of 'game_bloc.dart';

enum GameStatus { playing, won, lost }

class GameState extends Equatable {
  final List<Question> questions;
  final int index;
  final int lives;
  final int mushrooms;
  final int combo;
  final GameStatus status;
  final bool answered; // câu hiện tại đã trả lời, đang chờ chuyển
  final int? selectedIndex;
  final bool? lastCorrect;
  final bool gainedLife; // vừa được thưởng mạng (để hiệu ứng)
  final Set<int> hiddenOptions; // đáp án bị ẩn bởi power-up "gợi ý"

  const GameState({
    required this.questions,
    this.index = 0,
    this.lives = 3,
    this.mushrooms = 0,
    this.combo = 0,
    this.status = GameStatus.playing,
    this.answered = false,
    this.selectedIndex,
    this.lastCorrect,
    this.gainedLife = false,
    this.hiddenOptions = const {},
  });

  Question get current => questions[index];
  int get total => questions.length;

  GameState copyWith({
    int? index,
    int? lives,
    int? mushrooms,
    int? combo,
    GameStatus? status,
    bool? answered,
    int? selectedIndex,
    bool? lastCorrect,
    bool? gainedLife,
    Set<int>? hiddenOptions,
    bool clearSelection = false,
  }) =>
      GameState(
        questions: questions,
        index: index ?? this.index,
        lives: lives ?? this.lives,
        mushrooms: mushrooms ?? this.mushrooms,
        combo: combo ?? this.combo,
        status: status ?? this.status,
        answered: answered ?? this.answered,
        selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
        lastCorrect: clearSelection ? null : (lastCorrect ?? this.lastCorrect),
        gainedLife: gainedLife ?? this.gainedLife,
        hiddenOptions: clearSelection ? const {} : (hiddenOptions ?? this.hiddenOptions),
      );

  @override
  List<Object?> get props => [
        index,
        lives,
        mushrooms,
        combo,
        status,
        answered,
        selectedIndex,
        lastCorrect,
        gainedLife,
        hiddenOptions,
      ];
}
