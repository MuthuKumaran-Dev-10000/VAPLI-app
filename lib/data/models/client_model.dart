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

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dbKey: json['dbKey']?.toString() ?? json['db_key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rootFolderId: json['rootFolderId']?.toString() ?? json['root_folder_id']?.toString(),
      isActive: json['isActive'] != false && json['is_active'] != false,
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dbKey': dbKey,
        'description': description,
        'rootFolderId': rootFolderId,
        'isActive': isActive,
        'createdAt': createdAt,
      };
}
