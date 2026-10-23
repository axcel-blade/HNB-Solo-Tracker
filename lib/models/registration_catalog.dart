class BankTypes {
  const BankTypes._();

  static const hnb = 'HNB';
  static const other = 'Other Bank';
}

class MemberStatuses {
  const MemberStatuses._();

  static const oldActive = 'Old Active Member';
  static const newActive = 'New Active Member';
  static const card = 'Credit/Debit Card';
  static const account = 'Bank Account';
}

class ProductTypes {
  const ProductTypes._();

  static const soloMax = 'SOLO MAX';
  static const hnbAcc = 'HNB ACC';
  static const external = 'External App';
}

class ChannelTypes {
  const ChannelTypes._();

  static const branch = 'Branch';
  static const department = 'Department';
  static const ownVisit = 'Own Visit';
}

const hnbDepartments = [
  'Cards & Electronic Banking',
  'Digital Banking Solutions',
  'Personal Banking Division',
  'IT & Systems Infrastructure',
  'Marketing & Sales',
  'Customer Experience & Operations',
  'Credit Operations & Risk Management',
  'Compliance & Legal Affairs',
  'Finance & Accounts',
  'Human Resources Division',
];

const namedHnbBranches = [
  'HNB Negombo Main Branch',
  'HNB Negombo Metro Branch',
  'HNB Negombo City Branch',
  'HNB Tower - Main Branch (Colombo 10)',
  'Aluthgama',
  'Ambalangoda',
  'Ampitiya',
  'Anuradhapura',
  'Avissawella',
  'Badulla',
  'Balangoda',
  'Bandarawela',
  'Batticaloa',
  'Beruwala',
  'Biyagama',
  'Borella',
  'Chilaw',
  'Colombo - City Office',
  'Colombo - Cinnamon Gardens',
  'Colombo - Fort',
  'Colombo - Grandpass',
  'Colombo - Kollupitiya',
  'Colombo - Maradana',
  'Colombo - Narahenpita',
  'Colombo - Nugegoda',
  'Colombo - Pettah',
  'Colombo - Pettah Metro',
  'Colombo - Wellawatte',
  'Dambulla',
  'Dehiwala',
  'Embilipitiya',
  'Galle - Main',
  'Galle - Fort',
  'Gampaha - Main',
  'Gampaha - City',
  'Gampola',
  'Horana',
  'Ja-Ela',
  'Jaffna - Main',
  'Jaffna - Metro',
  'Kadawatha',
  'Kaduwela',
  'Kalutara',
  'Kandy - Main',
  'Kandy City Centre',
  'Katunayake',
  'Kegalle',
  'Kilinochchi',
  'Kiribathgoda',
  'Kottawa',
  'Kurunegala - Main',
  'Kurunegala - Metro',
  'Maharagama',
  'Mannar',
  'Matara - Main',
  'Matara - Metro',
  'Matugama',
  'Mawanella',
  'Minuwangoda',
  'Monaragala',
  'Moratuwa',
  'Mount Lavinia',
  'Nawalapitiya',
  'Nittambuwa',
  'Nuwara Eliya',
  'Panadura',
  'Peliyagoda',
  'Polonnaruwa',
  'Puttalam',
  'Ratnapura',
  'Thalawathugoda',
  'Trincomalee',
  'Vavuniya',
  'Wattala',
  'Welimada',
  'Wennappuwa',
];

const branchListSize = 256;

List<String> allHnbBranches() {
  final extra = branchListSize - namedHnbBranches.length;
  return [
    ...namedHnbBranches,
    for (var index = 1; index <= extra; index++) 'HNB Branch Ref #${100 + index}',
  ];
}
