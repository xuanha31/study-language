import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content_repository.dart';
import '../../data/models/course.dart';
import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';
import '../../logic/content/content_cubit.dart';
import '../../logic/settings/settings_cubit.dart';
import '../lessons/lesson_list_screen.dart';
import '../review/review_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../stats/stats_screen.dart';

/// Khung chính: thanh điều hướng dưới Học / Ôn tập / Thống kê / Cài đặt.
/// Mỗi lần đổi tab, màn được dựng lại -> số liệu (đến hạn, thống kê) luôn mới.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_tab) {
        0 => _LearnTab(
            onOpenReview: () => setState(() => _tab = 1),
            onOpenShop: () => setState(() => _tab = 3),
          ),
        1 => const ReviewScreen(),
        2 => const StatsScreen(),
        3 => const ShopScreen(),
        _ => const SettingsScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Học'),
          NavigationDestination(icon: Icon(Icons.replay_rounded), label: 'Ôn tập'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Thống kê'),
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Cửa hàng'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

/// Tab Học: thẻ ôn tập SRS + danh sách khóa HSK 1-6 (E9-1) kèm tiến độ.
class _LearnTab extends StatefulWidget {
  final VoidCallback onOpenReview;
  final VoidCallback onOpenShop;
  const _LearnTab({required this.onOpenReview, required this.onOpenShop});

  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  int _due = 0;
  Map<String, int> _studied = {}; // mã khóa -> số từ đã học

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final content = context.read<ContentRepository>();
    final progress = context.read<ProgressRepository>();
    final now = DateTime.now().millisecondsSinceEpoch;
    final studiedIds = {
      for (final e in progress.all())
        if (e.correct + e.wrong > 0) e.cardId,
    };
    final courses = await content.loadCourses();
    final studied = <String, int>{};
    for (final c in courses) {
      final cards = await content.loadCards(c);
      studied[c.code] = cards.where((e) => studiedIds.contains(e.id)).length;
    }
    if (!mounted) return;
    setState(() {
      _due = progress.dueCardIds(now).length;
      _studied = studied;
    });
  }

  Future<void> _openCourse(Course c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonListScreen(course: c)),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          return switch (state) {
            ContentLoading() => const Center(child: CircularProgressIndicator()),
            ContentError(:final message) => Center(child: Text(message)),
            ContentLoaded(:final courses) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _Header(onOpenShop: widget.onOpenShop),
                  const SizedBox(height: 18),
                  _ReviewHero(due: _due, onTap: widget.onOpenReview),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text('Khóa học', style: AppText.display(20))),
                      Text('${courses.length} cấp độ HSK',
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < courses.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CourseTile(
                        course: courses[i],
                        level: i + 1,
                        studied: _studied[courses[i].code] ?? 0,
                        onTap: () => _openCourse(courses[i]),
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

class _Header extends StatelessWidget {
  final VoidCallback onOpenShop;
  const _Header({required this.onOpenShop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chào bạn, hôm nay học gì?',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Học tiếng Trung', maxLines: 1, style: AppText.display(26)),
              ),
            ],
          ),
        ),
        BlocBuilder<SettingsCubit, AppSettings>(
          builder: (context, settings) {
            final streak = context.read<SettingsCubit>().displayStreak;
            final bank = Semantics(
              label: 'Ví ${settings.mushroomBank} nấm — mở cửa hàng',
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
               onTap: onOpenShop,
               child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cinnabarSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MushroomIcon(size: 20),
                    const SizedBox(width: 4),
                    Text(fmtNum(settings.mushroomBank),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cinnabarDeep)),
                  ],
                ),
              ),
              ),
            );
            final streakChip = Semantics(
              label: 'Chuỗi $streak ngày',
              excludeSemantics: true,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 20, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text('$streak',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.goldInk)),
                  ],
                ),
              ),
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [bank, const SizedBox(width: 8), streakChip],
            );
          },
        ),
      ],
    );
  }
}

/// Thẻ ôn tập nổi bật: số từ đến hạn (SRS) + nút mở tab Ôn tập.
class _ReviewHero extends StatelessWidget {
  final int due;
  final VoidCallback onTap;
  const _ReviewHero({required this.due, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(due > 0 ? '$due từ đến hạn' : 'Chưa có từ đến hạn',
                    style: AppText.display(28, color: AppColors.card)),
                const SizedBox(height: 4),
                Text(
                  due > 0 ? 'Ôn ngay để giữ trí nhớ dài hạn' : 'Học bài mới để có thẻ ôn tập',
                  style: const TextStyle(fontSize: 14, color: AppColors.cinnabarSoft),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.cinnabarDeep,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Ôn ngay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;
  final int level;
  final int studied;
  final VoidCallback onTap;
  const _CourseTile({
    required this.course,
    required this.level,
    required this.studied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = course.vocabCount;
    final ratio = total == 0 ? 0.0 : studied / total;
    final started = studied > 0;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SealBadge(hanziNumeral(level), filled: started),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(course.titleVi.replaceAll(' - ', ' · '),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          started ? '${(ratio * 100).round()}%' : 'Mới',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: started ? AppColors.cinnabarDeep : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ProgressTrack(value: ratio),
                    const SizedBox(height: 6),
                    Text('${fmtNum(total)} từ · ${course.lessonCount} bài',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
