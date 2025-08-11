// lib/data/models/user_model.dart

class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String numberAccount;
  final String? avatarUrl;
  final bool? hasNumberAccount;
  final DateTime? lastLogin;
  final String? phone;
  final int? maxLimitExpense;
  final String? role;
  final bool? isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.numberAccount,
    this.avatarUrl,
    this.hasNumberAccount,
    this.lastLogin,
    this.phone,
    this.maxLimitExpense,
    this.role,
    this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle avatar_url which can be either a string or an object
    String? parseAvatarUrl(dynamic avatarData) {
      if (avatarData == null) return null;
      if (avatarData is String) return avatarData;
      if (avatarData is Map) return avatarData['url'] as String?;
      return null;
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      numberAccount: json['numberAccount']?.toString() ?? '',
      avatarUrl: parseAvatarUrl(json['avatar_url']),
      hasNumberAccount: json['hasNumberAccount'] as bool?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      phone: json['phone']?.toString(),
      maxLimitExpense: json['max_limit_expense'] != null
          ? int.tryParse(json['max_limit_expense'].toString())
          : null,
      role: json['role']?.toString(),
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'numberAccount': numberAccount,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (hasNumberAccount != null) 'hasNumberAccount': hasNumberAccount,
        if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
        if (phone != null) 'phone': phone,
        if (maxLimitExpense != null) 'max_limit_expense': maxLimitExpense,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
      };
}
