import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/vocab_card.dart';
import '../../data/progress_repository.dart';
import '../../logic/answer_service.dart';
import '../../logic/audio_service.dart';
import '../../logic/game/game_bloc.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/sfx_service.dart';
import '../../logic/srs_service.dart';
import 'flame/quiz_game.dart';

/// Người chơi chọn gì ở màn kết quả (trả về qua `Navigator.pop`).
enum GameExit { replay, next }

/// Màn chơi gameplay HƯỚNG A: cảnh Flame (chạy/nhảy ăn nấm) + panel câu hỏi.
/// Tỉ lệ cảnh/panel cố định để cảnh không co giãn giữa các câu.
class GameScreen extends StatefulWidget {
  final String title;
  final bool hasNextLesson; // hiện nút "Bài tiếp" khi qua vòng
  const GameScreen({super.key, required this.title, this.hasNextLesson = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const _sceneFlex = 40;
  static const _panelFlex = 60;

  late final QuizGame _game;
  final SrsService _srs = SrsService();
  final Stopwatch _watch = Stopwatch()..start();
  Timer? _timer;
  Timer? _autoNext;
  late GameState _last;
  bool _deposited = false;
  int _lifeBursts = 0; // đếm số lần được thưởng mạng -> hiệu ứng "+1"

  GameBloc get _bloc => context.read<GameBloc>();
  SfxService get _sfx => context.read<SfxService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final look = context.read<SettingsCubit>().state; // nhân vật + phong cảnh từ cửa hàng
    _game = QuizGame(character: look.character, scene: look.scene);
    _last = context.read<GameBloc>().state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = _bloc.state;
      _game.speedFactor = s.speed.sceneFactor; // nhịp cảnh theo tốc độ
      _game.setBoss(s.bossHp, s.bossMax);
      if (s.status == GameStatus.playing) {
        _game.newQuestion(boss: s.isBoss);
        _maybeSpeakPrompt(s);
        _startQuestionTimer();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // HUD: SafeArea top + padding 12 + nút 44 (+ chút khoảng thở).
    _game.hudBottom = MediaQuery.paddingOf(context).top + 64;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _autoNext?.cancel();
    super.dispose();
  }

  /// App chạy nền / có cuộc gọi -> tạm dừng (người chơi tự bấm "Tiếp tục").
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) _bloc.add(const PauseGame());
  }

  // Mọi câu đều có đồng hồ (quái tiến tới). Tick 100ms cho quái di chuyển mượt.
  void _startQuestionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) _bloc.add(const TimeTick(100));
    });
  }

  void _stopQuestionTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleAutoNext(GameState state) {
    _autoNext?.cancel();
    _autoNext = Timer(Duration(milliseconds: state.speed.autoNextMs), () {
      if (mounted) _bloc.add(const NextQuestion());
    });
  }

  void _maybeSpeakPrompt(GameState state) {
    if (state.status == GameStatus.playing && state.current.isAudioPrompt) {
      context.read<AudioService>().speak(state.current.audioText);
    }
  }

  void _onStateChanged(BuildContext context, GameState state) {
    final prev = _last;
    _last = state;
    _game.setBoss(state.bossHp, state.bossMax);

    if (prev.paused != state.paused) _applyPause(state);
    if (!prev.gainedLife && state.gainedLife) {
      setState(() => _lifeBursts++);
      _sfx.play(Sfx.life);
    }

    if (!prev.answered && state.answered) {
      _onAnswered(state);
    } else if (prev.index != state.index && state.status == GameStatus.playing) {
      // Câu mới: nhân vật + nấm (+ quái mới), bắt đầu đếm giờ.
      _watch
        ..reset()
        ..start();
      _game.newQuestion(boss: state.isBoss);
      _maybeSpeakPrompt(state);
      _startQuestionTimer();
    }

    if (prev.status == GameStatus.playing && state.status != GameStatus.playing) {
      _onFinished(state);
    }
  }

  void _onAnswered(GameState state) {
    _stopQuestionTimer();
    _watch.stop();
    if (state.lastCorrect == true) {
      _game.onCorrect();
      _sfx.play(state.isBoss ? Sfx.hit : Sfx.correct);
    } else {
      _game.onWrong();
      _sfx.play(Sfx.wrong);
      // Đọc lại từ đúng để nhớ âm khi xem thẻ giải thích.
      context.read<AudioService>().speak(state.current.card.target);
    }
    _recordSrs(state);
    // Đúng: tự sang câu. Sai: chờ người chơi đọc thẻ giải thích rồi bấm "Tiếp".
    if (state.status == GameStatus.playing && state.lastCorrect == true) {
      _scheduleAutoNext(state);
    }
  }

  void _applyPause(GameState state) {
    if (state.paused) {
      _stopQuestionTimer();
      _autoNext?.cancel();
      _watch.stop();
      _game.pauseEngine();
      context.read<AudioService>().stop();
    } else {
      _game.resumeEngine();
      if (state.status != GameStatus.playing) return;
      if (!state.answered) {
        _watch.start();
        _startQuestionTimer();
      } else if (state.lastCorrect == true) {
        _scheduleAutoNext(state);
      }
    }
  }

  void _onFinished(GameState state) {
    _stopQuestionTimer();
    _autoNext?.cancel();
    if (state.status == GameStatus.won) {
      _sfx.play(Sfx.win);
    } else {
      Timer(const Duration(milliseconds: 450), () => _sfx.play(Sfx.lose));
    }
    _deposit(state);
  }

  /// Cất nấm còn lại (sau khi đã tiêu cho power-up) vào ví, một lần mỗi vòng.
  void _deposit(GameState state) {
    if (_deposited) return;
    _deposited = true;
    context.read<SettingsCubit>().depositMushrooms(state.mushrooms);
  }

  void _recordSrs(GameState state) {
    final q = state.current;
    if (q.isRetry) return; // chỉ tính lần gặp đầu trong vòng
    final repo = context.read<ProgressRepository>();
    // Mốc theo tốc độ vòng (E3-7); đồng hồ đã dừng lúc trả lời.
    final speed = (1 - _watch.elapsedMilliseconds / state.speed.maxAnswerMs).clamp(0.0, 1.0);
    final updated = _srs.review(
      repo.get(q.card.id),
      correct: state.lastCorrect == true,
      relativeSpeed: speed,
      nowMs: DateTime.now().millisecondsSinceEpoch,
      hinted: state.hiddenOptions.isNotEmpty,
    );
    repo.put(updated);
  }

  Future<void> _confirmExit() async {
    final state = _bloc.state;
    if (state.status != GameStatus.playing) {
      Navigator.of(context).pop();
      return;
    }
    final wasPaused = state.paused;
    _bloc.add(const PauseGame());
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát vòng chơi?'),
        content: Text(
          'Vòng này chưa xong. Nấm đã ăn (${state.mushrooms}) vẫn được cất vào ví, '
          'các từ đã trả lời vẫn được lưu tiến độ.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Chơi tiếp')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      _deposit(_bloc.state);
      Navigator.of(context).pop();
    } else if (!wasPaused) {
      _bloc.add(const ResumeGame());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final playing = state.status == GameStatus.playing;
        // Đồng bộ vị trí quái theo thời gian còn lại (quái = đồng hồ).
        if (playing) {
          _game.setTimeRatio((state.timeLeftMs / state.windowMs).clamp(0.0, 1.0));
        }
        return PopScope(
          canPop: !playing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmExit();
          },
          child: Scaffold(
            backgroundColor: AppColors.card,
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: _sceneFlex,
                      child: Stack(
                        children: [
                          Positioned.fill(child: GameWidget(game: _game)),
                          SafeArea(
                            bottom: false,
                            child: _Hud(
                              state: state,
                              lifeBursts: _lifeBursts,
                              onClose: _confirmExit,
                              onPause: () => _bloc.add(const PauseGame()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: _panelFlex,
                      child: playing
                          ? _QuestionPanel(
                              state: state,
                              onNext: () => _bloc.add(const NextQuestion()),
                            )
                          : const _PanelShell(child: SizedBox.expand()),
                    ),
                  ],
                ),
                if (playing && state.paused)
                  _PauseOverlay(
                    onResume: () => _bloc.add(const ResumeGame()),
                    onExit: _confirmExit,
                  ),
                if (!playing)
                  _ResultPanel(
                    state: state,
                    title: widget.title,
                    hasNextLesson: widget.hasNextLesson,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  final GameState state;
  final int lifeBursts;
  final VoidCallback onClose;
  final VoidCallback onPause;
  const _Hud({
    required this.state,
    required this.lifeBursts,
    required this.onClose,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final playing = state.status == GameStatus.playing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Thoát vòng chơi',
            onPressed: onClose,
            background: AppColors.card,
            color: AppColors.ink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Câu ${state.index + 1} trên ${state.total}',
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.line),
                ),
                child: ProgressTrack(
                  value: (state.index + 1) / state.total,
                  height: 8,
                  trackColor: AppColors.track,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              HudChip(
                icon: Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: state.lives > 0 ? AppColors.cinnabar : AppColors.inkMuted,
                ),
                text: '${state.lives}',
                semanticLabel: '${state.lives} mạng',
              ),
              if (lifeBursts > 0) _LifeBurst(key: ValueKey(lifeBursts)),
            ],
          ),
          const SizedBox(width: 6),
          HudChip(
            icon: const MushroomIcon(size: 18),
            text: '${state.mushrooms}',
            semanticLabel: '${state.mushrooms} nấm',
          ),
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Tạm dừng',
            onPressed: playing && !state.paused ? onPause : null,
            background: AppColors.card,
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }
}

/// "+1 ❤" bay lên rồi mờ dần khi được thưởng mạng (combo).
class _LifeBurst extends StatelessWidget {
  const _LifeBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOut,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, 30 - 46 * t),
          child: Opacity(opacity: t < 0.7 ? 1 : (1 - t) / 0.3, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.jade, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+1',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.card),
              ),
              SizedBox(width: 2),
              Icon(Icons.favorite_rounded, size: 13, color: AppColors.card),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung panel bo góc trên (dùng chung cho panel câu hỏi và nền khi kết thúc).
class _PanelShell extends StatelessWidget {
  final Widget child;
  const _PanelShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  final GameState state;
  final VoidCallback onNext;
  const _QuestionPanel({required this.state, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final audio = context.read<AudioService>();
    // Tạm dừng: giấu đề + đáp án để không dừng đồng hồ lại mà suy nghĩ.
    if (state.paused) return const _PanelShell(child: SizedBox.expand());
    final wrong = state.answered && state.lastCorrect != true;
    return _PanelShell(
      child: LayoutBuilder(builder: (context, box) {
        // Máy màn thấp (vd. 360×640dp): thu gọn để thẻ giải thích + nút Tiếp không
        // bị đẩy khuất dưới mép màn hình.
        final compact = box.maxHeight < 460;
        final gap = compact ? 8.0 : 14.0;
        return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, compact ? 14 : 20, 20, compact ? 10 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    q.isRetry
                        ? 'Ôn lại từ sai · ${state.speed.labelVi}'
                        : 'Câu ${state.index + 1} / ${state.total} · ${state.speed.labelVi}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: q.isRetry ? AppColors.cinnabarDeep : AppColors.inkSoft,
                    ),
                  ),
                ),
                if (state.isBoss)
                  _Tag(
                    'BOSS ${state.bossHp}/${state.bossMax}',
                    AppColors.cinnabarSoft,
                    AppColors.boss,
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.cinnabar,
                  ),
                if (state.combo >= 2) ...[
                  const SizedBox(width: 6),
                  _Tag(
                    // màn hẹp + đang boss: rút gọn (icon lửa đã nói là combo)
                    compact && state.isBoss ? '×${state.combo}' : 'Combo ×${state.combo}',
                    AppColors.goldSoft,
                    AppColors.goldInk,
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.gold,
                  ),
                ],
              ],
            ),
            SizedBox(height: gap),
            _TimerBar(state: state),
            SizedBox(height: gap),
            // Trả lời xong: thẻ giải thích thay chỗ đề bài (thẻ đã có chữ + pinyin),
            // nên chiều cao panel gần như giữ nguyên.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: state.answered
                  ? _AnswerCard(key: const ValueKey('card'), state: state)
                  : _Prompt(
                      key: ValueKey('p${state.index}'),
                      q: q,
                      audio: audio,
                      answered: state.answered,
                      compact: compact,
                    ),
            ),
            SizedBox(height: compact ? 10 : 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: compact ? 8 : 10,
              crossAxisSpacing: compact ? 8 : 10,
              childAspectRatio: compact ? 3.3 : 2.7,
              children: List.generate(q.options.length, (i) {
                return _OptionButton(state: state, index: i);
              }),
            ),
            SizedBox(height: gap),
            // Hàng power-up -> nút "Tiếp" (khi sai) cùng vị trí, cùng chiều cao.
            SizedBox(
              height: 48,
              child: !state.answered
                  ? _PowerUps(state: state)
                  : (wrong && state.status == GameStatus.playing)
                      ? SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onNext,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Tiếp'),
                          ),
                        )
                      : null,
            ),
          ],
        ),
        );
      }),
    );
  }
}

/// Thẻ giải thích sau khi trả lời: chữ · pinyin · Hán Việt · nghĩa + nghe lại.
/// Sai thì dừng ở đây tới khi người chơi bấm "Tiếp" (thời điểm học quan trọng nhất).
class _AnswerCard extends StatelessWidget {
  final GameState state;
  const _AnswerCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = state.current.card;
    final correct = state.lastCorrect == true;
    final timeout = !correct && state.selectedIndex == -1;
    final bg = correct ? AppColors.jadeSoft : AppColors.cinnabarSoft;
    final fg = correct ? AppColors.jade : AppColors.cinnabarDeep;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            correct ? 'Chính xác!' : (timeout ? 'Hết giờ — đáp án là:' : 'Chưa đúng — đáp án là:'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(c.target, style: AppText.hanzi(32, color: AppColors.ink)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.reading}  ·  ${c.hanviet.toUpperCase()}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.meaningVi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.volume_up_rounded,
                tooltip: 'Nghe lại',
                onPressed: () => context.read<AudioService>().speak(c.target),
                background: AppColors.card,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? iconColor;
  const _Tag(this.text, this.bg, this.fg, {this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: iconColor ?? fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Đồng hồ mỗi câu (= quái tiến tới); đóng băng đổi sang màu băng.
class _TimerBar extends StatelessWidget {
  final GameState state;
  const _TimerBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final ratio = state.windowMs == 0 ? 0.0 : (state.timeLeftMs / state.windowMs).clamp(0.0, 1.0);
    final secs = (state.timeLeftMs / 1000).ceil();
    final danger = ratio < 0.34;
    final Color bar;
    final Color ink;
    if (state.frozen) {
      bar = const Color(0xFF6BB6DA);
      ink = AppColors.frostInk;
    } else if (danger) {
      bar = AppColors.cinnabar;
      ink = AppColors.cinnabarDeep;
    } else {
      bar = AppColors.gold;
      ink = AppColors.goldInk;
    }
    return Semantics(
      label: 'Còn $secs giây',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(state.frozen ? Icons.ac_unit_rounded : Icons.schedule_rounded, size: 18, color: ink),
          const SizedBox(width: 10),
          Expanded(
            child: ProgressTrack(value: ratio, height: 8, color: bar),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '${secs}s',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
            ),
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
    final canAct = !state.answered && !state.paused && state.status == GameStatus.playing;
    final bloc = context.read<GameBloc>();
    final sfx = context.read<SfxService>();
    void use(GameEvent e) {
      sfx.play(Sfx.powerup);
      bloc.add(e);
    }

    final buttons = <Widget>[
      _PuButton(
        icon: Icons.lightbulb_outline_rounded,
        label: 'Gợi ý',
        cost: GameBloc.hintCost,
        enabled: canAct && wrongLeft > 0 && state.mushrooms >= GameBloc.hintCost,
        onTap: () => use(const UseHint()),
      ),
      if (state.isBoss)
        _PuButton(
          icon: Icons.ac_unit_rounded,
          label: 'Băng ${GameBloc.freezeMs ~/ 1000}s',
          cost: GameBloc.freezeCost,
          enabled: canAct && !state.frozen && state.mushrooms >= GameBloc.freezeCost,
          onTap: () => use(const UseFreeze()),
        ),
      _PuButton(
        icon: Icons.favorite_border_rounded,
        label: 'Hồi mạng',
        cost: GameBloc.extraLifeCost,
        enabled: canAct && state.mushrooms >= GameBloc.extraLifeCost,
        onTap: () => use(const UseExtraLife()),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

class _PuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int cost;
  final bool enabled;
  final VoidCallback onTap;
  const _PuButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.ink : AppColors.inkMuted;
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: enabled ? AppColors.paper : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(color: enabled ? AppColors.line : AppColors.disabled, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: enabled ? AppColors.goldInk : AppColors.inkMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
            Text(
              ' · $cost',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.inkSoft : AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: 3),
            MushroomIcon(size: 14, muted: !enabled),
          ],
        ),
      ),
    );
  }
}

/// Phần đề bài: dạng nghe -> nút loa lớn; dạng khác -> chữ + nút loa nhỏ.
class _Prompt extends StatelessWidget {
  final Question q;
  final AudioService audio;
  final bool answered;
  final bool compact; // màn thấp: chữ/nút nhỏ hơn
  const _Prompt({
    super.key,
    required this.q,
    required this.audio,
    required this.answered,
    this.compact = false,
  });

  Future<void> _speak(BuildContext context) async {
    final ok = await audio.speak(q.audioText);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa phát được — máy cần cài giọng tiếng Trung '
            '(Cài đặt hệ thống → Text-to-speech → tải Chinese)',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      q.type.labelVi.toUpperCase(),
      style: AppText.overline.copyWith(fontSize: 11, letterSpacing: 1.4),
    );
    if (q.isAudioPrompt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          const SizedBox(height: 10),
          RoundIconButton(
            icon: Icons.volume_up_rounded,
            tooltip: 'Nghe lại',
            onPressed: () => _speak(context),
            background: AppColors.cinnabar,
            color: AppColors.card,
            size: compact ? 60 : 76,
            iconSize: compact ? 30 : 38,
          ),
          if (q.promptMain.isNotEmpty && q.promptMain != '🔊') ...[
            const SizedBox(height: 8),
            Text(q.promptMain, style: AppText.hanzi(compact ? 32 : 40)),
          ],
          if (q.promptSub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(q.promptSub, style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
          ],
        ],
      );
    }
    // Nghĩa → Hán: loa đọc chính đáp án -> chỉ hiện sau khi đã trả lời.
    final showSpeaker = !q.speakRevealsAnswer || answered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                q.promptMain,
                textAlign: TextAlign.center,
                style: _isHanzi(q.promptMain)
                    ? AppText.hanzi(
                        (q.promptMain.characters.length > 3 ? 40 : 54) * (compact ? 0.78 : 1))
                    : AppText.display(compact ? 24 : 28),
              ),
            ),
            if (showSpeaker) ...[
              const SizedBox(width: 10),
              RoundIconButton(
                icon: Icons.volume_up_rounded,
                tooltip: 'Nghe phát âm',
                onPressed: () => _speak(context),
                iconSize: 20,
              ),
            ],
          ],
        ),
        if (q.promptSub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            q.promptSub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }
}

/// Có chứa chữ Hán (CJK Unified Ideographs) không.
bool _isHanzi(String s) => s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

class _OptionButton extends StatelessWidget {
  final GameState state;
  final int index;
  const _OptionButton({required this.state, required this.index});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final answered = state.answered;
    final hidden = state.hiddenOptions.contains(index); // power-up gợi ý
    final isCorrect = answered && index == q.correctIndex;
    final isWrongPick = answered && index == state.selectedIndex && !isCorrect;

    Color bg = Colors.white;
    Color fg = AppColors.ink;
    BorderSide side = const BorderSide(color: AppColors.line, width: 1.5);
    IconData? mark;
    if (isCorrect) {
      bg = AppColors.jade;
      fg = AppColors.card;
      side = BorderSide.none;
      mark = Icons.check_rounded;
    } else if (isWrongPick) {
      bg = AppColors.cinnabarSoft;
      fg = AppColors.cinnabarDeep;
      side = const BorderSide(color: AppColors.cinnabar, width: 1.5);
      mark = Icons.close_rounded;
    } else if (hidden) {
      bg = Colors.transparent;
      fg = const Color(0xFFB7A99A);
      side = const BorderSide(color: AppColors.disabled, width: 1.5);
    }

    final text = q.options[index];
    final style = _isHanzi(text)
        ? AppText.hanzi(24, color: fg)
        : TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg);

    return Opacity(
      opacity: hidden ? 0.6 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (answered || hidden || state.paused)
              ? null
              : () => context.read<GameBloc>().add(AnswerPicked(index)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mark != null) ...[Icon(mark, size: 18, color: fg), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: hidden
                          ? style.copyWith(decoration: TextDecoration.lineThrough)
                          : style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lớp phủ tạm dừng: che đáp án để không "dừng lại suy nghĩ" gian lận đồng hồ.
class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;
  const _PauseOverlay({required this.onResume, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Chặn chạm xuyên xuống HUD/panel bên dưới (chỉ nút trong thẻ nhận chạm).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
        color: const Color(0xE6221C18),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_filled_rounded, size: 56, color: AppColors.cinnabar),
                const SizedBox(height: 10),
                Text('Tạm dừng', style: AppText.display(26)),
                const SizedBox(height: 4),
                const Text(
                  'Đồng hồ đã dừng',
                  style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Tiếp tục'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 4),
                TextButton(onPressed: onExit, child: const Text('Thoát vòng chơi')),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final GameState state;
  final String title;
  final bool hasNextLesson;
  const _ResultPanel({required this.state, required this.title, required this.hasNextLesson});

  @override
  Widget build(BuildContext context) {
    final won = state.status == GameStatus.won;
    final pct = (state.accuracy * 100).round();
    // Máy màn thấp: thu gọn để thấy đủ các nút mà không phải cuộn.
    final compact = MediaQuery.sizeOf(context).height < 720;
    return Positioned.fill(
      // Chặn chạm xuyên xuống HUD/panel bên dưới (chỉ nút trong thẻ nhận chạm).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
        color: const Color(0x80221C18),
        child: SafeArea(
          child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 14 : 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: EdgeInsets.fromLTRB(20, compact ? 18 : 28, 20, compact ? 8 : 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.1,
                    child: SealBadge(won ? '过' : '再',
                        size: compact ? 56 : 76, radius: compact ? 14 : 18, filled: true),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Text(won ? 'Qua vòng!' : 'Hết mạng', style: AppText.display(compact ? 26 : 30)),
                  const SizedBox(height: 4),
                  Text(
                    won ? title : 'Thử lại để chinh phục $title nhé',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                  ),
                  if (won) ...[const SizedBox(height: 10), _Stars(count: state.stars)],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultStat(
                          icon: const Icon(
                            Icons.task_alt_rounded,
                            size: 24,
                            color: AppColors.goldInk,
                          ),
                          value: '$pct%',
                          label: 'đúng ngay lần đầu',
                          bg: AppColors.goldSoft,
                          fg: AppColors.goldInk,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResultStat(
                          icon: const MushroomIcon(size: 24),
                          value: '+${state.mushrooms}',
                          label: 'nấm vào ví',
                          bg: AppColors.cinnabarSoft,
                          fg: AppColors.cinnabarDeep,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResultStat(
                          icon: Icon(
                            Icons.favorite_rounded,
                            size: 24,
                            color: state.lives > 0 ? AppColors.jade : AppColors.cinnabar,
                          ),
                          value: '${state.lives}',
                          label: 'mạng còn lại',
                          bg: state.lives > 0 ? AppColors.jadeSoft : AppColors.cinnabarSoft,
                          fg: state.lives > 0 ? AppColors.jade : AppColors.cinnabarDeep,
                        ),
                      ),
                    ],
                  ),
                  if (state.missed.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TỪ CẦN ÔN (${state.missed.length})',
                        style: AppText.overline.copyWith(fontSize: 11, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: compact ? 132 : 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: state.missed.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _MissedRow(card: state.missed[i]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (won && hasNextLesson) ...[
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(GameExit.next),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Bài tiếp'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(GameExit.replay),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Chơi lại'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(GameExit.replay),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Chơi lại'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Về danh sách bài'),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int count;
  const _Stars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count trên 3 sao',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 8 : 0),
              child: Icon(
                i < count ? Icons.star_rounded : Icons.star_outline_rounded,
                size: i == 1 ? 44 : 36,
                color: i < count ? AppColors.gold : AppColors.disabled,
              ),
            ),
        ],
      ),
    );
  }
}

class _MissedRow extends StatelessWidget {
  final VocabCard card;
  const _MissedRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              card.target,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppText.hanzi(24),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.reading} · ${card.hanviet}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinnabarDeep,
                  ),
                ),
                Text(
                  card.meaningVi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Nghe ${card.target}',
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.cinnabar, size: 20),
            onPressed: () => context.read<AudioService>().speak(card.target),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  const _ResultStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text(value, style: AppText.display(22, color: fg)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, color: fg),
          ),
        ],
      ),
    );
  }
}
