import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../logic/collection_logic.dart';
import '../logic/place_routing.dart';
import '../models/collection_entry.dart';
import '../models/place.dart';
import '../models/place_directory.dart';

class TrackerStore extends ChangeNotifier {
  TrackerStore(this._database);

  final AppDatabase _database;
  List<CollectionEntry> entries = [];
  List<CollectionPlace> places = [];

  Future<void> load() async {
    await _database.ensureBuiltInPlaces(builtInPlaces);
    entries = await _database.fetchEntries();
    places = await _database.fetchPlaces();
    notifyListeners();
  }

  Future<void> close() => _database.close();

  Future<String?> add({
    required String phone,
    required String bankType,
    required String memberStatus,
    required String productType,
    required String channelType,
    required String channelDetail,
    String entryDate = '',
    DateTime? createdAt,
    String? id,
  }) {
    final created = createdAt ?? DateTime.now();
    entries = [
      ...entries,
      CollectionEntry(
        id: id ?? newEntryId(),
        phone: phone.trim(),
        bankType: bankType,
        memberStatus: memberStatus,
        productType: productType,
        channelType: channelType,
        channelDetail: channelDetail.trim(),
        entryDate: entryDate.isNotEmpty ? entryDate : isoDate(created.toLocal()),
        createdAt: created,
      ),
    ];
    return _persist();
  }

  Future<PlaceResult> addPlace({
    required OrganizationKind kind,
    required String organization,
    required String name,
  }) async {
    final resolvedOrganization = kind == OrganizationKind.hnb
        ? 'HNB'
        : cleanPlaceName(organization);
    final resolvedName = cleanPlaceName(
      name.isEmpty && kind != OrganizationKind.hnb ? 'Head office' : name,
    );
    if (kind != OrganizationKind.hnb &&
        isHnbOrganization(resolvedOrganization)) {
      return const PlaceResult.fail(useHnbTabMessage);
    }
    final draft = CollectionPlace(
      kind: kind,
      organization: resolvedOrganization,
      name: resolvedName,
    );
    if (routePlace(draft) == null) {
      return const PlaceResult.fail(placeNameMessage);
    }
    if (places.any((place) => place.identity == draft.identity)) {
      return const PlaceResult.fail(duplicatePlaceMessage);
    }
    places = [...places, draft];
    final error = await _persistPlaces();
    if (error != null) {
      places = places
          .where((place) => place.identity != draft.identity)
          .toList();
      return PlaceResult.fail(error);
    }
    final saved = places.where((place) => place.identity == draft.identity);
    if (saved.isEmpty) return const PlaceResult.fail(saveFailedMessage);
    return PlaceResult.ok(saved.first);
  }

  Future<String?> deletePlace(int id) async {
    final match = places.where((place) => place.id == id);
    if (match.isEmpty) return null;
    if (match.first.builtIn) return 'Built-in places stay in the list.';
    final previous = places;
    places = places.where((place) => place.id != id).toList();
    final error = await _persistPlaces();
    if (error != null) places = previous;
    return error;
  }

  Future<String?> delete(String id) {
    entries = entries.where((entry) => entry.id != id).toList();
    return _persist();
  }

  Future<String?> clear() {
    entries = [];
    return _persist();
  }

  Future<String?> replaceAll(List<CollectionEntry> next) {
    entries = List<CollectionEntry>.of(next);
    return _persist();
  }

  Future<String?> _persist() async {
    try {
      await _database.replaceEntries(entries);
      notifyListeners();
      return null;
    } catch (_) {
      notifyListeners();
      return saveFailedMessage;
    }
  }

  Future<String?> _persistPlaces() async {
    try {
      await _database.ensureBuiltInPlaces(builtInPlaces);
      final custom = places.where((place) => !place.builtIn);
      final stored = await _database.fetchPlaces();
      for (final place in stored.where((place) => !place.builtIn)) {
        final keep = custom.any((item) => item.identity == place.identity);
        if (!keep && place.id != null) {
          await _database.deleteCustomPlace(place.id!);
        }
      }
      final keys = stored.map((place) => place.identity).toSet();
      final missing = [
        for (final place in custom)
          if (!keys.contains(place.identity)) place,
      ];
      if (missing.isNotEmpty) await _database.insertPlaces(missing);
      places = await _database.fetchPlaces();
      notifyListeners();
      return null;
    } catch (_) {
      notifyListeners();
      return saveFailedMessage;
    }
  }
}
