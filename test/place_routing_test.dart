import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/logic/place_routing.dart';
import 'package:hnb_solo_tracker/models/place.dart';
import 'package:hnb_solo_tracker/models/place_directory.dart';

void main() {
  test('only HNB branches are recorded as HNB', () {
    final hnb = routePlace(
      const CollectionPlace(
        kind: OrganizationKind.hnb,
        organization: 'HNB',
        name: 'Kandy',
      ),
    );
    expect(hnb!.bank, 'HNB');
    expect(hnb.place, 'Kandy');
    expect(hnb.kind, OrganizationKind.hnb);

    expect(
      routePlace(
        const CollectionPlace(
          kind: OrganizationKind.hnb,
          organization: 'Commercial Bank',
          name: 'Kandy',
        ),
      ),
      isNull,
    );

    final bank = routePlace(
      const CollectionPlace(
        kind: OrganizationKind.bank,
        organization: 'Commercial Bank',
        name: 'Kandy',
      ),
    );
    expect(bank!.bank, 'Commercial Bank');
    expect(bank.bank, isNot('HNB'));

    final company = routePlace(
      const CollectionPlace(
        kind: OrganizationKind.company,
        organization: 'LOLC Finance',
        name: 'Head office',
      ),
    );
    expect(company!.bank, 'LOLC Finance');
    expect(company.kind, OrganizationKind.company);

    expect(
      routePlace(
        const CollectionPlace(
          kind: OrganizationKind.company,
          organization: 'Hatton National Bank',
          name: 'Colombo',
        ),
      ),
      isNull,
    );
  });

  test('HNB search does not return other banks with the same branch name', () {
    final places = [
      ...builtInPlaces,
      const CollectionPlace(
        kind: OrganizationKind.bank,
        organization: 'Commercial Bank',
        name: 'Kandy',
      ),
    ];
    final hnb = placesFor(places, OrganizationKind.hnb, query: 'kandy');
    expect(hnb, hasLength(1));
    expect(hnb.single.organization, 'HNB');

    final banks = placesFor(places, OrganizationKind.bank, query: 'kandy');
    expect(banks.single.organization, 'Commercial Bank');
    expect(
      emptyPlaceMessage(OrganizationKind.hnb, places, 'zzz-not-a-branch'),
      'No HNB branch matches.',
    );
    expect(
      emptyPlaceMessage(OrganizationKind.hnb, places, 'Commercial'),
      contains('not recorded as HNB'),
    );
  });
}
