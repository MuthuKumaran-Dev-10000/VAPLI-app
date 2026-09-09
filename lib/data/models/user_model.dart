class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final int roleRank; // 1: super admin, 2: admin, 3: user
  final String? phone;
  final String? email;
  final String? address;
  final Map<String, bool> privileges;
  final List<String> clientIds;
  final bool isActive;
  final String? lastLoginAt;
  final String createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.roleRank,
    this.phone,
    this.email,
    this.address,
    this.privileges = const {},
    this.clientIds = const [],
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final Map<String, bool> privs = {};
    if (json['privileges'] is Map) {
      (json['privileges'] as Map).forEach((key, val) {
        privs[key.toString()] = val == true;
      });
    }

    final List<String> clients = [];
    if (json['clientIds'] is List) {
      for (final item in json['clientIds'] as List) {
        if (item != null) clients.add(item.toString());
      }
    } else if (json['client_ids'] is List) {
      for (final item in json['client_ids'] as List) {
        if (item != null) clients.add(item.toString());
      }
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      role: (json['role']?.toString() ?? 'user').trim().toLowerCase(),
      roleRank: json['roleRank'] is int
          ? json['roleRank']
          : json['role_rank'] is int
              ? json['role_rank']
              : (json['role']?.toString().trim().toLowerCase() == 'super admin'
                  ? 1
                  : json['role']?.toString().trim().toLowerCase() == 'admin'
                      ? 2
                      : 3),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      privileges: privs,
      clientIds: clients,
      isActive: json['isActive'] != false && json['is_active'] != false,
      lastLoginAt: json['lastLoginAt']?.toString() ?? json['last_login_at']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'role': role,
        'roleRank': roleRank,
        'phone': phone,
        'email': email,
        'address': address,
        'privileges': privileges,
        'clientIds': clientIds,
        'isActive': isActive,
        'lastLoginAt': lastLoginAt,
        'createdAt': createdAt,
      };
}
