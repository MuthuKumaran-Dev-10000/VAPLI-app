class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String passwordHash;
  final String role; // 'super admin' | 'admin' | 'user'
  final String? phone;
  final String? email;
  final Map<String, bool> privileges;
  final List<String> clientIds;
  final int failedLoginAttempts;
  final String? lockedUntil;
  final bool isActive;
  final String? lastLoginAt;
  final String createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.passwordHash,
    required this.role,
    this.phone,
    this.email,
    this.privileges = const {},
    this.clientIds = const [],
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
  });

  static bool _parseBool(dynamic val, {bool defaultValue = true}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return defaultValue;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'password_hash': passwordHash,
        'role': role,
        'phone': phone,
        'email': email,
        'privileges': privileges,
        'client_ids': clientIds,
        'failed_login_attempts': failedLoginAttempts,
        'locked_until': lockedUntil,
        'is_active': isActive,
        'last_login_at': lastLoginAt,
        'created_at': createdAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: (m['id'] ?? '').toString(),
        username: (m['username'] ?? '').toString(),
        fullName: (m['full_name'] ?? m['fullName'] ?? m['display_name'] ?? '').toString(),
        passwordHash: (m['password_hash'] ?? m['passwordHash'] ?? '').toString(),
        role: (m['role'] ?? 'user').toString(),
        phone: m['phone']?.toString(),
        email: m['email']?.toString(),
        privileges: ((m['privileges'] as Map?) ?? (m['privileges_json'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), _parseBool(v, defaultValue: false))),
        clientIds: ((m['client_ids'] as List?) ?? (m['client_ids_json'] as List?) ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        failedLoginAttempts: (m['failed_login_attempts'] is num)
            ? (m['failed_login_attempts'] as num).toInt()
            : int.tryParse(m['failed_login_attempts']?.toString() ?? '0') ?? 0,
        lockedUntil: m['locked_until']?.toString(),
        isActive: _parseBool(m['is_active'], defaultValue: true),
        lastLoginAt: m['last_login_at']?.toString(),
        createdAt: (m['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      );
}
