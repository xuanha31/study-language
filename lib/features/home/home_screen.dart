import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';
import '../../logic/content/content_cubit.dart';
import '../../logic/settings/settings_cubit.dart';
import '../lessons/lesson_list_screen.dart';
import '../review/review_screen.dart';
import '../stats/stats_screen.dart';

/// Màn chính: danh sách khóa HSK 1-6 (E9-1) + lối vào Ôn tập (E4-5).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học tiếng Trung 🀄'),
        actions: [
          BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, _) {
              final streak = context.read<SettingsCubit>().displayStreak;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('🔥 $streak', style: const TextStyle(fontSize: 16)),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          return switch (state) {
            ContentLoading() => const Center(child: CircularProgressIndicator()),
            ContentError(:final message) => Center(child: Text(message)),
            ContentLoaded(:final courses) => Column(
                children: [
                  const _ReviewBanner(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: courses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final c = courses[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(c.code.replaceAll('HSK', ''))),
                            title: Text(c.titleVi),
                            subtitle: Text('${c.vocabCount} từ · ${c.lessonCount} bài'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => LessonListScreen(course: c)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

/// Banner ôn tập: hiện số từ đến hạn (SRS) và mở màn ôn tập.
class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = context.read<ProgressRepository>().dueCardIds(now).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListTile(
          leading: const Icon(Icons.history_edu),
          title: const Text('Ôn tập (SRS)'),
          subtitle: Text(due > 0 ? '⏰ $due từ đến hạn ôn' : 'Chưa có từ đến hạn ôn'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReviewScreen()),
          ),
        ),
      ),
    );
  }
}
