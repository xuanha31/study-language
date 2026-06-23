import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/content_repository.dart';
import '../../data/models/course.dart';
import '../../data/progress_repository.dart';
import '../../logic/settings/settings_cubit.dart';

/// Thống kê tiến độ học (E9-3): từ đã học/thuộc, độ chính xác, tiến độ theo khóa.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _masteredLevel = 4; // bậc coi như "đã thuộc"
  bool _loading = true;
  int _studied = 0;
  int _mastered = 0;
  int _due = 0;
  int _correct = 0;
  int _wrong = 0;
  List<(Course, int)> _perCourse = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = context.read<ContentRepository>();
    final progress = context.read<ProgressRepository>();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entries = progress.all();
    final studiedIds = {
      for (final e in entries)
        if (e.correct + e.wrong > 0) e.cardId,
    };

    final courses = await content.loadCourses();
    final perCourse = <(Course, int)>[];
    for (final c in courses) {
      final ids = (await content.loadCards(c)).map((e) => e.id).toSet();
      perCourse.add((c, ids.where(studiedIds.contains).length));
    }

    if (!mounted) return;
    setState(() {
      _studied = studiedIds.length;
      _mastered = entries.where((e) => e.level >= _masteredLevel).length;
      _due = progress.dueCardIds(now).length;
      _correct = entries.fold(0, (s, e) => s + e.correct);
      _wrong = entries.fold(0, (s, e) => s + e.wrong);
      _perCourse = perCourse;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final attempts = _correct + _wrong;
    final acc = attempts == 0 ? 0 : (_correct * 100 / attempts).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StreakCard(
                  current: cubit.displayStreak,
                  longest: cubit.state.longestStreak,
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  studied: _studied,
                  mastered: _mastered,
                  due: _due,
                  accuracy: acc,
                  attempts: attempts,
                ),
                const SizedBox(height: 12),
                Text('Tiến độ theo khóa',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._perCourse.map((e) => _CourseProgress(course: e.$1, studied: e.$2)),
              ],
            ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int current;
  final int longest;
  const _StreakCard({required this.current, required this.longest});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(children: [
              Text('🔥 $current', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('chuỗi hiện tại (ngày)'),
            ]),
            Column(children: [
              Text('🏅 $longest', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('kỷ lục'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int studied;
  final int mastered;
  final int due;
  final int accuracy;
  final int attempts;
  const _SummaryCard({
    required this.studied,
    required this.mastered,
    required this.due,
    required this.accuracy,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('📚 Đã học', '$studied từ'),
            _row('✅ Đã thuộc', '$mastered từ'),
            _row('⏰ Đến hạn ôn', '$due từ'),
            _row('🎯 Độ chính xác', attempts == 0 ? '—' : '$accuracy% ($attempts lượt)'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
        ),
      );
}

class _CourseProgress extends StatelessWidget {
  final Course course;
  final int studied;
  const _CourseProgress({required this.course, required this.studied});

  @override
  Widget build(BuildContext context) {
    final total = course.vocabCount;
    final ratio = total == 0 ? 0.0 : (studied / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(course.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$studied / $total'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: ratio, minHeight: 10),
          ),
        ],
      ),
    );
  }
}
