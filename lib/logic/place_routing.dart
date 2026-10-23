import '../models/place.dart';

const hnbRouteMessage =
    'Only an HNB branch can be recorded as HNB. Other banks and companies stay with that organization.';
const placeNameMessage = 'Enter a name between 2 and 80 characters.';
const duplicatePlaceMessage = 'That place is already listed.';
const useHnbTabMessage =
    'Add HNB branches on the HNB branches tab. Only those are recorded as HNB.';

class RoutedRecord {
  const RoutedRecord({
    required this.bank,
    required this.place,
    required this.kind,
  });

  final String bank;
  final String place;
  final OrganizationKind kind;
}

/// Numbers collected at an HNB branch are recorded as HNB.
/// Every other bank or company keeps its own name.
RoutedRecord? routePlace(CollectionPlace place) {
  final organization = cleanPlaceName(place.organization);
  final name = cleanPlaceName(place.name);
  if (!_fits(organization) || !_fits(name)) return null;
  switch (place.kind) {
    case OrganizationKind.hnb:
      if (organization != 'HNB') return null;
      return RoutedRecord(bank: 'HNB', place: name, kind: OrganizationKind.hnb);
    case OrganizationKind.bank:
    case OrganizationKind.company:
      if (isHnbOrganization(organization)) return null;
      return RoutedRecord(bank: organization, place: name, kind: place.kind);
  }
}

bool _fits(String value) => value.length >= 2 && value.length <= 80;

List<CollectionPlace> placesFor(
  List<CollectionPlace> places,
  OrganizationKind kind, {
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final place in places)
      if (place.kind == kind &&
          (needle.isEmpty ||
              place.name.toLowerCase().contains(needle) ||
              place.organization.toLowerCase().contains(needle)))
        place,
  ];
}

String emptyPlaceMessage(
  OrganizationKind kind,
  List<CollectionPlace> places,
  String query,
) {
  final needle = query.trim().toLowerCase();
  final elsewhere =
      needle.isNotEmpty &&
      places.any(
        (place) =>
            place.kind != kind &&
            (place.name.toLowerCase().contains(needle) ||
                place.organization.toLowerCase().contains(needle)),
      );
  if (elsewhere && kind == OrganizationKind.hnb) {
    return 'No HNB branch matches. That name is listed under another bank or company, so those numbers are not recorded as HNB.';
  }
  if (elsewhere) {
    return 'Nothing in this list matches. Check the other tabs.';
  }
  return switch (kind) {
    OrganizationKind.hnb => 'No HNB branch matches.',
    OrganizationKind.bank => 'No other bank matches.',
    OrganizationKind.company =>
      'No company matches. Add one if you visited it.',
  };
}
