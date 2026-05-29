import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/content_repository.dart';
import 'data/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final progress = await ProgressRepository.open();
  runApp(App(
    contentRepository: ContentRepository(),
    progressRepository: progress,
  ));
}
