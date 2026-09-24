import 'dart:convert';

class ReadingModel {
  final String id;
  final String tankId;
  final String? tankSnapshotName;
  final double? finalLevel;
  final Map<String, dynamic> inspectionValues;
  final String? imageUrl;
  final String source;
  final String capturedBy;
  final String capturedByName;
  final String? inferenceTimeMs;
  final String? capturedAtStart;
  final String capturedAt;

  ReadingModel({
    required this.id,
    required this.tankId,
    this.tankSnapshotName,
    this.finalLevel,
    Map<String, dynamic>? inspectionValues,
    this.imageUrl,
    this.source = 'manual',
    required this.capturedBy,
    required this.capturedByName,
    this.inferenceTimeMs,
    this.capturedAtStart,
    required this.capturedAt,
  }) : inspectionValues = inspectionValues ?? {};

  Map<String, dynamic> toMap() => {
        'id': id,
        'tank_id': tankId,
        'tank_snapshot_name': tankSnapshotName,
        'final_level': finalLevel,
        'inspection_values': inspectionValues,
        'image_url': imageUrl,
        'source': source,
        'captured_by': capturedBy,
        'captured_by_name': capturedByName,
        'inference_time_ms': inferenceTimeMs,
        'captured_at_start': capturedAtStart,
        'captured_at': capturedAt,
      };

  factory ReadingModel.fromMap(Map<String, dynamic> m) {
    double? parsedLevel;
    final rawLevel = m['final_level'];
    if (rawLevel != null) {
      if (rawLevel is num) {
        parsedLevel = rawLevel.toDouble();
      } else if (rawLevel is String) {
        parsedLevel = double.tryParse(rawLevel);
      }
    }

    Map<String, dynamic> parsedValues = {};
    final rawValues = m['inspection_values'] ?? m['inspection_values_json'];
    if (rawValues != null) {
      if (rawValues is Map) {
        parsedValues = Map<String, dynamic>.from(rawValues);
      } else if (rawValues is String && rawValues.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawValues);
          if (decoded is Map) {
            parsedValues = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return ReadingModel(
      id: m['id']?.toString() ?? '',
      tankId: m['tank_id']?.toString() ?? '',
      tankSnapshotName: m['tank_snapshot_name']?.toString(),
      finalLevel: parsedLevel,
      inspectionValues: parsedValues,
      imageUrl: m['image_url']?.toString(),
      source: m['source']?.toString() ?? 'manual',
      capturedBy: m['captured_by']?.toString() ?? '',
      capturedByName: m['captured_by_name']?.toString() ?? '',
      inferenceTimeMs: m['inference_time_ms']?.toString(),
      capturedAtStart: m['captured_at_start']?.toString(),
      capturedAt: m['captured_at']?.toString() ??
          DateTime.now().toIso8601String(),
    );
  }
}