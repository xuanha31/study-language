import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/content/content_cubit.dart';
import '../lessons/lesson_list_screen.dart';

/// Màn chính: danh sách khóa HSK 1-6 (E9-1).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Học tiếng Trung 🀄')),
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          return switch (state) {
            ContentLoading() => const Center(child: CircularProgressIndicator()),
            ContentError(:final message) => Center(child: Text(message)),
            ContentLoaded(:final courses) => ListView.separated(
                padding: const EdgeInsets.all(16),
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
          };
        },
      ),
    );
  }
}
