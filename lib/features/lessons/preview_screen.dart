import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content_repository.dart';
import '../../data/models/course.dart';
import '../../data/models/vocab_card.dart';
import '../../data/progress_repository.dart';
import '../../logic/answer_service.dart';
import '../../logic/audio_service.dart';
import '../../logic/game/game_bloc.dart';
import '../../logic/settings/settings_cubit.dart';
import '../game/game_screen.dart';

/// Xem trước từ vựng của bài + gợi ý tốc độ trước khi vào vòng (E4-6).
class PreviewScreen extends StatefulWidget {
  final Course course;
  final int lesson;
  const PreviewScreen({super.key, required this.course, required this.lesson});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _loading = true;
  List<VocabCard> _cards = [];
  List<VocabCard> _pool = [];
  Set<String> _freshIds = {};
  GameSpeed _speed = GameSpeed.medium;
  GameSpeed _suggested = GameSpeed.medium;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = context.read<ContentRepository>();
    final progress = context.read<ProgressRepository>();
    final pool = await content.loadCards(widget.course);
    final cards = pool.where((c) => c.lesson == widget.lesson).toList();
    final fresh = <String>{};
    for (final c in cards) {
      final e = progress.get(c.id);
      if (e.level == 0 && e.correct == 0 && e.wrong == 0) fresh.add(c.id);
    }
    if (!mounted) return;
    final suggested = _suggest(fresh.length, cards.length);
    setState(() {
      _pool = pool;
      _cards = cards;
      _freshIds = fresh;
      _suggested = suggested;
      if (_loading) _speed = suggested; // lần đầu: chọn sẵn tốc độ gợi ý
      _loading = false;
    });
  }

  /// Gợi ý tốc độ theo tỉ lệ từ mới: nhiều từ mới -> chậm; toàn từ quen -> nhanh.
  static GameSpeed _suggest(int fresh, int total) {
    if (total == 0) return GameSpeed.medium;
    final ratio = fresh / total;
    if (ratio > 0.6) return GameSpeed.slow;
    if (ratio < 0.2) return GameSpeed.fast;
    return GameSpeed.medium;
  }

  Future<void> _start() async {
    final settings = context.read<SettingsCubit>();
    final audio = context.read<AudioService>();
    final messenger = ScaffoldMessenger.of(context);
    await settings.recordStudyToday();
    final wanted = settings.state.enabledTypes;
    final allowed = AnswerService.playableTypes(wanted,
        hasVoice: audio.enabled && await audio.prepareVoices());
    if (!mounted) return;
    if (allowed.length < wanted.length) messenger.showSnackBar(noVoiceSnack);
    final questions = AnswerService().buildRound(_cards, _pool, allowed: allowed);
    final hasNext = widget.lesson < widget.course.lessonCount;
    final exit = await Navigator.of(context).push<GameExit>(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GameBloc(GameState.start(questions: questions, speed: _speed)),
        child: GameScreen(
          title: '${widget.course.code} · Bài ${widget.lesson}',
          hasNextLesson: hasNext,
        ),
      ),
    ));
    if (!mounted) return;
    switch (exit) {
      case GameExit.replay:
        await _load();
        if (mounted) _start();
      case GameExit.next:
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => PreviewScreen(course: widget.course, lesson: widget.lesson + 1),
        ));
      case null:
        _load(); // cập nhật số từ mới/đã gặp sau vòng chơi
    }
  }

  Future<void> _speak(VocabCard c) async {
    final ok = await context.read<AudioService>().speak(c.target);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chưa phát được — máy cần cài giọng tiếng Trung '
            '(Cài đặt hệ thống → Text-to-speech → tải Chinese)'),
        duration: Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.course.code.replaceAll('HSK', 'HSK '), style: AppText.overline),
            Text('Bài ${widget.lesson} · Xem trước'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _Summary(total: _cards.length, newCount: _freshIds.length),
                      const SizedBox(height: 16),
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < _cards.length; i++) ...[
                              if (i > 0) const Divider(),
                              _WordRow(
                                card: _cards[i],
                                isNew: _freshIds.contains(_cards[i].id),
                                onSpeak: () => _speak(_cards[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _StartPanel(
                  speed: _speed,
                  suggested: _suggested,
                  onSpeed: (s) => setState(() => _speed = s),
                  onStart: _cards.isEmpty ? null : _start,
                ),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int total;
  final int newCount;
  const _Summary({required this.total, required this.newCount});

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, Color bg, Color fg, {bool border = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: border ? Border.all(color: AppColors.line) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppText.display(24, color: fg)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 12, color: fg)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tile('$total', 'từ trong bài', AppColors.card, AppColors.ink, border: true),
        const SizedBox(width: 8),
        tile('$newCount', 'từ mới', AppColors.cinnabarSoft, AppColors.cinnabarDeep),
        const SizedBox(width: 8),
        tile('${total - newCount}', 'đã gặp', AppColors.jadeSoft, AppColors.jade),
      ],
    );
  }
}

class _WordRow extends StatelessWidget {
  final VocabCard card;
  final bool isNew;
  final VoidCallback onSpeak;
  const _WordRow({required this.card, required this.isNew, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final long = card.target.characters.length > 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(card.target, style: AppText.hanzi(long ? 24 : 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(card.reading,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.cinnabar)),
                    Text(card.hanviet.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, letterSpacing: 0.6, color: AppColors.inkSoft)),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cinnabar,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Text('MỚI',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.card)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(card.meaningVi, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.volume_up_rounded,
            tooltip: 'Nghe ${card.target}',
            onPressed: onSpeak,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  final GameSpeed speed;
  final GameSpeed suggested;
  final ValueChanged<GameSpeed> onSpeed;
  final VoidCallback? onStart;
  const _StartPanel({
    required this.speed,
    required this.suggested,
    required this.onSpeed,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Tốc độ', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    children: [
                      const TextSpan(text: 'Gợi ý cho bạn: '),
                      TextSpan(
                        text: suggested.labelVi,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.cinnabarDeep),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 12),
              SpeedSelector(value: speed, onChanged: onSpeed),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu vòng chơi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
