import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnb_solo_tracker/database/app_database.dart';
import 'package:hnb_solo_tracker/main.dart';
import 'package:hnb_solo_tracker/services/app_update.dart';
import 'package:hnb_solo_tracker/services/tracker_store.dart';
import 'package:hnb_solo_tracker/widgets/options_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saves a collection through the bank and category steps', (
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

    expect(find.text('Solo Collection Tracker'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Continue to options →'));
    await tester.pump();
    expect(
      find.text('Please check the phone number and try again.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '0771234567');
    await tester.tap(find.text('Continue to options →'));
    await tester.pumpAndSettle();

    expect(find.text('Where was this number collected?'), findsOneWidget);
    final dialog = find.byType(OptionsDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Kandy',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Kandy',
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();

    expect(find.text('Select the Solo category'), findsOneWidget);
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Solo Max')),
    );
    await tester.pump();
    await tester.tap(find.text('Save entry ✓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('0771234567'), findsOneWidget);
    expect(find.text('Entry saved as HNB · Kandy.'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);
    expect(store.entries, hasLength(1));
    expect(store.entries.single.bank, 'HNB');
    expect(store.entries.single.place, 'Kandy');
    expect(store.entries.single.organizationKind, 'hnb');
    expect(store.entries.single.category, 'max');

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No entries yet'), findsOneWidget);
    expect(store.entries, isEmpty);
    expect(find.text('Entry deleted.'), findsOneWidget);
  });

  testWidgets('narrow and desktop layouts render without overflow', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final store = TrackerStore(AppDatabase(NativeDatabase.memory()));
    await store.load();
    addTearDown(store.close);

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(HnbSoloTrackerApp(store: store));
      await tester.pump();
      expect(find.text('Add a collection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('other bank visits are not recorded as HNB', (tester) async {
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

    await tester.enterText(find.byType(TextField), '0715555555');
    await tester.tap(find.text('Continue to options →'));
    await tester.pumpAndSettle();

    final dialog = find.byType(OptionsDialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Other banks')),
    );
    await tester.pump();
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Commercial',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.text('Commercial Bank · Head office'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Credit/Debit')),
    );
    await tester.pump();
    await tester.tap(find.text('Save entry ✓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.entries.single.bank, 'Commercial Bank');
    expect(store.entries.single.organizationKind, 'bank');
    expect(store.entries.single.place, 'Head office');
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
