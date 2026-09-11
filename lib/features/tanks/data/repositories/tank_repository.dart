import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/api/api_client.dart';
import 'package:vapli/features/tanks/presentation/widgets/create_tank_qr.dart';
import 'package:vapli/features/admin/services/admin_cloudinary.dart';
import '../models/tank_model.dart';
import 'tank_tree_repository.dart';

class TankRepository {
  final ApiClient _api = ApiClient();
  final _uuid = const Uuid();
  final _treeRepo = TankTreeRepository();

  Stream<List<TankModel>> watchTanks() async* {
    while (true) {
      try {
        final tanks = await getAllTanks();
        yield tanks;
      } catch (e) {
        debugPrint('[TankRepository] watchTanks error: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<List<TankModel>> getAllTanks() async {
    final res = await _api.get('/assets/tanks');
    if (res is Map && res['tanks'] is List) {
      final list = (res['tanks'] as List).cast<Map>();
      return list
          .map((m) => TankModel.fromMap(Map<String, dynamic>.from(m)))
          .where((t) => t.isActive)
          .toList();
    }
    return [];
  }

  Future<TankModel?> getTankById(String tankId) async {
    try {
      final res = await _api.get('/assets/tanks/$tankId');
      if (res is Map && res['tank'] is Map) {
        return TankModel.fromMap(Map<String, dynamic>.from(res['tank']));
      }
    } catch (_) {}
    return null;
  }

  Future<TankModel> createTank({
    required String tankCode,
    required String tankName,
    String? location,
    String? qrJson,
    String? qrImageUrl,
    List<Map<String, dynamic>> inspectionProperties = const [],
    List<Map<String, dynamic>>? properties,
    double scaleMin = 0,
    double scaleMax = 100,
    String? scaleSide,
    String? createdBy,
    String? parentId,
    String inspectionFrequencyType = 'daily',
    int inspectionFrequencyDays = 1,
    Map<String, dynamic> groups = const {},
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final actualProps = (properties != null && properties.isNotEmpty) ? properties : inspectionProperties;

    final tank = TankModel(
      id: id,
      tankCode: tankCode,
      tankName: tankName,
      location: location,
      qrJson: qrJson,
      qrImageUrl: qrImageUrl,
      inspectionProperties: actualProps,
      scaleMin: scaleMin,
      scaleMax: scaleMax,
      scaleSide: scaleSide,
      isActive: true,
      createdBy: createdBy ?? 'system',
      createdAt: now,
      updatedAt: now,
      inspectionFrequencyType: inspectionFrequencyType,
      inspectionFrequencyDays: inspectionFrequencyDays,
      groups: groups,
    );

    await _api.post('/assets/tanks', tank.toMap());

    // Create tree node
    await _treeRepo.createLeaf(
      name: tankName,
      tankId: id,
      zone: location,
      parentId: parentId,
    );

    return tank;
  }

  Future<String> duplicateTank(
    TankModel sourceTank, {
    String? customName,
    String? customCode,
    String? parentId,
  }) async {
    final newCode = customCode ?? '${sourceTank.tankCode}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newName = customName ?? '${sourceTank.tankName} (Copy)';
    final location = sourceTank.location ?? 'root';

    QrGenerationResult? qrResult;
    try {
      qrResult = await generateAndUploadQr(
        tankCode: newCode,
        tankName: newName,
        location: location,
      );
    } catch (e) {
      debugPrint('[TankRepository] Duplicate QR generation warning: $e');
    }

    final dup = await createTank(
      tankCode: newCode,
      tankName: newName,
      location: sourceTank.location,
      parentId: parentId,
      qrJson: qrResult?.qrJson ?? sourceTank.qrJson,
      qrImageUrl: qrResult?.qrImageUrl ?? sourceTank.qrImageUrl,
      inspectionProperties: sourceTank.inspectionProperties,
      scaleMin: sourceTank.scaleMin,
      scaleMax: sourceTank.scaleMax,
      scaleSide: sourceTank.scaleSide,
      createdBy: sourceTank.createdBy,
      inspectionFrequencyType: sourceTank.inspectionFrequencyType,
      inspectionFrequencyDays: sourceTank.inspectionFrequencyDays,
      groups: sourceTank.groups,
    );
    return dup.id;
  }

  Future<void> updateTank(TankModel tank) async {
    await _api.patch('/assets/tanks/${tank.id}', tank.toMap());
  }

  Future<void> updateInspectionFrequency({
    required String tankId,
    required String type,
    required int days,
  }) async {
    await _api.patch('/assets/tanks/$tankId', {
      'inspection_frequency_type': type,
      'inspection_frequency_days': days,
    });
  }

  Future<void> updateTankUrl(String tankId, String url) async {
    await _api.patch('/assets/tanks/$tankId', {'qr_image_url': url});
  }

  Future<void> deleteTank(String tankId) async {
    final tank = await getTankById(tankId);
    if (tank != null && tank.qrImageUrl != null) {
      await deleteImageByUrl(tank.qrImageUrl);
    }
    final node = await _treeRepo.getNodeByTankId(tankId);
    if (node != null) {
      await _treeRepo.deleteNode(node.id);
    }
    await _api.delete('/assets/tanks/$tankId');
  }

  Future<void> saveReading({
    required String tankId,
    String? nodeId,
    required String recordedById,
    required String recordedByName,
    required String recordedByRole,
    String? clientId,
    required Map<String, dynamic> values,
  }) async {
    await _api.post('/readings', {
      'id': _uuid.v4(),
      'tank_id': tankId,
      'node_id': nodeId,
      'recorded_by_id': recordedById,
      'recorded_by_name': recordedByName,
      'recorded_by_role': recordedByRole,
      'client_id': clientId,
      'values_json': values,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchParameterTemplates() async {
    final res = await _api.get('/assets/templates');
    if (res is Map && res['templates'] is List) {
      return (res['templates'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> saveParameterTemplate({
    required String name,
    String? description,
    required List<Map<String, dynamic>> properties,
    required String createdBy,
  }) async {
    await _api.post('/assets/templates', {
      'id': _uuid.v4(),
      'name': name,
      'description': description,
      'properties': properties,
      'created_by': createdBy,
    });
  }

  Future<void> deleteParameterTemplate(String id) async {
    await _api.delete('/assets/templates/$id');
  }
}
