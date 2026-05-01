class Profile {
  final String id;
  final String name;
  final String email;
  final String urlName;
  final String status;
  final String type;
  final String? parentId;
  final String currencyId;
  final String countryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.urlName,
    required this.status,
    required this.type,
    this.parentId,
    required this.currencyId,
    required this.countryId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      urlName: json['url_name'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      parentId: json['parent_id'] as String?,
      currencyId: json['currency_id'] as String,
      countryId: json['country_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'url_name': urlName,
      'status': status,
      'type': type,
      'parent_id': parentId,
      'currency_id': currencyId,
      'country_id': countryId,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
