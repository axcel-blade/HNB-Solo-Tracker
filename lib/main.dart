import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'database/app_database.dart';
import 'screens/tracker_screen.dart';
import 'services/app_update.dart';
import 'services/tracker_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final store = TrackerStore(AppDatabase.defaults());
  await store.load();
  runApp(
    HnbSoloTrackerApp(
      store: store,
      updates: GithubUpdateChecker(currentVersion: info.version),
    ),
  );
}

class HnbSoloTrackerApp extends StatelessWidget {
  const HnbSoloTrackerApp({
    super.key,
    required this.store,
    this.updates = const DisabledUpdateChecker(),
  });

  final TrackerStore store;
  final UpdateChecker updates;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HNB Solo Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: TrackerScreen(store: store, updates: updates),
    );
  }
}
