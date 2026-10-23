enum OrganizationKind {
  hnb('hnb', 'HNB branches'),
  bank('bank', 'Other banks'),
  company('company', 'Other companies');

  const OrganizationKind(this.id, this.label);

  final String id;
  final String label;

  static OrganizationKind? byId(String id) {
    for (final kind in OrganizationKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// A branch or office where phone numbers are collected.
class CollectionPlace {
  const CollectionPlace({
    this.id,
    required this.kind,
    required this.organization,
    required this.name,
    this.builtIn = false,
  });

  final int? id;
  final OrganizationKind kind;
  final String organization;
  final String name;
  final bool builtIn;

  String get identity => placeIdentity(kind, organization, name);

  /// Short label in the HNB list. Other lists include the organization.
  String get pickerTitle =>
      kind == OrganizationKind.hnb ? name : '$organization · $name';

  String get headline =>
      kind == OrganizationKind.hnb ? 'HNB · $name' : '$organization · $name';

  String get recordedAs => kind == OrganizationKind.hnb ? 'HNB' : organization;
}

class PlaceResult {
  const PlaceResult._({this.place, this.error});

  const PlaceResult.ok(CollectionPlace place) : this._(place: place);

  const PlaceResult.fail(String message) : this._(error: message);

  final CollectionPlace? place;
  final String? error;
}

String cleanPlaceName(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

String placeIdentity(OrganizationKind kind, String organization, String name) {
  return '${kind.id}|${cleanPlaceName(organization).toLowerCase()}|'
      '${cleanPlaceName(name).toLowerCase()}';
}

bool isHnbOrganization(String value) {
  const names = {'hnb', 'hatton national bank'};
  return names.contains(cleanPlaceName(value).toLowerCase());
}
