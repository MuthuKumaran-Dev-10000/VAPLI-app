import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import '../models/tank_model.dart';

class TankRepository {
  static final TankRepository _instance = TankRepository._internal();
  factory TankRepository() => _instance;
  TankRepository._internal();

  final _controller = StreamController<List<TankModel>>.broadcast();

  Stream<List<TankModel>> watchTanks() {
    getAllTanks().then((tanks) {
      if (!_controller.isClosed) {
        _controller.add(tanks);
      }
    }).catchError((err) {
      if (!_controller.isClosed) {
        _controller.addError(err);
      }
    });
    return _controller.stream;
  }

  Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  Future<List<TankModel>> getAllTanks() async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/tanks');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      final tanks = list
          .map((item) => TankModel.fromMap(Map<String, dynamic>.from(item)))
          .where((t) => t.isActive)
          .toList();
      if (!_controller.isClosed) {
        _controller.add(tanks);
      }
      return tanks;
    }
    return [];
  }

  Future<TankModel?> getTankById(String id) async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/tanks/$id');
    if (response is Map && response['success'] == true && response['data'] != null) {
      return TankModel.fromMap(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  Future<TankModel> createTank({
    required String tankCode,
    required String tankName,
    required String location,
    required double scaleMax,
    String? qrImageUrl,
    String? scaleSide,
    required String createdBy,
    required List<Map<String, dynamic>> properties,
  }) async {
    final clientId = await _getClientId();
    final response = await ApiClient.post('/clients/$clientId/tanks', {
      'tank_code': tankCode,
      'tank_name': tankName,
      'location': location,
      'scale_max': scaleMax,
      'scale_side': scaleSide,
      'qr_image_url': qrImageUrl,
      'created_by': createdBy,
      'inspection_properties': properties,
    });

    if (response is Map && response['success'] == true && response['data'] != null) {
      final tank = TankModel.fromMap(Map<String, dynamic>.from(response['data']));
      await getAllTanks();
      return tank;
    } else {
      final msg = (response is Map && response['error'] != null)
          ? response['error']['message']
          : 'Failed to create tank';
      throw Exception(msg);
    }
  }

  Future<void> updateTank({
    required String id,
    required String tankCode,
    required String tankName,
    required String location,
    required double scaleMax,
    String? scaleSide,
    String? qrImageUrl,
    required List<Map<String, dynamic>> properties,
  }) async {
    final clientId = await _getClientId();
    await ApiClient.put('/clients/$clientId/tanks/$id', {
      'tank_code': tankCode,
      'tank_name': tankName,
      'location': location,
      'scale_max': scaleMax,
      'scale_side': scaleSide,
      'qr_image_url': qrImageUrl,
      'inspection_properties': properties,
    });
    await getAllTanks();
  }

  Future<void> deleteTank(String id) async {
    final clientId = await _getClientId();
    await ApiClient.delete('/clients/$clientId/tanks/$id');
    await getAllTanks();
  }

  Future<String> duplicateTank(TankModel tank) async {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final newCode = '${tank.tankCode}_$suffix';
    final baseName = tank.tankName.replaceAll(RegExp(r'\s*\(\s*Copy(\s*\d+)?\s*\)$', caseSensitive: false), '');
    final newName = '$baseName (Copy $suffix)';

    final newTank = await createTank(
      tankCode: newCode,
      tankName: newName,
      location: tank.location ?? '',
      scaleMax: tank.scaleMax,
      scaleSide: tank.scaleSide,
      qrImageUrl: tank.qrImageUrl,
      createdBy: tank.createdBy ?? 'user',
      properties: tank.inspectionProperties,
    );
    return newTank.id;
  }

  Future<void> updateInspectionFrequency({
    required String tankId,
    required String type,
    required int days,
  }) async {
    final clientId = await _getClientId();
    await ApiClient.put('/clients/$clientId/tanks/$tankId', {
      'inspection_frequency_type': type,
      'inspection_frequency_days': days < 1 ? 1 : days,
    });
    await getAllTanks();
  }
}
