part of 'game_bloc.dart';

enum GameStatus { playing, won, lost }

class GameState extends Equatable {
  final List<Question> questions;
  final GameSpeed speed;
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
  final int timeLeftMs; // đồng hồ boss còn lại (chỉ dùng ở câu boss)
  final bool frozen; // đồng hồ boss đang bị đóng băng (power-up)

  const GameState({
    required this.questions,
    this.speed = GameSpeed.medium,
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
    this.timeLeftMs = 0,
    this.frozen = false,
  });

  Question get current => questions[index];
  int get total => questions.length;

  /// Câu cuối (câu 20) là câu boss — khó hơn, có đếm giờ (E3-5).
  bool get isBoss => index == total - 1;
  int get bossTotalMs => speed.bossSeconds * 1000;

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
    int? timeLeftMs,
    bool? frozen,
    bool clearSelection = false,
  }) =>
      GameState(
        questions: questions,
        speed: speed,
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
        timeLeftMs: timeLeftMs ?? this.timeLeftMs,
        frozen: frozen ?? this.frozen,
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
        timeLeftMs,
        frozen,
      ];
}
