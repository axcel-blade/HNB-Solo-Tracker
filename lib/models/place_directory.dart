import 'place.dart';

/// Starter directory. HNB branches are the only places recorded as HNB.
/// Other banks and companies are separate, and custom places can be added.
final List<CollectionPlace> builtInPlaces = [
  for (final name in hnbBranchNames)
    CollectionPlace(
      kind: OrganizationKind.hnb,
      organization: 'HNB',
      name: name,
      builtIn: true,
    ),
  for (final name in otherBankNames)
    CollectionPlace(
      kind: OrganizationKind.bank,
      organization: name,
      name: 'Head office',
      builtIn: true,
    ),
  for (final name in otherCompanyNames)
    CollectionPlace(
      kind: OrganizationKind.company,
      organization: name,
      name: 'Head office',
      builtIn: true,
    ),
];

const hnbBranchNames = [
  'Head Office',
  'Ampara',
  'Anuradhapura',
  'Avissawella',
  'Badulla',
  'Bambalapitiya',
  'Bandarawela',
  'Batticaloa',
  'Chilaw',
  'Colombo Fort',
  'Dambulla',
  'Dehiwala',
  'Galle',
  'Gampaha',
  'Hambantota',
  'Hatton',
  'Homagama',
  'Jaffna',
  'Kaduwela',
  'Kalutara',
  'Kandy',
  'Katugastota',
  'Kegalle',
  'Kiribathgoda',
  'Kollupitiya',
  'Kurunegala',
  'Maharagama',
  'Matale',
  'Matara',
  'Moratuwa',
  'Mount Lavinia',
  'Negombo',
  'Nugegoda',
  'Nuwara Eliya',
  'Panadura',
  'Pettah',
  'Polonnaruwa',
  'Puttalam',
  'Ratnapura',
  'Trincomalee',
  'Vavuniya',
  'Wattala',
  'Wellawatte',
];

const otherBankNames = [
  'Amana Bank',
  'Bank of Ceylon',
  'Cargills Bank',
  'Commercial Bank',
  'DFCC Bank',
  'HSBC',
  'NDB Bank',
  'National Savings Bank',
  'Nations Trust Bank',
  'Pan Asia Bank',
  "People's Bank",
  'Regional Development Bank',
  'Sampath Bank',
  'Seylan Bank',
  'Standard Chartered',
  'Union Bank',
];

const otherCompanyNames = [
  'Central Finance',
  'Commercial Credit',
  'Dialog Finance',
  'LB Finance',
  'LOLC Finance',
  "People's Leasing",
  'Singer Finance',
  'Softlogic Finance',
];
