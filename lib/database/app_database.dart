import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/collection_entry.dart';

part 'app_database.g.dart';

class Entries extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get id => text()();
  TextColumn get phone => text()();
  TextColumn get bank => text()();
  TextColumn get category => text()();
  TextColumn get entryDate => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database: a sqlite file on mobile and desktop, and
  /// Drift's wasm sqlite database in the browser.
  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'solo_collection',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  Future<List<CollectionEntry>> fetchEntries() async {
    final rows = await (select(entries)
          ..orderBy([(row) => OrderingTerm.asc(row.localId)]))
        .get();
    return [
      for (final row in rows)
        CollectionEntry(
          id: row.id,
          phone: row.phone,
          bank: row.bank,
          category: row.category,
          entryDate: row.entryDate,
          createdAt: row.createdAt,
        ),
    ];
  }

  Future<void> replaceEntries(List<CollectionEntry> next) {
    return transaction(() async {
      await delete(entries).go();
      if (next.isEmpty) return;
      await batch((batch) {
        batch.insertAll(entries, [
          for (final entry in next)
            EntriesCompanion.insert(
              id: entry.id,
              phone: entry.phone,
              bank: entry.bank,
              category: entry.category,
              entryDate: entry.entryDate,
              createdAt: Value(entry.createdAt),
            ),
        ]);
      });
    });
  }
}
