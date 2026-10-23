import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../logic/collection_logic.dart';
import '../models/collection_entry.dart';

class TrackerStore extends ChangeNotifier {
  TrackerStore(this._database);

  final AppDatabase _database;
  List<CollectionEntry> entries = [];

  Future<void> load() async {
    entries = await _database.fetchEntries();
    notifyListeners();
  }

  Future<void> close() => _database.close();

  Future<String?> add({
    required String phone,
    required String bank,
    required String category,
    required String entryDate,
    DateTime? createdAt,
    String? id,
  }) {
    entries = [
      ...entries,
      CollectionEntry(
        id: id ?? newEntryId(),
        phone: phone.trim(),
        bank: bank,
        category: category,
        entryDate: entryDate,
        createdAt: createdAt ?? DateTime.now(),
      ),
    ];
    return _persist();
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
}
