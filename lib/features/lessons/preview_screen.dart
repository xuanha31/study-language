import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
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
  int _newCount = 0;
  GameSpeed _speed = GameSpeed.medium;

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
    var fresh = 0;
    for (final c in cards) {
      final e = progress.get(c.id);
      if (e.level == 0 && e.correct == 0 && e.wrong == 0) fresh++;
    }
    if (!mounted) return;
    setState(() {
      _pool = pool;
      _cards = cards;
      _newCount = fresh;
      _speed = _suggest(fresh, cards.length);
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
    await settings.recordStudyToday();
    final answer = AnswerService();
    final questions = _cards
        .map((c) => answer.build(c, _pool, allowed: settings.state.enabledTypes))
        .toList();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GameBloc(GameState(questions: questions, speed: _speed)),
        child: GameScreen(title: '${widget.course.code} · Bài ${widget.lesson}'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.course.code} · Bài ${widget.lesson}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _Header(newCount: _newCount, total: _cards.length, suggested: _speed),
                _SpeedPicker(value: _speed, onChanged: (s) => setState(() => _speed = s)),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _cards.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = _cards[i];
                      return ListTile(
                        leading: Text(c.target,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        title: Text('${c.reading}  ·  ${c.hanviet}'),
                        subtitle: Text(c.meaningVi),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => audio.speak(c.target),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _cards.isEmpty ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Bắt đầu'),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final int newCount;
  final int total;
  final GameSpeed suggested;
  const _Header({required this.newCount, required this.total, required this.suggested});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$total từ · $newCount từ mới · ${total - newCount} đã gặp',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Gợi ý tốc độ: ${suggested.labelVi}',
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  final GameSpeed value;
  final ValueChanged<GameSpeed> onChanged;
  const _SpeedPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<GameSpeed>(
        segments: const [
          ButtonSegment(value: GameSpeed.slow, label: Text('Chậm')),
          ButtonSegment(value: GameSpeed.medium, label: Text('Vừa')),
          ButtonSegment(value: GameSpeed.fast, label: Text('Nhanh')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
