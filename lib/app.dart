import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme.dart';
import 'data/content_repository.dart';
import 'data/progress_repository.dart';
import 'features/home/home_screen.dart';
import 'logic/content/content_cubit.dart';

class App extends StatelessWidget {
  final ContentRepository contentRepository;
  final ProgressRepository progressRepository;

  const App({
    super.key,
    required this.contentRepository,
    required this.progressRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: contentRepository),
        RepositoryProvider.value(value: progressRepository),
      ],
      child: BlocProvider(
        create: (_) => ContentCubit(contentRepository)..load(),
        child: MaterialApp(
          title: 'Học tiếng Trung',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
