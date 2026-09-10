import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:vapli/data/api/api_client.dart';
import '../models/reading_model.dart';

class ReadingRepository {
  final ApiClient _api = ApiClient();
  final _uuid = const Uuid();

  Future<String?> uploadReadingImage({
    required Uint8List bytes,
    required String category, // 'violation_image' | 'auto_capture_image' | 'manual_capture_image'
    required String assetId,
    required String readingId,
    String? paramId,
    String? imageId,
    String? dateStr,
  }) async {
    try {
      final fields = <String, String>{
        'category': category,
        'asset_id': assetId,
        'reading_id': readingId,
      };
      if (paramId != null) fields['param_id'] = paramId;
      if (imageId != null) fields['image_id'] = imageId;
      if (dateStr != null) fields['date_str'] = dateStr;

      final res = await _api.uploadMultipart(
        '/uploads/readings',
        bytes: bytes,
        filename: 'image.png',
        fields: fields,
      );

      if (res is Map && res['url'] != null) {
        return res['url'].toString();
      }
    } catch (e) {
      debugPrint('[ReadingRepository] uploadReadingImage error: $e');
    }
    return null;
  }

  Future<ReadingModel> saveReading({
    required String tankId,
    required String tankName,
    required double level,
    required String capturedBy,
    required String capturedByName,
    String? capturedAtStart,
    String? capturedAt,
    Map<String, dynamic>? inspectionValues,
    List<ReadingValueModel>? valuesList,
    List<ReadingImageModel>? imagesList,
    String? imageUrl,
  }) async {
    final id = _uuid.v4();
    final now = capturedAt ?? DateTime.now().toIso8601String();

    final reading = ReadingModel(
      id: id,
      tankId: tankId,
      tankSnapshotName: tankName,
      finalLevel: level,
      inspectionValues: inspectionValues ?? {},
      valuesList: valuesList ?? [],
      imagesList: imagesList ?? [],
      imageUrl: imageUrl,
      source: "manual",
      capturedBy: capturedBy,
      capturedByName: capturedByName,
      capturedAtStart: capturedAtStart,
      capturedAt: now,
    );

    final payload = {
      'id': id,
      'tank_id': tankId,
      'tank_snapshot_name': tankName,
      'final_level': level,
      'recorded_by_id': capturedBy,
      'recorded_by_name': capturedByName,
      'recorded_by_role': 'user',
      'values_json': inspectionValues ?? {},
      'inspection_values': inspectionValues ?? {},
      'values_list': (valuesList ?? []).map((v) => v.toMap()).toList(),
      'images_list': (imagesList ?? []).map((i) => i.toMap()).toList(),
      'image_url': imageUrl,
      'timestamp': now,
      'captured_at': now,
      'captured_at_start': capturedAtStart,
    };

    await _api.post('/readings', payload);
    return reading;
  }

  Future<List<ReadingModel>> watchReadingsForTank(String tankId) async {
    return getReadingsForTank(tankId);
  }

  Future<List<ReadingModel>> getReadingsForTank(String tankId) async {
    final res = await _api.get('/readings?tank_id=$tankId');
    if (res is Map && res['readings'] is List) {
      final list = (res['readings'] as List).cast<Map>();
      return list
          .map((m) => ReadingModel.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    return [];
  }

  Future<List<ReadingModel>> getAllReadings() async {
    final res = await _api.get('/readings');
    if (res is Map && res['readings'] is List) {
      final list = (res['readings'] as List).cast<Map>();
      return list
          .map((m) => ReadingModel.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    return [];
  }

  Future<List<ReadingModel>> getReadingsInRange({
    required String tankId,
    required DateTime from,
    required DateTime to,
  }) async {
    final list = await getReadingsForTank(tankId);
    return list.where((r) {
      final dt = DateTime.tryParse(r.capturedAt);
      if (dt == null) return false;
      return dt.isAfter(from) && dt.isBefore(to);
    }).toList();
  }
}
