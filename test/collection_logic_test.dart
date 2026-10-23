import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/logic/collection_logic.dart';
import 'package:hnb_solo_tracker/models/collection_entry.dart';
import 'package:hnb_solo_tracker/models/registration_catalog.dart';

CollectionEntry entry({
  String id = '1',
  String phone = '0771234567',
  String bankType = BankTypes.hnb,
  String memberStatus = MemberStatuses.oldActive,
  String productType = ProductTypes.soloMax,
  String channelType = ChannelTypes.branch,
  String channelDetail = 'Kandy - Main',
  String entryDate = '2026-10-01',
  DateTime? createdAt,
}) {
  return CollectionEntry(
    id: id,
    phone: phone,
    bankType: bankType,
    memberStatus: memberStatus,
    productType: productType,
    channelType: channelType,
    channelDetail: channelDetail,
    entryDate: entryDate,
    createdAt: createdAt ?? DateTime.utc(2026, 10, 1, 8),
  );
}

void main() {
  test('registration stats count bank type and channel', () {
    final stats = registrationStats([
      entry(),
      entry(id: '2', bankType: BankTypes.other, memberStatus: MemberStatuses.card, productType: ProductTypes.external),
      entry(id: '3', channelType: ChannelTypes.department, channelDetail: 'HNB Tower - Marketing & Sales'),
      entry(id: '4', channelType: ChannelTypes.ownVisit, channelDetail: 'Direct Own Visit'),
    ]);
    expect(stats.total, 4);
    expect(stats.hnb, 3);
    expect(stats.other, 1);
    expect(stats.branches, 2);
    expect(stats.departments, 1);
    expect(stats.ownVisits, 1);
    expect(stats.hnbPercent, '75.0');
  });

  test('a reference can be a phone number or a short ref', () {
    expect(registrationError(const RegistrationInput(
      phone: '   ',
      bankType: BankTypes.hnb,
      hnbMemberStatus: MemberStatuses.oldActive,
      hnbProduct: ProductTypes.soloMax,
      otherSource: MemberStatuses.card,
      channelType: ChannelTypes.branch,
      branch: 'Kandy',
      department: 'Marketing & Sales',
      ownVisit: '',
    )), referenceRequiredMessage);
    final saved = registrationFrom(
      const RegistrationInput(
        phone: ' Ref #1029 ',
        bankType: BankTypes.other,
        hnbMemberStatus: MemberStatuses.oldActive,
        hnbProduct: ProductTypes.soloMax,
        otherSource: MemberStatuses.account,
        channelType: ChannelTypes.department,
        branch: 'Kandy',
        department: 'Marketing & Sales',
        ownVisit: '   ',
      ),
      createdAt: DateTime.utc(2026, 10, 2, 1),
    );
    expect(saved.phone, 'Ref #1029');
    expect(saved.bankType, BankTypes.other);
    expect(saved.productType, ProductTypes.external);
    expect(saved.memberStatus, MemberStatuses.account);
    expect(saved.channelDetail, 'HNB Tower - Marketing & Sales');
    final visit = registrationFrom(
      const RegistrationInput(
        phone: '0771234567',
        bankType: BankTypes.hnb,
        hnbMemberStatus: MemberStatuses.newActive,
        hnbProduct: ProductTypes.hnbAcc,
        otherSource: MemberStatuses.card,
        channelType: ChannelTypes.ownVisit,
        branch: 'Kandy',
        department: 'Marketing & Sales',
        ownVisit: '',
      ),
    );
    expect(visit.channelDetail, 'Direct Own Visit');
    expect(visit.productType, ProductTypes.hnbAcc);
    expect(allHnbBranches(), hasLength(256));
    expect(allHnbBranches().first, 'HNB Negombo Main Branch');
  });

  test('export range is inclusive and requires both dates', () {
    final entries = [
      entry(entryDate: '2026-10-01'),
      entry(id: '2', entryDate: '2026-10-15', phone: '0770000000'),
      entry(id: '3', entryDate: '2026-10-31', phone: '0771111111'),
    ];
    expect(
      buildReport(entries, from: '', to: '').error,
      exportDatesRequiredMessage,
    );
    expect(
      buildReport(entries, from: '2026-10-20', to: '2026-10-01').error,
      dateOrderMessage,
    );

    final ranged = buildReport(entries, from: '2026-10-15', to: '2026-10-31');
    expect(ranged.error, isNull);
    expect(ranged.count, 2);
    expect(ranged.filename('csv'), 'HNB_Solo_Report_2026-10-15_to_2026-10-31.csv');
    expect(ranged.csv, contains('0770000000'));
    expect(ranged.csv, isNot(contains('0771234567')));
    expect(ranged.json, contains('0771111111'));
  });

  test('csv keeps quotes and skips matching duplicates', () {
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
    expect(fresh.entries.single.productType, ProductTypes.soloMax);
    expect(fresh.entries.single.bankType, BankTypes.hnb);
    expect(fresh.entries.single.channelDetail, 'Kandy - Main');
  });

  test('legacy csv import maps old categories and drops invalid rows', () {
    const csv =
        'Phone number,Bank,Category,Entry date,Saved date and time\r\n'
        '"0710000000","Other Bank","Credit/Debit","2026-09-01",""\r\n'
        '"0712222222","Commercial Bank","Solo Max","2026-09-02",""\r\n'
        '"","HNB","Solo Max","2026-09-01",""\r\n'
        '"0713333333","HNB","Not a category","2026-09-01",""\r\n'
        '"0710000000","Other Bank","Credit/Debit","2026-09-01",""\r\n';
    final existing = [entry()];
    final result = mergeCsv(existing, csv);
    expect(result.imported, 2);
    expect(result.skippedDuplicates, 1);
    expect(result.skippedInvalid, 2);
    expect(result.entries, hasLength(3));
    expect(result.entries[1].memberStatus, MemberStatuses.card);
    expect(result.entries[1].bankType, BankTypes.other);
    expect(result.entries[1].productType, ProductTypes.external);
    expect(result.entries[2].channelDetail, 'Commercial Bank');
    expect(result.message, contains('Imported 2'));
  });

  test('legacy place csv keeps the branch and rejects a mismatched kind', () {
    final original = entry(
      phone: '0771234567',
      channelType: ChannelTypes.branch,
      channelDetail: 'Kandy',
    );
    final csv = toCsv([original]);
    final merged = mergeCsv(const [], csv);
    expect(merged.imported, 1);
    expect(merged.entries.single.channelDetail, 'Kandy');
    expect(merged.entries.single.bankType, BankTypes.hnb);

    const wrong =
        'Phone number,Bank,Place,Kind,Category,Entry date,Saved date and time\r\n'
        '"0770000000","Commercial Bank","Kandy","hnb","Solo Max","2026-10-01",""\r\n';
    final rejected = mergeCsv(const [], wrong);
    expect(rejected.imported, 0);
    expect(rejected.skippedInvalid, 1);
  });

  test('json backup keeps valid registration rows and maps older backups', () {
    final raw = '''
    [
      {"phoneNumber":"0771234567","bankType":"HNB","memberStatus":"New Active Member","productType":"HNB ACC","channelType":"Branch","channelDetail":"Kandy - Main","timestamp":"2026-10-02T01:02:03.000Z","entryDate":"2026-10-02"},
      {"phone":1,"bank":"HNB","category":"max"},
      {"phone":"0770000000","bank":"","category":"max"},
      {"phone":"0770000001","bank":"HNB","category":"max","organizationKind":"company"},
      {"phone":"0770000002","bank":"Commercial Bank","category":"max","place":"Kandy","organizationKind":"bank"}
    ]
    ''';
    final parsed = parseBackup(raw);
    expect(parsed, isNotNull);
    expect(parsed, hasLength(2));
    expect(parsed!.first.productType, ProductTypes.hnbAcc);
    expect(parsed.first.memberStatus, MemberStatuses.newActive);
    expect(parsed.first.entryDate, '2026-10-02');
    expect(parsed.last.bankType, BankTypes.other);
    expect(parsed.last.channelDetail, 'Kandy');
    expect(parsed.last.channelType, ChannelTypes.ownVisit);
    expect(parseBackup('{"phone":"x"}'), isNull);
    expect(parseBackup('not json'), isNull);
  });

  test('newest entries are listed first without changing storage order', () {
    final stored = [entry(id: 'old'), entry(id: 'new')];
    expect(newestFirst(stored).map((item) => item.id), ['new', 'old']);
    expect(stored.map((item) => item.id), ['old', 'new']);
    expect(filterRecords(stored, 'kandy').map((item) => item.id), ['new', 'old']);
    expect(filterRecords(stored, 'missing'), isEmpty);
  });
}
