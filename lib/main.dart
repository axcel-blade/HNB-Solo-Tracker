import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'screens/tracker_screen.dart';
import 'services/tracker_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TrackerStore(AppDatabase.defaults());
  await store.load();
  runApp(HnbSoloTrackerApp(store: store));
}

class HnbSoloTrackerApp extends StatelessWidget {
  const HnbSoloTrackerApp({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HNB Solo Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: TrackerScreen(store: store),
    );
  }
}
