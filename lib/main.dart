import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/content_repository.dart';
import 'data/progress_repository.dart';
import 'data/settings_repository.dart';
import 'logic/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final progress = await ProgressRepository.open();
  final settings = await SettingsRepository.open();
  final audio = AudioService()..enabled = settings.load().audioEnabled;
  runApp(App(
    contentRepository: ContentRepository(),
    progressRepository: progress,
    settingsRepository: settings,
    audioService: audio,
  ));
}
