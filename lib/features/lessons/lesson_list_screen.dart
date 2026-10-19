import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content_repository.dart';
import '../../data/models/course.dart';
import '../../data/models/vocab_card.dart';
import '../../data/progress_repository.dart';
import 'preview_screen.dart';

/// Màn chọn bài trong một khóa (E9-1). Bấm bài -> xem trước (E4-6) -> vào vòng.
class LessonListScreen extends StatefulWidget {
  final Course course;
  const LessonListScreen({super.key, required this.course});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  Map<int, List<VocabCard>> _lessons = {};
  Set<String> _studiedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = context.read<ContentRepository>();
    final progress = context.read<ProgressRepository>();
    final cards = await content.loadCards(widget.course);
    final studied = {
      for (final e in progress.all())
        if (e.correct + e.wrong > 0) e.cardId,
    };
    if (!mounted) return;
    setState(() {
      _lessons = groupByLesson(cards);
      _studiedIds = studied;
    });
  }

  Future<void> _openPreview(int lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewScreen(course: widget.course, lesson: lesson),
    ));
    if (mounted) _load();
  }

  int _studiedIn(List<VocabCard> cards) => cards.where((c) => _studiedIds.contains(c.id)).length;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final level = int.tryParse(course.code.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final studiedTotal = _lessons.values.fold(0, (s, l) => s + _studiedIn(l));
    int? resume;
    for (var i = 1; i <= course.lessonCount; i++) {
      final cards = _lessons[i] ?? const [];
      if (cards.isEmpty || _studiedIn(cards) < cards.length) {
        resume = i;
        break;
      }
    }
    final parts = course.titleVi.split(' - ');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parts.first),
            Text(
              '${parts.length > 1 ? '${parts.last} · ' : ''}'
              '${fmtNum(course.vocabCount)} từ · ${course.lessonCount} bài',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SealBadge(hanziNumeral(level), size: 64, radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Tiến độ khóa',
                                      style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                Text('$studiedTotal / ${fmtNum(course.vocabCount)} từ',
                                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ProgressTrack(
                              value: course.vocabCount == 0 ? 0 : studiedTotal / course.vocabCount,
                              height: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              resume == null ? 'Đã học hết khóa' : 'Tiếp tục: Bài $resume',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 128,
              ),
              itemCount: course.lessonCount,
              itemBuilder: (context, i) {
                final lesson = i + 1;
                final cards = _lessons[lesson] ?? const <VocabCard>[];
                return _LessonTile(
                  lesson: lesson,
                  sample: cards.take(3).map((c) => c.target).join(' '),
                  total: cards.isEmpty ? course.lessonSize : cards.length,
                  studied: _studiedIn(cards),
                  current: lesson == resume,
                  onTap: () => _openPreview(lesson),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final int lesson;
  final String sample;
  final int total;
  final int studied;
  final bool current;
  final VoidCallback onTap;
  const _LessonTile({
    required this.lesson,
    required this.sample,
    required this.total,
    required this.studied,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = total > 0 && studied >= total;
    final Color bg;
    final Color fg;
    final Color label;
    final BorderSide border;
    if (done) {
      bg = AppColors.jadeSoft;
      fg = AppColors.ink;
      label = AppColors.jade;
      border = const BorderSide(color: AppColors.jadeLine);
    } else if (current) {
      bg = AppColors.cinnabar;
      fg = AppColors.card;
      label = AppColors.cinnabarSoft;
      border = BorderSide.none;
    } else {
      bg = AppColors.card;
      fg = AppColors.ink;
      label = AppColors.inkSoft;
      border = const BorderSide(color: AppColors.line);
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Bài $lesson',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: label)),
                  ),
                  if (done)
                    Semantics(
                      label: 'Hoàn thành',
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: AppColors.jade, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 16, color: AppColors.card),
                      ),
                    )
                  else if (current && studied > 0)
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Đang học',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cinnabarDeep)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sample,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppText.hanzi(21, color: fg).copyWith(letterSpacing: 1),
              ),
              const Spacer(),
              if (current && !done && studied > 0) ...[
                ProgressTrack(
                  value: studied / total,
                  height: 5,
                  color: AppColors.card,
                  trackColor: const Color(0xFFD9645B),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                studied == 0 ? '$total từ mới' : '$studied / $total từ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: label),
              ),
            ],
          ),
        ),
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
