import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import '../models/alert_model.dart';

class AlertRepository {
  Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  Future<AlertModel> createAlert({
    required String tankId,
    required String tankCode,
    required String tankName,
    String? tankLocation,
    String? tankPath,
    required String readingId,
    required String capturedBy,
    required String capturedByName,
    required String capturedAt,
    required Map<String, dynamic> constraint,
    required String constraintLabel,
    required String violatedValue,
    required Map<String, dynamic> lastInspectionValues,
  }) async {
    final id = 'alert_${DateTime.now().millisecondsSinceEpoch}';
    final alert = AlertModel(
      id: id,
      tankId: tankId,
      tankCode: tankCode,
      tankName: tankName,
      tankLocation: tankLocation,
      tankPath: tankPath,
      readingId: readingId,
      capturedBy: capturedBy,
      capturedByName: capturedByName,
      capturedAt: capturedAt,
      constraintId: constraint['id']?.toString() ?? '',
      constraintOp: constraint['op']?.toString() ?? '',
      constraintValue: constraint['value']?.toString() ?? '',
      constraintSeverity: constraint['severity']?.toString() ?? 'warning',
      constraintLabel: constraintLabel,
      violatedValue: violatedValue,
      alertTitle: constraint['alert_title']?.toString() ?? constraintLabel,
      message: constraint['message']?.toString() ?? 'Constraint alert',
      showDashboardAlert: constraint['show_dashboard_alert'] == true,
      playSound: constraint['play_sound_on_violation'] == true,
      captureImageOnViolation: constraint['capture_image_on_violation'] == true,
      blockSubmission: constraint['block_submission'] == true,
      lastInspectionValues: lastInspectionValues,
      resolved: false,
      status: 'active',
    );
    return alert;
  }

  Stream<List<AlertModel>> watchAll() {
    final controller = StreamController<List<AlertModel>>.broadcast();
    getAll().then((list) {
      controller.add(list);
    }).catchError((err) {
      controller.addError(err);
    });
    return controller.stream;
  }

  Stream<List<AlertModel>> watchForTank(String tankId) {
    final controller = StreamController<List<AlertModel>>.broadcast();
    getAll().then((list) {
      final filtered = list.where((a) => a.tankId == tankId).toList();
      controller.add(filtered);
    }).catchError((err) {
      controller.addError(err);
    });
    return controller.stream;
  }

  Future<List<AlertModel>> getActiveDashboardAlerts() async {
    final all = await getAll();
    return all.where((a) => !a.resolved && a.showDashboardAlert).toList();
  }

  Future<List<AlertModel>> getAll() async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/alerts');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      return list
          .map((item) => AlertModel.fromMap(
                item['id'].toString(),
                Map<dynamic, dynamic>.from(item),
              ))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    return [];
  }

  Future<void> resolveAlert({
    required String alertId,
    required String resolvedBy,
  }) async {
    final clientId = await _getClientId();
    await ApiClient.put('/clients/$clientId/alerts/$alertId/resolve', {
      'description': 'Alert resolved by $resolvedBy',
    });
  }

  Future<void> deleteAlert(String alertId) async {
    // Delete supported via resolution / backend API
  }
}
