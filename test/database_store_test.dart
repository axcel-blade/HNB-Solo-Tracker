import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/database/app_database.dart';
import 'package:hnb_solo_tracker/logic/collection_logic.dart';
import 'package:hnb_solo_tracker/models/collection_entry.dart';
import 'package:hnb_solo_tracker/services/tracker_store.dart';

Future<TrackerStore> openStore(AppDatabase database) async {
  final store = TrackerStore(database);
  await store.load();
  return store;
}

void main() {
  test('entries survive a new store opened on the same database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final store = await openStore(database);
    final error = await store.add(
      phone: '0771234567',
      bank: 'HNB',
      category: 'max',
      entryDate: '2026-10-01',
      id: 'entry-1',
      createdAt: DateTime.utc(2026, 10, 1, 8, 30),
    );
    expect(error, isNull);

    final reloaded = await openStore(database);
    expect(reloaded.entries, hasLength(1));
    final saved = reloaded.entries.single;
    expect(saved.id, 'entry-1');
    expect(saved.phone, '0771234567');
    expect(saved.bank, 'HNB');
    expect(saved.category, 'max');
    expect(saved.entryDate, '2026-10-01');
    expect(saved.createdAt?.toUtc(), DateTime.utc(2026, 10, 1, 8, 30));
  });

  test('reload keeps insertion order and counts known categories', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = await openStore(database);

    await store.add(
      phone: '0770000001',
      bank: 'HNB',
      category: 'max',
      entryDate: '2026-10-01',
      id: 'older',
    );
    await store.add(
      phone: '0770000002',
      bank: 'Other Bank',
      category: 'card',
      entryDate: '2026-10-02',
      id: 'newer',
    );

    final reloaded = await openStore(database);
    expect(reloaded.entries.map((entry) => entry.id), ['older', 'newer']);
    expect(newestFirst(reloaded.entries).map((entry) => entry.id), [
      'newer',
      'older',
    ]);
    final counts = countEntries(reloaded.entries);
    expect(counts.max, 1);
    expect(counts.card, 1);
    expect(counts.total, 2);
  });

  test('delete, replace, and clear are stored in sqlite', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = await openStore(database);
    await store.add(
      phone: '0770000001',
      bank: 'HNB',
      category: 'hnbacc',
      entryDate: '2026-10-03',
      id: 'keep-me',
    );
    await store.add(
      phone: '0770000002',
      bank: 'HNB',
      category: 'bank',
      entryDate: '2026-10-04',
      id: 'drop-me',
    );
    await store.delete('drop-me');

    final afterDelete = await openStore(database);
    expect(afterDelete.entries.map((entry) => entry.id), ['keep-me']);

    await afterDelete.replaceAll([
      const CollectionEntry(
        id: 'imported',
        phone: '0710000000',
        bank: 'Other Bank',
        category: 'card',
        entryDate: '2026-09-01',
        createdAt: null,
      ),
    ]);
    final afterImport = await openStore(database);
    expect(afterImport.entries.single.id, 'imported');
    expect(afterImport.entries.single.createdAt, isNull);

    await afterImport.clear();
    final afterClear = await openStore(database);
    expect(afterClear.entries, isEmpty);
  });
}
