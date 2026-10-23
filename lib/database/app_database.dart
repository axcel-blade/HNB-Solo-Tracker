import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/collection_entry.dart';
import '../models/place.dart';

part 'app_database.g.dart';

class Entries extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get id => text()();
  TextColumn get phone => text()();
  TextColumn get bank => text()();
  TextColumn get category => text()();
  TextColumn get entryDate => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get place => text().withDefault(const Constant(''))();
  TextColumn get organizationKind => text().withDefault(const Constant(''))();
}

class Places extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get organization => text()();
  TextColumn get name => text()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Entries, Places])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(entries, entries.place);
        await migrator.addColumn(entries, entries.organizationKind);
        await migrator.createTable(places);
      }
    },
  );

  Future<List<CollectionEntry>> fetchEntries() async {
    final rows = await (select(
      entries,
    )..orderBy([(row) => OrderingTerm.asc(row.localId)])).get();
    return [
      for (final row in rows)
        CollectionEntry(
          id: row.id,
          phone: row.phone,
          bank: row.bank,
          category: row.category,
          entryDate: row.entryDate,
          createdAt: row.createdAt,
          place: row.place,
          organizationKind: row.organizationKind,
        ),
    ];
  }

  Future<void> ensureBuiltInPlaces(List<CollectionPlace> builtIns) async {
    final current = await fetchPlaces();
    final keys = current.map((place) => place.identity).toSet();
    final missing = [
      for (final place in builtIns)
        if (!keys.contains(place.identity)) place,
    ];
    if (missing.isEmpty) return;
    await insertPlaces([
      for (final place in missing)
        CollectionPlace(
          kind: place.kind,
          organization: place.organization,
          name: place.name,
          builtIn: true,
        ),
    ]);
  }

  Future<void> insertPlaces(List<CollectionPlace> next) async {
    if (next.isEmpty) return;
    await batch((batch) {
      batch.insertAll(places, [
        for (final place in next)
          PlacesCompanion.insert(
            kind: place.kind.id,
            organization: place.organization,
            name: place.name,
            builtIn: Value(place.builtIn),
          ),
      ]);
    });
  }

  Future<List<CollectionPlace>> fetchPlaces() async {
    final rows =
        await (select(places)..orderBy([
              (row) => OrderingTerm.asc(row.organization),
              (row) => OrderingTerm.asc(row.name),
            ]))
            .get();
    final mapped = <CollectionPlace>[];
    for (final row in rows) {
      final kind = OrganizationKind.byId(row.kind);
      if (kind == null) continue;
      mapped.add(
        CollectionPlace(
          id: row.id,
          kind: kind,
          organization: row.organization,
          name: row.name,
          builtIn: row.builtIn,
        ),
      );
    }
    return mapped;
  }

  Future<void> deleteCustomPlace(int id) async {
    await (delete(
      places,
    )..where((row) => row.id.equals(id) & row.builtIn.equals(false))).go();
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
              place: Value(entry.place),
              organizationKind: Value(entry.organizationKind),
            ),
        ]);
      });
    });
  }
}
