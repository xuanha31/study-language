import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _StreakCard(
                  current: cubit.displayStreak,
                  longest: cubit.state.longestStreak,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _StatTile(
                      icon: Icons.menu_book_rounded,
                      color: AppColors.cinnabar,
                      value: fmtNum(_studied),
                      label: 'từ đã học',
                    ),
                    _StatTile(
                      icon: Icons.check_rounded,
                      color: AppColors.jade,
                      value: fmtNum(_mastered),
                      label: 'từ đã thuộc',
                    ),
                    _StatTile(
                      icon: Icons.schedule_rounded,
                      color: AppColors.goldInk,
                      value: fmtNum(_due),
                      label: 'từ đến hạn ôn',
                    ),
                    _StatTile(
                      icon: Icons.track_changes_rounded,
                      color: AppColors.ink,
                      value: attempts == 0 ? '—' : '$acc%',
                      label: attempts == 0 ? 'chưa có lượt' : 'chính xác · ${fmtNum(attempts)} lượt',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiến độ theo khóa',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        ..._perCourse.map((e) => _CourseProgress(course: e.$1, studied: e.$2)),
                      ],
                    ),
                  ),
                ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department_rounded, size: 34, color: AppColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$current ngày liên tiếp',
                    style: AppText.display(26, color: const Color(0xFF5E400C))),
                const SizedBox(height: 2),
                Text('Kỷ lục: $longest ngày',
                    style: const TextStyle(fontSize: 13, color: AppColors.goldInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const Spacer(),
            Text(value, style: AppText.display(26)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _CourseProgress extends StatelessWidget {
  final Course course;
  final int studied;
  const _CourseProgress({required this.course, required this.studied});

  @override
  Widget build(BuildContext context) {
    final total = course.vocabCount;
    final ratio = total == 0 ? 0.0 : studied / total;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(course.code.replaceAll('HSK', 'HSK '),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text('${fmtNum(studied)} / ${fmtNum(total)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 6),
          ProgressTrack(value: ratio, height: 8),
        ],
      ),
    );
  }
}
