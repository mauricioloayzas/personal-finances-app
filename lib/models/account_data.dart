class AccountData {
  final String name;
  final String description;
  final String code;
  final String nature;
  final String type;
  final bool isFinal;
  final num balance;
  final bool withInterest;
  final bool withInsurance;

  AccountData({
    required this.name,
    required this.description,
    required this.code,
    required this.nature,
    required this.type,
    required this.isFinal,
    required this.balance,
    required this.withInterest,
    required this.withInsurance,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'code': code,
      'nature': nature,
      'type': type,
      'final': isFinal,
      'balance': balance,
    };

    if (withInterest) {
      data['withInterest'] = withInterest;
    }

    if (withInsurance) {
      data['withInsurance'] = withInsurance;
    }

    return data;
  }
}
