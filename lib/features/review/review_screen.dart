import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/content_repository.dart';
import '../../data/models/vocab_card.dart';
import '../../data/progress_repository.dart';
import '../../logic/answer_service.dart';
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

  Future<void> _start() async {
    final settings = context.read<SettingsCubit>();
    await settings.recordStudyToday();
    final cards = _due.take(_maxPerRound).toList();
    final answer = AnswerService();
    final questions = cards
        .map((c) => answer.build(c, _pool, allowed: settings.state.enabledTypes))
        .toList();
    if (!mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GameBloc(GameState(questions: questions, speed: settings.state.speed)),
        child: const GameScreen(title: 'Ôn tập'),
      ),
    ));
    if (mounted) _load(); // làm mới danh sách đến hạn sau khi ôn
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập (SRS)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _due.isEmpty
              ? const _Empty()
              : _Ready(count: _due.length, onStart: _start),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Chưa có từ nào đến hạn ôn.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Học thêm bài mới hoặc quay lại sau nhé!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  final int count;
  final VoidCallback onStart;
  const _Ready({required this.count, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final n = count > 20 ? 20 : count;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⏰ $count từ đến hạn ôn',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Vòng này ôn $n từ.', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu ôn'),
          ),
        ],
      ),
    );
  }
}
