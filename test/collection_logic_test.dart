import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/logic/collection_logic.dart';
import 'package:hnb_solo_tracker/models/collection_entry.dart';

CollectionEntry entry({
  String id = '1',
  String phone = '0771234567',
  String bank = 'HNB',
  String category = 'max',
  String entryDate = '2026-10-01',
  DateTime? createdAt,
}) {
  return CollectionEntry(
    id: id,
    phone: phone,
    bank: bank,
    category: category,
    entryDate: entryDate,
    createdAt: createdAt ?? DateTime.utc(2026, 10, 1, 8),
  );
}

void main() {
  test('counts only known categories and sums the grand total', () {
    final counts = countEntries([
      entry(category: 'max'),
      entry(id: '2', category: 'max'),
      entry(id: '3', category: 'card'),
      entry(id: '4', category: 'bank'),
      entry(id: '5', category: 'hnbacc'),
      entry(id: '6', category: 'unknown'),
    ]);
    expect(counts.max, 2);
    expect(counts.card, 1);
    expect(counts.bank, 1);
    expect(counts.hnbAcc, 1);
    expect(counts.total, 5);
  });

  test('phone check trims and requires at least 7 characters', () {
    expect(checkPhone('   '), PhoneCheck.empty);
    expect(checkPhone('123456'), PhoneCheck.tooShort);
    expect(checkPhone('  0771234567  '), PhoneCheck.ok);
  });

  test('export range is inclusive and rejects an inverted range', () {
    final entries = [
      entry(entryDate: '2026-10-01'),
      entry(id: '2', entryDate: '2026-10-15', phone: '0770000000'),
      entry(id: '3', entryDate: '2026-10-31', phone: '0771111111'),
    ];
    final inverted = buildExport(entries, from: '2026-10-20', to: '2026-10-01');
    expect(inverted.error, dateOrderMessage);

    final ranged = buildExport(entries, from: '2026-10-15', to: '2026-10-31');
    expect(ranged.error, isNull);
    expect(ranged.count, 2);
    expect(ranged.filename, 'solo-collection-2026-10-15-to-2026-10-31.csv');
    expect(ranged.csv, contains('0770000000'));
    expect(ranged.csv, isNot(contains('0771234567')));

    final all = buildExport(entries, from: '', to: '');
    expect(all.count, 3);
    expect(all.filename, 'solo-collection-all-to-all.csv');
    expect(all.csv!.startsWith('\uFEFF'), isTrue);
  });

  test('csv keeps quotes, commas, and skips matching duplicates', () {
    final original = entry(phone: '077"123,4567');
    final csv = toCsv([original]);
    expect(csv, contains('"077""123,4567"'));

    final merged = mergeCsv([original], csv);
    expect(merged.imported, 0);
    expect(merged.skippedDuplicates, 1);
    expect(merged.entries, hasLength(1));

    final fresh = mergeCsv(const [], csv);
    expect(fresh.imported, 1);
    expect(fresh.entries.single.phone, '077"123,4567');
    expect(fresh.entries.single.category, 'max');
    expect(fresh.entries.single.bank, 'HNB');
    expect(fresh.entries.single.entryDate, '2026-10-01');
  });

  test('csv import keeps existing rows and drops invalid ones', () {
    const csv = 'Phone number,Bank,Category,Entry date,Saved date and time\r\n'
        '"0710000000","Other Bank","Credit/Debit","2026-09-01",""\r\n'
        '"bad","Nope","Solo Max","2026-09-01",""\r\n'
        '"0710000000","Other Bank","Credit/Debit","2026-09-01",""\r\n';
    final existing = [entry()];
    final result = mergeCsv(existing, csv);
    expect(result.imported, 1);
    expect(result.skippedDuplicates, 1);
    expect(result.skippedInvalid, 1);
    expect(result.entries, hasLength(2));
    expect(result.entries.last.category, 'card');
    expect(result.entries.last.bank, 'Other Bank');
    expect(result.message, contains('Imported 1'));
  });

  test('json backup replaces with valid rows only', () {
    final raw = '''
    [
      {"phone":"0771234567","bank":"HNB","category":"hnbacc","entryDate":"2026-10-02","createdAt":"2026-10-02T01:02:03.000Z"},
      {"phone":1,"bank":"HNB","category":"max"},
      {"phone":"0770000000","bank":"Commercial","category":"max"}
    ]
    ''';
    final parsed = parseBackup(raw);
    expect(parsed, isNotNull);
    expect(parsed, hasLength(1));
    expect(parsed!.single.category, 'hnbacc');
    expect(parsed.single.entryDate, '2026-10-02');
    expect(parseBackup('{"phone":"x"}'), isNull);
    expect(parseBackup('not json'), isNull);
  });

  test('newest entries are listed first without changing storage order', () {
    final stored = [entry(id: 'old'), entry(id: 'new')];
    expect(newestFirst(stored).map((item) => item.id), ['new', 'old']);
    expect(stored.map((item) => item.id), ['old', 'new']);
  });
}
