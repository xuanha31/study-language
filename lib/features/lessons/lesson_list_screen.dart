import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/content_repository.dart';
import '../../data/models/course.dart';
import '../../data/models/vocab_card.dart';
import '../../logic/answer_service.dart';
import '../../logic/game/game_bloc.dart';
import '../game/game_screen.dart';

/// Màn chọn bài trong một khóa (E9-1).
class LessonListScreen extends StatelessWidget {
  final Course course;
  const LessonListScreen({super.key, required this.course});

  Future<void> _startLesson(BuildContext context, int lesson) async {
    final repo = context.read<ContentRepository>();
    final pool = await repo.loadCards(course); // toàn khóa -> distractor
    final lessonCards = pool.where((c) => c.lesson == lesson).toList();
    if (lessonCards.isEmpty || !context.mounted) return;

    final answerService = AnswerService();
    final questions = lessonCards.map((c) => answerService.build(c, pool)).toList();

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GameBloc(GameState(questions: questions)),
        child: GameScreen(title: '${course.code} · Bài $lesson'),
      ),
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
            onTap: () => _startLesson(context, lesson),
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
