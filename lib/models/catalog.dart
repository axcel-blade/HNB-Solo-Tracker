class SoloCategory {
  const SoloCategory(this.id, this.name);

  final String id;
  final String name;

  static const max = SoloCategory('max', 'Solo Max');
  static const card = SoloCategory('card', 'Credit/Debit');
  static const otherBankAcc = SoloCategory('bank', 'Other Bank acc');
  static const hnbAcc = SoloCategory('hnbacc', 'HNB ACC');

  static const all = [max, card, otherBankAcc, hnbAcc];

  static SoloCategory? byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }

  static SoloCategory? byName(String name) {
    for (final category in all) {
      if (category.name == name) return category;
    }
    return null;
  }

  static String labelFor(String id) => byId(id)?.name ?? id;
}
