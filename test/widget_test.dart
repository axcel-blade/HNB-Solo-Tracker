import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnb_solo_tracker/database/app_database.dart';
import 'package:hnb_solo_tracker/main.dart';
import 'package:hnb_solo_tracker/models/registration_catalog.dart';
import 'package:hnb_solo_tracker/services/app_update.dart';
import 'package:hnb_solo_tracker/services/tracker_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saves an HNB registration and can delete it', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = TrackerStore(AppDatabase(NativeDatabase.memory()));
    await store.load();
    addTearDown(store.close);

    await tester.pumpWidget(HnbSoloTrackerApp(store: store));
    await tester.pump();

    expect(find.text('HNB Solo Tracker'), findsOneWidget);
    expect(find.text('New Customer Entry Form'), findsOneWidget);
    expect(
      find.text('No entries recorded yet. Use the entry form above to log data.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save Customer Entry'));
    await tester.pump();
    expect(find.text('Enter a contact or reference number.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reference-field')), 'Ref #1029');
    await tester.tap(find.text('Save Customer Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ref #1029'), findsOneWidget);
    expect(
      find.text('Customer registration entry added successfully!'),
      findsOneWidget,
    );
    expect(store.entries, hasLength(1));
    expect(store.entries.single.bankType, BankTypes.hnb);
    expect(store.entries.single.memberStatus, MemberStatuses.oldActive);
    expect(store.entries.single.productType, ProductTypes.soloMax);
    expect(store.entries.single.channelType, ChannelTypes.branch);
    expect(store.entries.single.channelDetail, 'HNB Negombo Main Branch');
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byTooltip('Delete record'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('No entries recorded yet. Use the entry form above to log data.'),
      findsOneWidget,
    );
    expect(store.entries, isEmpty);
    expect(find.text('Entry removed from log.'), findsOneWidget);
  });

  testWidgets('narrow and desktop layouts render without overflow', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final store = TrackerStore(AppDatabase(NativeDatabase.memory()));
    await store.load();
    addTearDown(store.close);

    for (final size in const [Size(390, 900), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(HnbSoloTrackerApp(store: store));
      await tester.pump();
      expect(find.text('New Customer Entry Form'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('other bank visits record an external payment source', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = TrackerStore(AppDatabase(NativeDatabase.memory()));
    await store.load();
    addTearDown(store.close);
    await tester.pumpWidget(HnbSoloTrackerApp(store: store));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('reference-field')), '0715555555');
    await tester.tap(find.text('Other Bank').first);
    await tester.pump();
    expect(find.text('Credit / Debit Card'), findsOneWidget);
    expect(find.text('SOLO MAX'), findsNothing);
    await tester.tap(find.text('Own Visit').first);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('visit-field')), 'Majestic City Promo');
    await tester.tap(find.text('Save Customer Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.entries.single.bankType, BankTypes.other);
    expect(store.entries.single.memberStatus, MemberStatuses.card);
    expect(store.entries.single.productType, ProductTypes.external);
    expect(store.entries.single.channelType, ChannelTypes.ownVisit);
    expect(store.entries.single.channelDetail, 'Majestic City Promo');
  });

  testWidgets('startup and settings show a GitHub update', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = TrackerStore(AppDatabase(NativeDatabase.memory()));
    await store.load();
    addTearDown(store.close);
    final updates = _ScriptedUpdates([
      const UpdateResult.available(
        currentVersion: '1.0.0',
        latestVersion: '1.2.0',
        pageUrl:
            'https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/v1.2.0',
        notes: 'Branch routing and update checks.',
      ),
      const UpdateResult.upToDate('1.0.0'),
    ]);

    await tester.pumpWidget(HnbSoloTrackerApp(store: store, updates: updates));
    await tester.pumpAndSettle();

    expect(find.text(updateAvailableTitle), findsOneWidget);
    expect(find.textContaining('1.2.0'), findsWidgets);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Axcel Blade'), findsWidgets);
    expect(find.text('@axcel-blade'), findsOneWidget);
    expect(find.text('https://github.com/axcel-blade'), findsOneWidget);
    expect(find.text('HNB branches'), findsOneWidget);
    expect(find.text('Other companies'), findsOneWidget);

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('latest version'), findsOneWidget);
    expect(updates.calls, 2);
  });
}

class _ScriptedUpdates implements UpdateChecker {
  _ScriptedUpdates(this._results);

  final List<UpdateResult> _results;
  var calls = 0;

  @override
  String get currentVersion => '1.0.0';

  @override
  Future<UpdateResult> check() async {
    final result = _results[calls];
    calls += 1;
    return result;
  }
}
