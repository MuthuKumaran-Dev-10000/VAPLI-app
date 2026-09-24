class ClientModel {
  final String id;
  final String name;
  final String dbKey;
  final String description;
  final String? rootFolderId;
  final bool isActive;
  final String createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.dbKey,
    required this.description,
    this.rootFolderId,
    this.isActive = true,
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
        'name': name,
        'db_key': dbKey,
        'description': description,
        'root_folder_id': rootFolderId,
        'is_active': isActive,
        'created_at': createdAt,
      };

  factory ClientModel.fromMap(Map<String, dynamic> m) => ClientModel(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        dbKey: m['db_key']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        rootFolderId: m['root_folder_id']?.toString(),
        isActive: _parseBool(m['is_active'], defaultValue: true),
        createdAt: m['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      );
}
