import 'dart:math';

import 'catalog.dart';
import 'registration_catalog.dart';

class CollectionEntry {
  const CollectionEntry({
    required this.id,
    required this.phone,
    required this.bankType,
    required this.memberStatus,
    required this.productType,
    required this.channelType,
    required this.channelDetail,
    required this.entryDate,
    required this.createdAt,
  });

  final String id;
  final String phone;
  final String bankType;
  final String memberStatus;
  final String productType;
  final String channelType;
  final String channelDetail;
  final String entryDate;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': createdAt?.toUtc().toIso8601String() ?? '',
      'phoneNumber': phone,
      'bankType': bankType,
      'memberStatus': memberStatus,
      'productType': productType,
      'channelType': channelType,
      'channelDetail': channelDetail,
      if (entryDate.isNotEmpty) 'entryDate': entryDate,
    };
  }

  static CollectionEntry? fromLoose(dynamic raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    if (json.containsKey('bankType') || json.containsKey('phoneNumber')) {
      return _registrationFromJson(json, strict: false);
    }
    return _legacyFromJson(json, strict: false);
  }

  static CollectionEntry? tryImport(
    dynamic raw, {
    DateTime? fallbackCreatedAt,
  }) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    if (json.containsKey('bankType') || json.containsKey('phoneNumber')) {
      return _registrationFromJson(
        json,
        strict: true,
        fallbackCreatedAt: fallbackCreatedAt,
      );
    }
    return _legacyFromJson(
      json,
      strict: true,
      fallbackCreatedAt: fallbackCreatedAt,
    );
  }

  static CollectionEntry fromStored({
    required String id,
    required String phone,
    required String bank,
    required String category,
    required String entryDate,
    required DateTime? createdAt,
    required String place,
    required String organizationKind,
    required String bankType,
    required String memberStatus,
    required String productType,
    required String channelType,
    required String channelDetail,
  }) {
    if (bankType.isNotEmpty) {
      return CollectionEntry(
        id: id,
        phone: phone,
        bankType: bankType,
        memberStatus: memberStatus,
        productType: productType.isNotEmpty ? productType : category,
        channelType: channelType.isNotEmpty ? channelType : organizationKind,
        channelDetail: channelDetail.isNotEmpty ? channelDetail : place,
        entryDate: entryDate,
        createdAt: createdAt,
      );
    }
    return fromLegacy(
      id: id,
      phone: phone,
      bank: bank,
      category: category,
      entryDate: entryDate,
      createdAt: createdAt,
      place: place,
      organizationKind: organizationKind,
    );
  }

  static CollectionEntry fromLegacy({
    required String id,
    required String phone,
    required String bank,
    required String category,
    required String entryDate,
    required DateTime? createdAt,
    required String place,
    required String organizationKind,
  }) {
    final categoryId =
        SoloCategory.byId(category)?.id ??
        SoloCategory.byName(category)?.id ??
        category;
    final hnb =
        organizationKind == 'hnb' ||
        (bank == 'HNB' &&
            organizationKind != 'bank' &&
            organizationKind != 'company');
    final memberStatus = hnb
        ? MemberStatuses.oldActive
        : categoryId == 'card'
        ? MemberStatuses.card
        : MemberStatuses.account;
    final productType = hnb
        ? (categoryId == 'hnbacc' ? ProductTypes.hnbAcc : ProductTypes.soloMax)
        : ProductTypes.external;
    final branchVisit = organizationKind == 'hnb' || (hnb && place.isNotEmpty);
    final channelType = branchVisit
        ? ChannelTypes.branch
        : ChannelTypes.ownVisit;
    final channelDetail = branchVisit
        ? (place.isEmpty ? 'HNB' : place)
        : (place.isNotEmpty
              ? place
              : (bank.isEmpty ? 'Direct Own Visit' : bank));
    return CollectionEntry(
      id: id,
      phone: phone,
      bankType: hnb ? BankTypes.hnb : BankTypes.other,
      memberStatus: memberStatus,
      productType: productType,
      channelType: channelType,
      channelDetail: channelDetail,
      entryDate: entryDate,
      createdAt: createdAt,
    );
  }
}

CollectionEntry? _registrationFromJson(
  Map<String, dynamic> json, {
  required bool strict,
  DateTime? fallbackCreatedAt,
}) {
  final phoneRaw = json['phoneNumber'] ?? json['phone'];
  if (phoneRaw is! String) return null;
  final phone = phoneRaw.trim();
  if (phone.isEmpty || phone.length > 120) return null;
  final bankType = json['bankType']?.toString() ?? '';
  final memberStatus = json['memberStatus']?.toString() ?? '';
  final productType = json['productType']?.toString() ?? '';
  final channelType = json['channelType']?.toString() ?? '';
  final detailRaw = json['channelDetail'];
  if (strict && detailRaw is! String) return null;
  final channelDetail = detailRaw?.toString().trim() ?? '';
  if (!_knownRegistration(
    bankType: bankType,
    memberStatus: memberStatus,
    productType: productType,
    channelType: channelType,
    channelDetail: channelDetail,
  )) {
    return null;
  }
  final created = _createdAt(json, fallbackCreatedAt);
  final entryDate = _entryDate(json, created);
  if (entryDate == null) return null;
  return CollectionEntry(
    id: _idOf(json['id']),
    phone: phone,
    bankType: bankType,
    memberStatus: memberStatus,
    productType: productType,
    channelType: channelType,
    channelDetail: channelDetail,
    entryDate: entryDate,
    createdAt: created,
  );
}

bool _knownRegistration({
  required String bankType,
  required String memberStatus,
  required String productType,
  required String channelType,
  required String channelDetail,
}) {
  if (channelDetail.isEmpty || channelDetail.length > 240) return false;
  if (channelType != ChannelTypes.branch &&
      channelType != ChannelTypes.department &&
      channelType != ChannelTypes.ownVisit) {
    return false;
  }
  if (bankType == BankTypes.hnb) {
    return (memberStatus == MemberStatuses.oldActive ||
            memberStatus == MemberStatuses.newActive) &&
        (productType == ProductTypes.soloMax ||
            productType == ProductTypes.hnbAcc);
  }
  if (bankType == BankTypes.other) {
    return (memberStatus == MemberStatuses.card ||
            memberStatus == MemberStatuses.account) &&
        productType == ProductTypes.external;
  }
  return false;
}

CollectionEntry? _legacyFromJson(
  Map<String, dynamic> json, {
  required bool strict,
  DateTime? fallbackCreatedAt,
}) {
  final phone = json['phone'];
  final bank = json['bank'];
  final category = json['category'];
  if (phone is! String || phone.trim().isEmpty) return null;
  if (bank is! String || bank.trim().isEmpty || bank.trim().length > 80) {
    return null;
  }
  if (category is! String) return null;
  final known =
      SoloCategory.byId(category) ?? SoloCategory.byName(category);
  if (strict && known == null) return null;
  final place = json['place'];
  if (place != null && place is! String) return null;
  final kindRaw = json['organizationKind'];
  if (kindRaw != null && kindRaw is! String) return null;
  final kind = kindRaw is String ? kindRaw : '';
  if (kind.isNotEmpty &&
      kind != 'hnb' &&
      kind != 'bank' &&
      kind != 'company') {
    return null;
  }
  final bankName = bank.trim();
  if (strict && kind == 'hnb' && bankName != 'HNB') return null;
  if (strict &&
      (kind == 'bank' || kind == 'company') &&
      bankName == 'HNB') {
    return null;
  }
  final created = _createdAt(json, fallbackCreatedAt);
  final entryDate = _entryDate(json, created);
  if (entryDate == null) return null;
  return CollectionEntry.fromLegacy(
    id: _idOf(json['id']),
    phone: phone.trim(),
    bank: bankName,
    category: known?.id ?? category,
    entryDate: entryDate,
    createdAt: created,
    place: place is String ? place.trim() : '',
    organizationKind: kind,
  );
}

DateTime? _createdAt(Map<String, dynamic> json, DateTime? fallback) {
  final raw = json['timestamp'] ?? json['createdAt'];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw) ?? fallback;
  }
  return fallback;
}

String? _entryDate(Map<String, dynamic> json, DateTime? createdAt) {
  final raw = json['entryDate'];
  if (raw is String && raw.isNotEmpty) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;
    return raw;
  }
  if (raw != null && raw is! String) return null;
  if (createdAt == null) return '';
  final local = createdAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _idOf(dynamic raw) {
  if (raw is String && raw.trim().isNotEmpty) return raw;
  if (raw != null && raw.toString().trim().isNotEmpty) return raw.toString();
  return newEntryId();
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
