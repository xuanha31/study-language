part of 'game_bloc.dart';

enum GameStatus { playing, won, lost }

class GameState extends Equatable {
  final List<Question> questions; // hàng đợi câu: có thể dài thêm khi hỏi lại từ sai
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
  final int timeLeftMs; // đồng hồ câu hiện tại còn lại
  final int frozenMs; // đóng băng còn lại (power-up, chỉ ở chặng boss)
  final bool paused; // người chơi tạm dừng / app chạy nền
  final int bossHp; // số đòn còn lại để hạ boss
  final int bossMax;
  final int firstTried; // số từ đã trả lời lần đầu (không tính câu hỏi lại)
  final int firstCorrect; // số từ đúng ngay lần đầu
  final List<VocabCard> missed; // từ sai lần đầu (hiện ở màn kết quả)

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
    this.frozenMs = 0,
    this.paused = false,
    this.bossHp = 0,
    this.bossMax = 0,
    this.firstTried = 0,
    this.firstCorrect = 0,
    this.missed = const [],
  });

  /// Số câu boss cuối vòng: vòng đủ dài thì boss có 3 HP, vòng ngắn 1 HP.
  static int bossCountFor(int total) => total >= 10 ? 3 : 1;

  /// Trạng thái đầu vòng: gắn cờ boss cho các câu cuối, đặt đồng hồ đúng câu đầu.
  factory GameState.start({
    required List<Question> questions,
    GameSpeed speed = GameSpeed.medium,
    int lives = 3,
    int mushrooms = 0,
  }) {
    final n = questions.length;
    final boss = n == 0 ? 0 : bossCountFor(n);
    final tagged = [for (var i = 0; i < n; i++) questions[i].copyWith(isBoss: i >= n - boss)];
    final first = tagged.isNotEmpty && tagged.first.isBoss;
    return GameState(
      questions: tagged,
      speed: speed,
      lives: lives,
      mushrooms: mushrooms,
      bossHp: boss,
      bossMax: boss,
      timeLeftMs: (first ? speed.bossSeconds : speed.answerSeconds) * 1000,
    );
  }

  Question get current => questions[index];
  int get total => questions.length;

  bool get isBoss => current.isBoss;
  bool get frozen => frozenMs > 0;

  /// Cửa sổ thời gian của câu hiện tại (ms) = nhịp quái tiến tới nhân vật.
  /// Mọi câu đều có đồng hồ; tốc độ nhanh -> cửa sổ ngắn.
  int get windowMs => (isBoss ? speed.bossSeconds : speed.answerSeconds) * 1000;

  /// Tỉ lệ đúng ngay lần đầu (0..1).
  double get accuracy => firstTried == 0 ? 0 : firstCorrect / firstTried;

  /// Sao khi qua vòng: theo độ chính xác lần đầu. Thua = 0 sao.
  int get stars {
    if (status != GameStatus.won) return 0;
    if (accuracy >= 0.9) return 3;
    if (accuracy >= 0.7) return 2;
    return 1;
  }

  GameState copyWith({
    List<Question>? questions,
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
    int? frozenMs,
    bool? paused,
    int? bossHp,
    int? firstTried,
    int? firstCorrect,
    List<VocabCard>? missed,
    bool clearSelection = false,
  }) => GameState(
    questions: questions ?? this.questions,
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
    frozenMs: frozenMs ?? this.frozenMs,
    paused: paused ?? this.paused,
    bossHp: bossHp ?? this.bossHp,
    bossMax: bossMax,
    firstTried: firstTried ?? this.firstTried,
    firstCorrect: firstCorrect ?? this.firstCorrect,
    missed: missed ?? this.missed,
  );

  @override
  List<Object?> get props => [
    questions,
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
    frozenMs,
    paused,
    bossHp,
    firstTried,
    firstCorrect,
    missed,
  ];
}
