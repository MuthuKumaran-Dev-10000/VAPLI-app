part of '../dashboard_tab.dart';

class _AlertModel {
  final String id;
  final String alertTitle;
  final String message;
  final String op;
  final String severity;
  final String tankId;
  final String tankName;
  final String tankCode;
  final String paramId;
  final String paramLabel;
  final String paramValue;
  final String capturedBy;
  final String capturedByName;
  final String imageUrl;
  final String constraintId;
  final String timestamp;
  final bool acknowledged;
  final bool isLive;
  final String status;
  final String readingId; // 🔖 Added for lookup in reports
  final String ifThen; // 🔖 Added for IF-THEN detail

  _AlertModel({
    required this.id,
    required this.alertTitle,
    required this.message,
    required this.severity,
    required this.op,
    required this.tankId,
    required this.tankName,
    required this.tankCode,
    required this.paramId,
    required this.paramLabel,
    required this.paramValue,
    required this.capturedBy,
    required this.capturedByName,
    required this.imageUrl,
    required this.constraintId,
    required this.timestamp,
    required this.acknowledged,
    required this.isLive,
    required this.status,
    this.readingId = '', // 🔖 Added for lookup in reports
    this.ifThen = '', // 🔖 Added for IF-THEN detail
    this.completedDescription = '',
    this.completedPhotoUrl = '',
    this.completedPhotoUrls = const [],
  });

  final String completedDescription;
  final String completedPhotoUrl;
  final List<String> completedPhotoUrls;

  factory _AlertModel.fromMap(Map<dynamic, dynamic> m) {
    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1';
      }
      return defaultValue;
    }

    final rawUrls = m['completed_photo_urls'];
    final List<String> parsedUrls = (rawUrls is List)
        ? rawUrls.map((e) => e.toString()).toList()
        : (m['completed_photo_url']?.toString().isNotEmpty == true
            ? [m['completed_photo_url'].toString()]
            : []);

    return _AlertModel(
      id: m['id']?.toString() ?? '',
      alertTitle: (m['alert_title'] ?? m['constraint_label'])?.toString() ?? '',
      message: m['message']?.toString() ?? '',
      severity: (m['severity'] ?? m['constraint_severity'])?.toString() ?? 'warning',
      op: (m['op'] ?? m['constraint_op'])?.toString() ?? 'null',
      tankId: m['tank_id']?.toString() ?? '',
      tankName: m['tank_name']?.toString() ?? '',
      tankCode: m['tank_code']?.toString() ?? '',
      paramId: (m['param_id'] ?? m['constraint_id'])?.toString() ?? '',
      paramLabel: (m['param_label'] ?? m['constraint_label'])?.toString() ?? '',
      paramValue: (m['param_value'] ?? m['violated_value'])?.toString() ?? '',
      capturedBy: m['captured_by']?.toString() ?? '',
      capturedByName: m['captured_by_name']?.toString() ?? '',
      imageUrl: m['image_url']?.toString() ?? '',
      constraintId: m['constraint_id']?.toString() ?? '',
      timestamp: (m['timestamp'] ?? m['captured_at'])?.toString() ?? '',
      acknowledged: parseBool(m['acknowledged'] ?? m['resolved']),
      isLive: m['live'] == true,
      status: m['status']?.toString() ?? 'active',
      readingId: m['reading_id']?.toString() ?? '',
      ifThen: m['if_then']?.toString() ?? '',
      completedDescription: m['completed_description']?.toString() ?? '',
      completedPhotoUrl: m['completed_photo_url']?.toString() ?? '',
      completedPhotoUrls: parsedUrls,
    );
  }
}
