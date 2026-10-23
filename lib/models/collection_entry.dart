import 'dart:math';

import 'catalog.dart';

class CollectionEntry {
  const CollectionEntry({
    required this.id,
    required this.phone,
    required this.bank,
    required this.category,
    required this.entryDate,
    required this.createdAt,
  });

  final String id;
  final String phone;
  final String bank;
  final String category;
  final String entryDate;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'bank': bank,
      'category': category,
      'entryDate': entryDate,
      if (createdAt != null)
        'createdAt': createdAt!.toUtc().toIso8601String(),
    };
  }

  static CollectionEntry? fromLoose(dynamic raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    final createdRaw = json['createdAt']?.toString();
    return CollectionEntry(
      id: _idOf(json['id']),
      phone: json['phone']?.toString() ?? '',
      bank: json['bank']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      entryDate: json['entryDate']?.toString() ?? '',
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }

  /// Accepts a backup object the way the reference site does:
  /// phone must be a string, bank must be HNB or Other Bank, and category
  /// must be a known id.
  static CollectionEntry? tryImport(dynamic raw, {DateTime? fallbackCreatedAt}) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    final phone = json['phone'];
    final bank = json['bank'];
    final category = json['category'];
    if (phone is! String) return null;
    if (bank is! String || !BankOption.names.contains(bank)) return null;
    if (category is! String || SoloCategory.byId(category) == null) return null;
    final createdRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }
    createdAt ??= fallbackCreatedAt;
    final entryDate = json['entryDate'];
    return CollectionEntry(
      id: _idOf(json['id']),
      phone: phone,
      bank: bank,
      category: category,
      entryDate: entryDate is String ? entryDate : '',
      createdAt: createdAt,
    );
  }

  static String _idOf(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw;
    if (raw != null && raw.toString().trim().isNotEmpty) return raw.toString();
    return newEntryId();
  }
}

String newEntryId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
