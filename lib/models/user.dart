class User {
  final String id;
  final String name;
  final String email;
  final String timeZoneId;
  final String languageId;
  final String countryId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.timeZoneId,
    required this.languageId,
    required this.countryId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      timeZoneId: json['time_zone_id'] as String,
      languageId: json['language_id'] as String,
      countryId: json['country_id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'time_zone_id': timeZoneId,
      'language_id': languageId,
      'country_id': countryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
