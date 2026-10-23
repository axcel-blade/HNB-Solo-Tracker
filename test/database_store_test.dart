import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/database/app_database.dart';
import 'package:hnb_solo_tracker/logic/collection_logic.dart';
import 'package:hnb_solo_tracker/logic/place_routing.dart';
import 'package:hnb_solo_tracker/models/collection_entry.dart';
import 'package:hnb_solo_tracker/models/place.dart';
import 'package:hnb_solo_tracker/models/registration_catalog.dart';
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
      bankType: BankTypes.hnb,
      memberStatus: MemberStatuses.oldActive,
      productType: ProductTypes.soloMax,
      channelType: ChannelTypes.branch,
      channelDetail: 'HNB Negombo Main Branch',
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
    expect(saved.bankType, BankTypes.hnb);
    expect(saved.productType, ProductTypes.soloMax);
    expect(saved.channelDetail, 'HNB Negombo Main Branch');
    expect(saved.entryDate, '2026-10-01');
    expect(saved.createdAt?.toUtc(), DateTime.utc(2026, 10, 1, 8, 30));
  });

  test('reload keeps insertion order and counts known categories', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = await openStore(database);

    await store.add(
      phone: '0770000001',
      bankType: BankTypes.hnb,
      memberStatus: MemberStatuses.oldActive,
      productType: ProductTypes.soloMax,
      channelType: ChannelTypes.branch,
      channelDetail: 'Kandy - Main',
      entryDate: '2026-10-01',
      id: 'older',
    );
    await store.add(
      phone: '0770000002',
      bankType: BankTypes.other,
      memberStatus: MemberStatuses.card,
      productType: ProductTypes.external,
      channelType: ChannelTypes.ownVisit,
      channelDetail: 'Direct Own Visit',
      entryDate: '2026-10-02',
      id: 'newer',
    );

    final reloaded = await openStore(database);
    expect(reloaded.entries.map((entry) => entry.id), ['older', 'newer']);
    expect(newestFirst(reloaded.entries).map((entry) => entry.id), [
      'newer',
      'older',
    ]);
    final stats = registrationStats(reloaded.entries);
    expect(stats.hnb, 1);
    expect(stats.other, 1);
    expect(stats.total, 2);
  });

  test('delete, replace, and clear are stored in sqlite', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = await openStore(database);
    await store.add(
      phone: '0770000001',
      bankType: BankTypes.hnb,
      memberStatus: MemberStatuses.newActive,
      productType: ProductTypes.hnbAcc,
      channelType: ChannelTypes.branch,
      channelDetail: 'Kandy - Main',
      entryDate: '2026-10-03',
      id: 'keep-me',
    );
    await store.add(
      phone: '0770000002',
      bankType: BankTypes.hnb,
      memberStatus: MemberStatuses.oldActive,
      productType: ProductTypes.soloMax,
      channelType: ChannelTypes.department,
      channelDetail: 'HNB Tower - Finance & Accounts',
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
        bankType: BankTypes.other,
        memberStatus: MemberStatuses.card,
        productType: ProductTypes.external,
        channelType: ChannelTypes.ownVisit,
        channelDetail: 'Direct Own Visit',
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

  test('HNB branches stay separate from other banks and companies', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = await openStore(database);

    final hnbKandy = store.places.singleWhere(
      (place) => place.kind == OrganizationKind.hnb && place.name == 'Kandy',
    );
    expect(hnbKandy.organization, 'HNB');
    expect(
      store.places.where(
        (place) => place.kind != OrganizationKind.hnb && place.name == 'Kandy',
      ),
      isEmpty,
    );

    final added = await store.addPlace(
      kind: OrganizationKind.bank,
      organization: 'Commercial Bank',
      name: 'Kandy',
    );
    expect(added.error, isNull);
    expect(added.place!.builtIn, isFalse);
    expect(routePlace(added.place!)!.bank, 'Commercial Bank');

    final blocked = await store.addPlace(
      kind: OrganizationKind.company,
      organization: 'HNB',
      name: 'Colombo',
    );
    expect(blocked.error, useHnbTabMessage);

    final saved = await store.add(
      phone: '0771234567',
      bankType: BankTypes.other,
      memberStatus: MemberStatuses.card,
      productType: ProductTypes.external,
      channelType: ChannelTypes.ownVisit,
      channelDetail: 'Kandy',
      entryDate: '2026-10-02',
      id: 'visit',
    );
    expect(saved, isNull);

    final reloaded = await openStore(database);
    expect(reloaded.entries.single.channelDetail, 'Kandy');
    expect(reloaded.entries.single.bankType, BankTypes.other);
    expect(
      reloaded.places.any(
        (place) =>
            place.kind == OrganizationKind.bank &&
            place.organization == 'Commercial Bank' &&
            place.name == 'Kandy' &&
            !place.builtIn,
      ),
      isTrue,
    );

    final customId = reloaded.places
        .singleWhere(
          (place) =>
              place.organization == 'Commercial Bank' && place.name == 'Kandy',
        )
        .id!;
    expect(await reloaded.deletePlace(customId), isNull);
    expect(
      await reloaded.deletePlace(hnbKandy.id!),
      'Built-in places stay in the list.',
    );
    final afterDelete = await openStore(database);
    expect(
      afterDelete.places.any(
        (place) => place.name == 'Kandy' && !place.builtIn,
      ),
      isFalse,
    );
  });
}
