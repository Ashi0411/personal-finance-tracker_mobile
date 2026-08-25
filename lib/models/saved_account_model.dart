class SavedAccountModel {
  final int id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String currency;
  final String? userJson;
  final DateTime lastActive;

  SavedAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.currency = '\$',
    this.userJson,
    required this.lastActive,
  });

  factory SavedAccountModel.fromJson(Map<String, dynamic> json) {
    return SavedAccountModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      fullName: json['full_name'] ?? 'User',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      currency: json['currency'] ?? '\$',
      userJson: json['user_json'],
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'currency': currency,
      'user_json': userJson,
      'last_active': lastActive.toIso8601String(),
    };
  }

  SavedAccountModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? currency,
    String? userJson,
    DateTime? lastActive,
  }) {
    return SavedAccountModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currency: currency ?? this.currency,
      userJson: userJson ?? this.userJson,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
