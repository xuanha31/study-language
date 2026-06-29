import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../data/progress_repository.dart';
import '../../logic/answer_service.dart';
import '../../logic/audio_service.dart';
import '../../logic/game/game_bloc.dart';
import '../../logic/srs_service.dart';
import 'flame/quiz_game.dart';

/// Màn chơi gameplay HƯỚNG A: cảnh Flame (chạy/nhảy ăn nấm) + overlay câu hỏi.
class GameScreen extends StatefulWidget {
  final String title;
  const GameScreen({super.key, required this.title});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final QuizGame _game = QuizGame();
  final SrsService _srs = SrsService();
  final Stopwatch _watch = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<GameBloc>().state;
      _game.speedFactor = s.speed.sceneFactor; // nhịp cảnh theo tốc độ
      if (s.status == GameStatus.playing) {
        _game.newQuestion(boss: s.isBoss);
        _maybeSpeakPrompt(s);
        _startQuestionTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Mọi câu đều có đồng hồ (quái tiến tới). Tick 100ms cho quái di chuyển mượt.
  void _startQuestionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) context.read<GameBloc>().add(const TimeTick(100));
    });
  }

  void _stopQuestionTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _maybeSpeakPrompt(GameState state) {
    if (state.status == GameStatus.playing && state.current.isAudioPrompt) {
      context.read<AudioService>().speak(state.current.audioText);
    }
  }

  void _onAnswered(BuildContext context, GameState state) {
    if (state.lastCorrect == true) {
      _game.onCorrect();
    } else {
      _game.onWrong();
    }
    _recordSrs(context, state);

    if (state.status == GameStatus.playing) {
      Timer(Duration(milliseconds: state.speed.autoNextMs), () {
        if (mounted) context.read<GameBloc>().add(const NextQuestion());
      });
    }
  }

  void _recordSrs(BuildContext context, GameState state) {
    final repo = context.read<ProgressRepository>();
    final card = state.current.card;
    // Đọc thời gian TRƯỚC khi câu mới reset đồng hồ; mốc theo tốc độ vòng (E3-7).
    final speed =
        (1 - _watch.elapsedMilliseconds / state.speed.maxAnswerMs).clamp(0.0, 1.0);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = _srs.review(
      repo.get(card.id),
      correct: state.lastCorrect == true,
      relativeSpeed: speed,
      nowMs: now,
    );
    repo.put(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<GameBloc, GameState>(
          listenWhen: (prev, curr) =>
              prev.answered != curr.answered || prev.index != curr.index,
          listener: (context, state) {
            if (state.answered) {
              _stopQuestionTimer();
              _onAnswered(context, state);
            } else if (state.status == GameStatus.playing) {
              // Câu mới: nhân vật + nấm + quái mới, bắt đầu đếm giờ.
              _watch
                ..reset()
                ..start();
              _game.newQuestion(boss: state.isBoss);
              _maybeSpeakPrompt(state);
              _startQuestionTimer();
            }
          },
          builder: (context, state) {
            // Đồng bộ vị trí quái theo thời gian còn lại (quái = đồng hồ).
            if (state.status == GameStatus.playing) {
              _game.setTimeRatio((state.timeLeftMs / state.windowMs).clamp(0.0, 1.0));
            }
            // Tách 2 vùng: trên = cảnh game (luôn nhìn thấy), dưới = câu hỏi.
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: GameWidget(game: _game)),
                      _Hud(state: state, title: widget.title),
                      if (state.status != GameStatus.playing)
                        _ResultPanel(state: state),
                    ],
                  ),
                ),
                if (state.status == GameStatus.playing) _QuestionPanel(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final GameState state;
  final String title;
  const _Hud({required this.state, required this.title});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (state.index + 1) / state.total,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 12),
          Text('❤️ ${state.lives}', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text('🍄 ${state.mushrooms}', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  final GameState state;
  const _QuestionPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final audio = context.read<AudioService>();
    // Giới hạn chiều cao panel để cảnh game phía trên luôn nhìn thấy được.
    final maxH = MediaQuery.of(context).size.height * 0.55;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimerBar(state: state),
              Text('Câu ${state.index + 1}/${state.total} · ${state.speed.labelVi}'
                  '${state.combo >= 2 ? '   🔥 x${state.combo}' : ''}'),
              const SizedBox(height: 8),
              _Prompt(q: q, audio: audio),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: List.generate(q.options.length, (i) {
                  return _OptionButton(state: state, index: i);
                }),
              ),
              const SizedBox(height: 10),
              _PowerUps(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

/// Đồng hồ mỗi câu (= quái tiến tới); câu boss có nhãn riêng (E3-5).
class _TimerBar extends StatelessWidget {
  final GameState state;
  const _TimerBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final ratio = state.windowMs == 0
        ? 0.0
        : (state.timeLeftMs / state.windowMs).clamp(0.0, 1.0);
    final secs = (state.timeLeftMs / 1000).ceil();
    final danger = ratio < 0.34;
    final color = state.frozen
        ? Colors.lightBlue
        : (danger ? Colors.red : Colors.orange);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isBoss)
                const Text('👹 BOSS  ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(state.frozen ? '❄️ $secs' : '👾 $secs',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Hàng nút power-up: gợi ý / đóng băng (chỉ boss) / hồi mạng.
class _PowerUps extends StatelessWidget {
  final GameState state;
  const _PowerUps({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final wrongLeft = (q.options.length - 1) - state.hiddenOptions.length;
    final canAct = !state.answered && state.status == GameStatus.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _PuButton(
          label: '💡 Gợi ý',
          cost: GameBloc.hintCost,
          enabled: canAct && wrongLeft > 0 && state.mushrooms >= GameBloc.hintCost,
          onTap: () => context.read<GameBloc>().add(const UseHint()),
        ),
        if (state.isBoss)
          _PuButton(
            label: '❄️ Đóng băng',
            cost: GameBloc.freezeCost,
            enabled: canAct && !state.frozen && state.mushrooms >= GameBloc.freezeCost,
            onTap: () => context.read<GameBloc>().add(const UseFreeze()),
          ),
        _PuButton(
          label: '❤️ Hồi mạng',
          cost: GameBloc.extraLifeCost,
          enabled: canAct && state.mushrooms >= GameBloc.extraLifeCost,
          onTap: () => context.read<GameBloc>().add(const UseExtraLife()),
        ),
      ],
    );
  }
}

class _PuButton extends StatelessWidget {
  final String label;
  final int cost;
  final bool enabled;
  final VoidCallback onTap;
  const _PuButton({
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      child: Text('$label  $cost🍄', style: const TextStyle(fontSize: 12)),
    );
  }
}

/// Phần đề bài: dạng nghe -> nút loa lớn; dạng khác -> chữ + nút loa nhỏ.
class _Prompt extends StatelessWidget {
  final Question q;
  final AudioService audio;
  const _Prompt({required this.q, required this.audio});

  @override
  Widget build(BuildContext context) {
    if (q.isAudioPrompt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            iconSize: 44,
            onPressed: () => audio.speak(q.audioText),
            icon: const Icon(Icons.volume_up),
          ),
          if (q.promptMain.isNotEmpty && q.promptMain != '🔊')
            Text(q.promptMain,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          if (q.promptSub.isNotEmpty)
            Text(q.promptSub, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(q.promptMain,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: () => audio.speak(q.audioText),
              icon: const Icon(Icons.volume_up, size: 22),
              tooltip: 'Nghe',
            ),
          ],
        ),
        if (q.promptSub.isNotEmpty)
          Text(q.promptSub, style: const TextStyle(fontSize: 18, color: Colors.black54)),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final GameState state;
  final int index;
  const _OptionButton({required this.state, required this.index});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final answered = state.answered;
    final hidden = state.hiddenOptions.contains(index); // power-up gợi ý
    Color? bg;
    if (answered) {
      if (index == q.correctIndex) {
        bg = Colors.green.shade400;
      } else if (index == state.selectedIndex) {
        bg = Colors.red.shade300;
      }
    }
    final isHanzi = q.type == QuestionType.meaningToHanzi ||
        q.type == QuestionType.listening;
    return Opacity(
      opacity: hidden ? 0.25 : 1,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: bg != null ? Colors.white : null,
        ),
        onPressed: (answered || hidden)
            ? null
            : () => context.read<GameBloc>().add(AnswerPicked(index)),
        child: Text(
          q.options[index],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isHanzi ? 24 : 15),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final GameState state;
  const _ResultPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final won = state.status == GameStatus.won;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(won ? '🎉 Qua vòng!' : '💀 Hết mạng',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('🍄 ${state.mushrooms} nấm   ·   ❤️ ${state.lives} mạng còn lại'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Về danh sách bài'),
            ),
          ],
        ),
      ),
    );
  }
}
