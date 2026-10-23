import 'dart:convert';

import '../models/catalog.dart';
import '../models/collection_entry.dart';

enum PhoneCheck { empty, tooShort, ok }

const saveFailedMessage =
    'Could not save: browser storage may be full or disabled. Export a backup.';
const phoneTooShortMessage = 'Please check the phone number and try again.';
const dateOrderMessage = 'The start date must be before the end date.';
const emptyRangeMessage = 'No entries found in the selected date range.';
const invalidJsonMessage = 'Could not import. Choose a valid JSON backup file.';
const invalidCsvMessage = 'Could not import. Choose a valid CSV file.';

const csvHeader = [
  'Phone number',
  'Bank',
  'Place',
  'Kind',
  'Category',
  'Entry date',
  'Saved date and time',
];

const legacyCsvHeader = [
  'Phone number',
  'Bank',
  'Category',
  'Entry date',
  'Saved date and time',
];

class CategoryCounts {
  const CategoryCounts({
    required this.max,
    required this.card,
    required this.bank,
    required this.hnbAcc,
  });

  final int max;
  final int card;
  final int bank;
  final int hnbAcc;

  int get total => max + card + bank + hnbAcc;
}

class ExportBuild {
  const ExportBuild._({
    required this.error,
    required this.csv,
    required this.filename,
    required this.count,
  });

  const ExportBuild.fail(String message)
    : this._(error: message, csv: null, filename: null, count: 0);

  const ExportBuild.ok({
    required String csv,
    required String filename,
    required int count,
  }) : this._(error: null, csv: csv, filename: filename, count: count);

  final String? error;
  final String? csv;
  final String? filename;
  final int count;
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

PhoneCheck checkPhone(String raw) {
  final phone = raw.trim();
  if (phone.isEmpty) return PhoneCheck.empty;
  if (phone.length < 7) return PhoneCheck.tooShort;
  return PhoneCheck.ok;
}

CategoryCounts countEntries(List<CollectionEntry> entries) {
  var max = 0;
  var card = 0;
  var bank = 0;
  var hnbAcc = 0;
  for (final entry in entries) {
    switch (entry.category) {
      case 'max':
        max++;
      case 'card':
        card++;
      case 'bank':
        bank++;
      case 'hnbacc':
        hnbAcc++;
    }
  }
  return CategoryCounts(max: max, card: card, bank: bank, hnbAcc: hnbAcc);
}

List<CollectionEntry> newestFirst(List<CollectionEntry> entries) {
  return entries.reversed.toList(growable: false);
}

String effectiveDate(CollectionEntry entry) {
  if (entry.entryDate.isNotEmpty) return entry.entryDate;
  final created = entry.createdAt;
  if (created == null) return '';
  final iso = created.toUtc().toIso8601String();
  return iso.length >= 10 ? iso.substring(0, 10) : '';
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
  final second = local.second.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year}, '
      '$hour12:$minute:$second $period';
}

String displayWhen(CollectionEntry entry) {
  if (entry.entryDate.isNotEmpty) {
    final parsed = DateTime.tryParse('${entry.entryDate}T12:00:00');
    if (parsed != null) return formatEntryDate(entry.entryDate);
  }
  if (entry.createdAt != null) return formatSavedAt(entry.createdAt!);
  return '—';
}

ExportBuild buildExport(
  List<CollectionEntry> entries, {
  required String from,
  required String to,
}) {
  if (from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0) {
    return const ExportBuild.fail(dateOrderMessage);
  }
  final filtered = entries
      .where((entry) {
        final date = effectiveDate(entry);
        if (from.isNotEmpty && date.compareTo(from) < 0) return false;
        if (to.isNotEmpty && date.compareTo(to) > 0) return false;
        return true;
      })
      .toList(growable: false);
  if (filtered.isEmpty) return const ExportBuild.fail(emptyRangeMessage);
  final start = from.isEmpty ? 'all' : from;
  final end = to.isEmpty ? 'all' : to;
  return ExportBuild.ok(
    csv: toCsv(filtered),
    filename: 'solo-collection-$start-to-$end.csv',
    count: filtered.length,
  );
}

String toCsv(List<CollectionEntry> entries) {
  final lines = <List<String>>[
    csvHeader,
    for (final entry in entries)
      [
        entry.phone,
        entry.bank,
        entry.place,
        entry.organizationKind,
        SoloCategory.labelFor(entry.category),
        entry.entryDate,
        entry.createdAt == null ? '' : formatSavedAt(entry.createdAt!),
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
  var legacy = false;
  final first = rows.first.map((cell) => cell.trim()).toList();
  if (_sameHeader(first, csvHeader)) {
    data = rows.skip(1).toList();
  } else if (_sameHeader(first, legacyCsvHeader)) {
    legacy = true;
    data = rows.skip(1).toList();
  }

  final seen = {for (final entry in existing) duplicateKey(entry)};
  final merged = List<CollectionEntry>.of(existing);
  var imported = 0;
  var duplicates = 0;
  var invalid = 0;

  for (final row in data) {
    if (row.every((cell) => cell.trim().isEmpty)) continue;
    final entry = _entryFromCsvRow(row, legacy: legacy);
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

bool _sameHeader(List<String> row, List<String> header) {
  if (row.length < header.length) return false;
  for (var index = 0; index < header.length; index++) {
    if (row[index] != header[index]) return false;
  }
  return true;
}

bool _isCategory(String value) {
  return SoloCategory.byId(value) != null || SoloCategory.byName(value) != null;
}

CollectionEntry? _entryFromCsvRow(List<String> row, {required bool legacy}) {
  if (row.length < 3) return null;
  final phone = row[0].trim();
  final bank = row[1].trim();
  if (phone.isEmpty || bank.isEmpty || bank.length > 80) return null;

  final categoryAtTwo = _isCategory(row[2].trim());
  final useLegacy = legacy || (categoryAtTwo && row.length < 6);
  if (useLegacy) {
    if (!categoryAtTwo) return null;
    return _entryFromCells(
      phone: phone,
      bank: bank,
      place: '',
      kind: '',
      categoryCell: row[2].trim(),
      entryDate: row.length > 3 ? row[3].trim() : '',
      savedAt: row.length > 4 ? row[4].trim() : '',
    );
  }

  if (row.length < 5 || !_isCategory(row[4].trim())) return null;
  final kind = row[3].trim();
  if (kind == 'hnb' && bank != 'HNB') return null;
  if ((kind == 'bank' || kind == 'company') && bank == 'HNB') return null;
  if (kind.isNotEmpty && kind != 'hnb' && kind != 'bank' && kind != 'company') {
    return null;
  }
  return _entryFromCells(
    phone: phone,
    bank: bank,
    place: row[2].trim(),
    kind: kind,
    categoryCell: row[4].trim(),
    entryDate: row.length > 5 ? row[5].trim() : '',
    savedAt: row.length > 6 ? row[6].trim() : '',
  );
}

CollectionEntry? _entryFromCells({
  required String phone,
  required String bank,
  required String place,
  required String kind,
  required String categoryCell,
  required String entryDate,
  required String savedAt,
}) {
  final category =
      SoloCategory.byId(categoryCell) ?? SoloCategory.byName(categoryCell);
  if (category == null) return null;
  if (entryDate.isNotEmpty &&
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entryDate)) {
    return null;
  }
  return CollectionEntry(
    id: newEntryId(),
    phone: phone,
    bank: bank,
    category: category.id,
    entryDate: entryDate,
    createdAt: savedAt.isEmpty ? null : DateTime.tryParse(savedAt),
    place: place,
    organizationKind: kind,
  );
}

String duplicateKey(CollectionEntry entry) {
  return '${entry.phone}\u0000${entry.bank}\u0000${entry.place}\u0000'
      '${entry.category}\u0000${entry.entryDate}';
}

String encodeBackup(List<CollectionEntry> entries) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(entries.map((entry) => entry.toJson()).toList());
}

String jsonBackupFilename(DateTime now) {
  return 'solo-collection-backup-${isoDate(now.toUtc())}.json';
}

/// Returns null when the file is not a JSON array.
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
