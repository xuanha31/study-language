import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content_repository.dart';
import '../../data/models/vocab_card.dart';
import '../../data/progress_repository.dart';
import '../../logic/answer_service.dart';
import '../../logic/audio_service.dart';
import '../../logic/game/game_bloc.dart';
import '../../logic/settings/settings_cubit.dart';
import '../game/game_screen.dart';

/// Màn ôn tập theo SRS (E4-5): gom các thẻ đến hạn ôn rồi chơi 1 vòng.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const _maxPerRound = 20;
  bool _loading = true;
  List<VocabCard> _due = [];
  List<VocabCard> _pool = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final content = context.read<ContentRepository>();
    final progress = context.read<ProgressRepository>();
    final index = await content.loadIndex();
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = progress
        .dueCardIds(now)
        .map((id) => index[id])
        .whereType<VocabCard>()
        .toList()
      ..shuffle();
    if (!mounted) return;
    setState(() {
      _pool = index.values.toList();
      _due = due;
      _loading = false;
    });
  }

  Future<void> _start([List<VocabCard>? replay]) async {
    final settings = context.read<SettingsCubit>();
    final audio = context.read<AudioService>();
    final messenger = ScaffoldMessenger.of(context);
    await settings.recordStudyToday();
    // "Chơi lại" ôn đúng bộ thẻ vừa rồi (lúc này chúng đã được dời lịch, không còn đến hạn).
    final cards = replay ?? _due.take(_maxPerRound).toList();
    final wanted = settings.state.enabledTypes;
    final allowed = AnswerService.playableTypes(wanted,
        hasVoice: audio.enabled && await audio.prepareVoices());
    if (!mounted) return;
    if (allowed.length < wanted.length) messenger.showSnackBar(noVoiceSnack);
    final questions = AnswerService().buildRound(cards, _pool, allowed: allowed);

    final exit = await Navigator.of(context).push<GameExit>(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GameBloc(GameState.start(questions: questions, speed: settings.state.speed)),
        child: const GameScreen(title: 'Ôn tập'),
      ),
    ));
    if (!mounted) return;
    await _load(); // làm mới danh sách đến hạn sau khi ôn
    if (exit == GameExit.replay && mounted) _start(cards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _due.isEmpty
              ? const _Empty()
              : _Ready(count: _due.length, perRound: _maxPerRound, onStart: _start),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.1,
              child: const SealBadge('好', size: 84, radius: 18, filled: true),
            ),
            const SizedBox(height: 20),
            Text('Chưa có từ nào đến hạn ôn',
                textAlign: TextAlign.center, style: AppText.display(22)),
            const SizedBox(height: 8),
            const Text('Học thêm bài mới hoặc quay lại sau nhé!',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  final int count;
  final int perRound;
  final VoidCallback onStart;
  const _Ready({required this.count, required this.perRound, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final n = count > perRound ? perRound : count;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cinnabar,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -26,
                child: ExcludeSemantics(
                  child: Text('习', style: AppText.hanzi(150, color: AppColors.cinnabarGlyph)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÔN TẬP SRS',
                        style: AppText.overline.copyWith(color: AppColors.cinnabarSoft)),
                    const SizedBox(height: 4),
                    Text('$count từ đến hạn', style: AppText.display(30, color: AppColors.card)),
                    const SizedBox(height: 4),
                    Text('Vòng này ôn $n từ',
                        style: const TextStyle(fontSize: 14, color: AppColors.cinnabarSoft)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.cinnabarDeep,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Bắt đầu ôn'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.inkSoft),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Từ trả lời đúng và nhanh sẽ được hẹn ôn thưa hơn; trả lời sai sẽ quay lại sớm.',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
