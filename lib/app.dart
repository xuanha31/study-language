import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme.dart';
import 'data/content_repository.dart';
import 'data/progress_repository.dart';
import 'data/settings_repository.dart';
import 'features/home/home_screen.dart';
import 'logic/audio_service.dart';
import 'logic/content/content_cubit.dart';
import 'logic/settings/settings_cubit.dart';

class App extends StatelessWidget {
  final ContentRepository contentRepository;
  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;
  final AudioService audioService;

  const App({
    super.key,
    required this.contentRepository,
    required this.progressRepository,
    required this.settingsRepository,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: contentRepository),
        RepositoryProvider.value(value: progressRepository),
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider.value(value: audioService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ContentCubit(contentRepository)..load()),
          BlocProvider(create: (_) => SettingsCubit(settingsRepository)),
        ],
        child: BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (p, c) => p.audioEnabled != c.audioEnabled,
          listener: (_, s) => audioService.enabled = s.audioEnabled,
          child: MaterialApp(
            title: 'Học tiếng Trung',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
