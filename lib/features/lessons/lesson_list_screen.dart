import 'package:flutter/material.dart';

import '../../data/models/course.dart';
import '../../data/models/vocab_card.dart';
import 'preview_screen.dart';

/// Màn chọn bài trong một khóa (E9-1). Bấm bài -> xem trước (E4-6) -> vào vòng.
class LessonListScreen extends StatelessWidget {
  final Course course;
  const LessonListScreen({super.key, required this.course});

  void _openPreview(BuildContext context, int lesson) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewScreen(course: course, lesson: lesson),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.titleVi)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: course.lessonCount,
        itemBuilder: (context, i) {
          final lesson = i + 1;
          return InkWell(
            onTap: () => _openPreview(context, lesson),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Center(
                child: Text('Bài\n$lesson',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tiện ích cho test/sau này: nhóm thẻ theo bài.
Map<int, List<VocabCard>> groupByLesson(List<VocabCard> cards) {
  final map = <int, List<VocabCard>>{};
  for (final c in cards) {
    map.putIfAbsent(c.lesson, () => []).add(c);
  }
  return map;
}
