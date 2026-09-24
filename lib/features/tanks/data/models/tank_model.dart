class TankModel {
  final String id;
  final String tankCode;
  final String tankName;
  final String? location;
  final String? qrJson;
  final String? qrImageUrl;
  final List<Map<String, dynamic>> inspectionProperties;
  final double scaleMin;
  final double scaleMax;
  final String? scaleSide;
  final bool isActive;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final String inspectionFrequencyType; // daily|weekly_once|weekly_thrice|custom_days
  final int inspectionFrequencyDays;
  final Map<String, dynamic> groups;

  TankModel({
    required this.id,
    required this.tankCode,
    required this.tankName,
    this.location,
    this.qrJson,
    this.qrImageUrl,
    this.inspectionProperties = const [],
    this.scaleMin = 0,
    required this.scaleMax,
    this.scaleSide,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.inspectionFrequencyType = 'daily',
    this.inspectionFrequencyDays = 1,
    this.groups = const {},
  });

  String get uniqueKey => "${tankCode}_${tankName}_${location ?? "nozone"}"
      .toLowerCase()
      .replaceAll(
        " ",
        "_",
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "tank_code": tankCode,
        "tank_name": tankName,
        "location": location,
        "qr_json": qrJson,
        "qr_image_url": qrImageUrl,
        "inspection_properties": inspectionProperties,
        "scale_min": scaleMin,
        "scale_max": scaleMax,
        "scale_side": scaleSide,
        "is_active": isActive,
        "created_by": createdBy,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "inspection_frequency_type": inspectionFrequencyType,
        "inspection_frequency_days": inspectionFrequencyDays,
        "Groups": groups,
      };

  factory TankModel.fromMap(
    Map<String, dynamic> m,
  ) {
    List<Map<String, dynamic>> properties = [];

    final raw = m["inspection_properties"] ?? m["inspection_properties_json"];
    if (raw != null) {
      if (raw is List) {
        properties = raw
            .whereType<Map>()
            .map(
              (e) => Map<String, dynamic>.from(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList();
      } else if (raw is Map) {
        properties = raw.values
            .whereType<Map>()
            .map(
              (e) => Map<String, dynamic>.from(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList();
      }
    }

    Map<String, dynamic> parsedGroups = {};
    if (m["Groups"] != null || m["groups"] != null) {
      final rawGroups = m["Groups"] ?? m["groups"];
      if (rawGroups is Map) {
        try {
          parsedGroups = <String, dynamic>{};
          for (final entry in rawGroups.entries) {
            parsedGroups[entry.key.toString()] = entry.value;
          }
        } catch (_) {}
      }
    }

    bool parseBool(dynamic val, {bool defaultValue = true}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1';
      }
      return defaultValue;
    }

    double parseDouble(dynamic val, {double defaultValue = 0.0}) {
      if (val == null) return defaultValue;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? defaultValue;
      }
      return defaultValue;
    }

    return TankModel(
      id: m["id"]?.toString() ?? "",
      tankCode: m["tank_code"]?.toString() ?? "",
      tankName: m["tank_name"]?.toString() ?? "",
      location: m["location"]?.toString(),
      qrJson: m["qr_json"]?.toString(),
      qrImageUrl: m["qr_image_url"]?.toString(),
      inspectionProperties: properties,
      scaleMin: parseDouble(m["scale_min"], defaultValue: 0.0),
      scaleMax: parseDouble(m["scale_max"], defaultValue: 100.0),
      scaleSide: m["scale_side"]?.toString(),
      isActive: parseBool(m["is_active"], defaultValue: true),
      createdBy: m["created_by"]?.toString() ?? "",
      createdAt: m["created_at"]?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: m["updated_at"]?.toString() ?? DateTime.now().toIso8601String(),
      inspectionFrequencyType:
          (m["inspection_frequency_type"] ?? 'daily').toString(),
      inspectionFrequencyDays: (m["inspection_frequency_days"] is num)
          ? (m["inspection_frequency_days"] as num).toInt()
          : int.tryParse(m["inspection_frequency_days"]?.toString() ?? '') ??
              (((m["inspection_frequency_type"] ?? 'daily').toString() == 'weekly_once')
                  ? 7
                  : ((m["inspection_frequency_type"] ?? 'daily').toString() ==
                          'weekly_thrice')
                      ? 2
                      : 1),
      groups: parsedGroups,
    );
  }
}
