import 'dart:convert';

import '../models/catalog.dart';
import '../models/collection_entry.dart';
import '../models/registration_catalog.dart';

const saveFailedMessage =
    'Could not save: browser storage may be full or disabled. Export a backup.';
const referenceRequiredMessage = 'Enter a contact or reference number.';
const dateOrderMessage = 'The start date must be before the end date.';
const exportDatesRequiredMessage = 'Please select both start and end dates.';
const emptyRangeMessage = 'No records found within the selected date range.';
const invalidJsonMessage = 'Could not import. Choose a valid JSON backup file.';
const invalidCsvMessage = 'Could not import. Choose a valid CSV file.';
const savedMessage = 'Customer registration entry added successfully!';
const deletedMessage = 'Entry removed from log.';
const clearedMessage = 'All records have been cleared.';
const nothingToClearMessage = 'There are no entries to clear.';

const csvHeader = [
  'Timestamp',
  'Reference Number',
  'Bank Category',
  'Member Status/Source',
  'Product Type',
  'Channel Type',
  'Channel Detail',
];

const legacyCsvHeader = [
  'Phone number',
  'Bank',
  'Category',
  'Entry date',
  'Saved date and time',
];

const legacyPlaceCsvHeader = [
  'Phone number',
  'Bank',
  'Place',
  'Kind',
  'Category',
  'Entry date',
  'Saved date and time',
];

class RegistrationInput {
  const RegistrationInput({
    required this.phone,
    required this.bankType,
    required this.hnbMemberStatus,
    required this.hnbProduct,
    required this.otherSource,
    required this.channelType,
    required this.branch,
    required this.department,
    required this.ownVisit,
  });

  final String phone;
  final String bankType;
  final String hnbMemberStatus;
  final String hnbProduct;
  final String otherSource;
  final String channelType;
  final String branch;
  final String department;
  final String ownVisit;
}

class RegistrationStats {
  const RegistrationStats({
    required this.total,
    required this.hnb,
    required this.other,
    required this.branches,
    required this.departments,
    required this.ownVisits,
  });

  final int total;
  final int hnb;
  final int other;
  final int branches;
  final int departments;
  final int ownVisits;

  String get hnbPercent {
    if (total == 0) return '0';
    return ((hnb / total) * 100).toStringAsFixed(1);
  }
}

class ReportBuild {
  const ReportBuild._({
    required this.error,
    required this.entries,
    required this.from,
    required this.to,
  });

  const ReportBuild.fail(String message)
    : this._(error: message, entries: const [], from: '', to: '');

  const ReportBuild.ok({
    required List<CollectionEntry> entries,
    required String from,
    required String to,
  }) : this._(error: null, entries: entries, from: from, to: to);

  final String? error;
  final List<CollectionEntry> entries;
  final String from;
  final String to;

  int get count => entries.length;

  String filename(String extension) =>
      'HNB_Solo_Report_${from}_to_$to.$extension';

  String get csv => toCsv(entries);

  String get json => encodeBackup(entries);
}

class CsvMergeResult {
  const CsvMergeResult({
    required this.entries,
    required this.imported,
    required this.skippedDuplicates,
    required this.skippedInvalid,
    required this.error,
  });

  final List<CollectionEntry> entries;
  final int imported;
  final int skippedDuplicates;
  final int skippedInvalid;
  final String? error;

  String get message {
    if (error != null) return error!;
    if (imported == 0 && skippedDuplicates == 0) return invalidCsvMessage;
    final duplicateBit = skippedDuplicates == 1
        ? '1 duplicate'
        : '$skippedDuplicates duplicates';
    final invalidBit = skippedInvalid == 0
        ? ''
        : skippedInvalid == 1
        ? ' and 1 invalid row'
        : ' and $skippedInvalid invalid rows';
    return 'Imported $imported entries. Skipped $duplicateBit$invalidBit.';
  }
}

String? registrationError(RegistrationInput input) {
  final phone = input.phone.trim();
  if (phone.isEmpty) return referenceRequiredMessage;
  if (phone.length > 120) return referenceRequiredMessage;
  return null;
}

CollectionEntry registrationFrom(
  RegistrationInput input, {
  DateTime? createdAt,
  String? id,
}) {
  final created = createdAt ?? DateTime.now();
  final hnb = input.bankType == BankTypes.hnb;
  final detail = switch (input.channelType) {
    ChannelTypes.branch => input.branch.trim(),
    ChannelTypes.department => 'HNB Tower - ${input.department.trim()}',
    _ => input.ownVisit.trim().isEmpty
        ? 'Direct Own Visit'
        : input.ownVisit.trim(),
  };
  return CollectionEntry(
    id: id ?? newEntryId(),
    phone: input.phone.trim(),
    bankType: hnb ? BankTypes.hnb : BankTypes.other,
    memberStatus: hnb ? input.hnbMemberStatus : input.otherSource,
    productType: hnb ? input.hnbProduct : ProductTypes.external,
    channelType: input.channelType,
    channelDetail: detail,
    entryDate: isoDate(created.toLocal()),
    createdAt: created,
  );
}

RegistrationStats registrationStats(List<CollectionEntry> entries) {
  var hnb = 0;
  var other = 0;
  var branches = 0;
  var departments = 0;
  var ownVisits = 0;
  for (final entry in entries) {
    if (entry.bankType == BankTypes.hnb) {
      hnb++;
    } else if (entry.bankType == BankTypes.other) {
      other++;
    }
    switch (entry.channelType) {
      case ChannelTypes.branch:
        branches++;
      case ChannelTypes.department:
        departments++;
      case ChannelTypes.ownVisit:
        ownVisits++;
    }
  }
  return RegistrationStats(
    total: entries.length,
    hnb: hnb,
    other: other,
    branches: branches,
    departments: departments,
    ownVisits: ownVisits,
  );
}

List<CollectionEntry> newestFirst(List<CollectionEntry> entries) {
  return entries.reversed.toList(growable: false);
}

List<CollectionEntry> filterRecords(
  List<CollectionEntry> entries,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return newestFirst(entries);
  return [
    for (final entry in newestFirst(entries))
      if (_matches(entry, needle)) entry,
  ];
}

bool _matches(CollectionEntry entry, String needle) {
  final haystack = [
    entry.phone,
    entry.bankType,
    entry.memberStatus,
    entry.productType,
    entry.channelType,
    entry.channelDetail,
  ].join('\n').toLowerCase();
  return haystack.contains(needle);
}

String isoDate(DateTime value) {
  final local = DateTime(value.year, value.month, value.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String formatEntryDate(String entryDate) {
  final parsed = DateTime.tryParse('${entryDate}T12:00:00');
  if (parsed == null) return entryDate;
  return '${parsed.month}/${parsed.day}/${parsed.year}';
}

String formatSavedAt(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year}, '
      '$hour12:$minute $period';
}

String displayWhen(CollectionEntry entry) {
  if (entry.createdAt != null) return formatSavedAt(entry.createdAt!);
  if (entry.entryDate.isNotEmpty) return formatEntryDate(entry.entryDate);
  return '—';
}

String effectiveDate(CollectionEntry entry) {
  if (entry.entryDate.isNotEmpty) return entry.entryDate;
  final created = entry.createdAt;
  if (created == null) return '';
  return isoDate(created.toLocal());
}

ReportBuild buildReport(
  List<CollectionEntry> entries, {
  required String from,
  required String to,
}) {
  if (from.isEmpty || to.isEmpty) {
    return const ReportBuild.fail(exportDatesRequiredMessage);
  }
  if (from.compareTo(to) > 0) return const ReportBuild.fail(dateOrderMessage);
  final filtered = entries
      .where((entry) {
        final date = effectiveDate(entry);
        if (date.isEmpty) return false;
        return date.compareTo(from) >= 0 && date.compareTo(to) <= 0;
      })
      .toList(growable: false);
  if (filtered.isEmpty) return const ReportBuild.fail(emptyRangeMessage);
  return ReportBuild.ok(entries: filtered, from: from, to: to);
}

String toCsv(List<CollectionEntry> entries) {
  final lines = <List<String>>[
    csvHeader,
    for (final entry in entries)
      [
        entry.createdAt == null ? '' : entry.createdAt!.toUtc().toIso8601String(),
        entry.phone,
        entry.bankType,
        entry.memberStatus,
        entry.productType,
        entry.channelType,
        entry.channelDetail,
      ],
  ];
  final body = lines.map(_csvRow).join('\r\n');
  return '\uFEFF$body';
}

String _csvRow(List<String> cells) {
  return cells.map((value) => '"${value.replaceAll('"', '""')}"').join(',');
}

List<List<String>> parseCsv(String source) {
  var text = source;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final rows = <List<String>>[];
  final row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;

  void finishField() {
    row.add(field.toString());
    field.clear();
    fieldStarted = false;
  }

  void finishRow() {
    finishField();
    if (row.length == 1 && row.first.isEmpty) {
      row.clear();
      return;
    }
    rows.add(List<String>.of(row));
    row.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      fieldStarted = true;
      continue;
    }
    if (char == '"') {
      inQuotes = true;
      fieldStarted = true;
    } else if (char == ',') {
      finishField();
    } else if (char == '\n') {
      finishRow();
    } else if (char != '\r') {
      field.write(char);
      fieldStarted = true;
    }
  }
  if (fieldStarted || row.isNotEmpty) finishRow();
  return rows;
}

CsvMergeResult mergeCsv(List<CollectionEntry> existing, String source) {
  final List<List<String>> rows;
  try {
    rows = parseCsv(source);
  } catch (_) {
    return CsvMergeResult(
      entries: existing,
      imported: 0,
      skippedDuplicates: 0,
      skippedInvalid: 0,
      error: invalidCsvMessage,
    );
  }
  if (rows.isEmpty) {
    return CsvMergeResult(
      entries: existing,
      imported: 0,
      skippedDuplicates: 0,
      skippedInvalid: 0,
      error: invalidCsvMessage,
    );
  }

  var data = rows;
  var layout = _CsvLayout.registration;
  final first = rows.first.map((cell) => cell.trim()).toList();
  if (_sameHeader(first, csvHeader)) {
    data = rows.skip(1).toList();
  } else if (_sameHeader(first, legacyPlaceCsvHeader)) {
    layout = _CsvLayout.place;
    data = rows.skip(1).toList();
  } else if (_sameHeader(first, legacyCsvHeader)) {
    layout = _CsvLayout.legacy;
    data = rows.skip(1).toList();
  }

  final seen = {for (final entry in existing) duplicateKey(entry)};
  final merged = List<CollectionEntry>.of(existing);
  var imported = 0;
  var duplicates = 0;
  var invalid = 0;

  for (final row in data) {
    if (row.every((cell) => cell.trim().isEmpty)) continue;
    final entry = _entryFromCsvRow(row, layout: layout);
    if (entry == null) {
      invalid++;
      continue;
    }
    final key = duplicateKey(entry);
    if (seen.contains(key)) {
      duplicates++;
      continue;
    }
    seen.add(key);
    merged.add(entry);
    imported++;
  }

  return CsvMergeResult(
    entries: merged,
    imported: imported,
    skippedDuplicates: duplicates,
    skippedInvalid: invalid,
    error: null,
  );
}

enum _CsvLayout { registration, legacy, place }

bool _sameHeader(List<String> row, List<String> header) {
  if (row.length < header.length) return false;
  for (var index = 0; index < header.length; index++) {
    if (row[index] != header[index]) return false;
  }
  return true;
}

CollectionEntry? _entryFromCsvRow(
  List<String> row, {
  required _CsvLayout layout,
}) {
  if (layout == _CsvLayout.registration ||
      (layout == _CsvLayout.registration && row.length >= csvHeader.length)) {
    if (row.length < csvHeader.length) return null;
    return CollectionEntry.tryImport({
      'timestamp': row[0].trim(),
      'phoneNumber': row[1].trim(),
      'bankType': row[2].trim(),
      'memberStatus': row[3].trim(),
      'productType': row[4].trim(),
      'channelType': row[5].trim(),
      'channelDetail': row[6].trim(),
    });
  }
  return _legacyCsvEntry(row, withPlace: layout == _CsvLayout.place);
}

CollectionEntry? _legacyCsvEntry(List<String> row, {required bool withPlace}) {
  if (row.length < 3) return null;
  final phone = row[0].trim();
  final bank = row[1].trim();
  if (phone.isEmpty || bank.isEmpty || bank.length > 80) return null;

  if (!withPlace) {
    final categoryCell = row[2].trim();
    if (SoloCategory.byId(categoryCell) == null &&
        SoloCategory.byName(categoryCell) == null) {
      return null;
    }
    return CollectionEntry.tryImport({
      'phone': phone,
      'bank': bank,
      'category': categoryCell,
      'entryDate': row.length > 3 ? row[3].trim() : '',
      'createdAt': row.length > 4 ? row[4].trim() : '',
    });
  }

  if (row.length < 5) return null;
  final kind = row[3].trim();
  final categoryCell = row[4].trim();
  if (SoloCategory.byId(categoryCell) == null &&
      SoloCategory.byName(categoryCell) == null) {
    return null;
  }
  return CollectionEntry.tryImport({
    'phone': phone,
    'bank': bank,
    'place': row[2].trim(),
    'organizationKind': kind,
    'category': categoryCell,
    'entryDate': row.length > 5 ? row[5].trim() : '',
    'createdAt': row.length > 6 ? row[6].trim() : '',
  });
}

String duplicateKey(CollectionEntry entry) {
  final stamp =
      entry.createdAt?.toUtc().toIso8601String() ?? entry.entryDate;
  return '${entry.phone}\u0000${entry.bankType}\u0000${entry.memberStatus}\u0000'
      '${entry.productType}\u0000${entry.channelType}\u0000${entry.channelDetail}\u0000'
      '$stamp';
}

String encodeBackup(List<CollectionEntry> entries) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(entries.map((entry) => entry.toJson()).toList());
}

String jsonBackupFilename(DateTime now) {
  return 'HNB_Solo_Report_${isoDate(now.toLocal())}.json';
}

List<CollectionEntry>? parseBackup(String source) {
  final dynamic data;
  try {
    data = jsonDecode(source);
  } catch (_) {
    return null;
  }
  if (data is! List) return null;
  return [for (final item in data) ?CollectionEntry.tryImport(item)];
}

List<CollectionEntry> decodeStored(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return [];
    return [for (final item in data) ?CollectionEntry.fromLoose(item)];
  } catch (_) {
    return [];
  }
}
