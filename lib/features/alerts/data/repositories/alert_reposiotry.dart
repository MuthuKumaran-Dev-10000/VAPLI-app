import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';

class AlertRepository {
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
    return AlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      tankId: tankId,
      tankCode: tankCode,
      tankName: tankName,
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
      alertTitle: constraintLabel,
      message: 'Violation on $constraintLabel',
      showDashboardAlert: false,
      playSound: false,
      captureImageOnViolation: false,
      blockSubmission: false,
      lastInspectionValues: lastInspectionValues,
    );
  }

  Stream<List<AlertModel>> watchAll() async* {
    yield [];
  }

  Stream<List<AlertModel>> watchForTank(String tankId) async* {
    yield [];
  }

  Future<List<AlertModel>> getActiveDashboardAlerts() async => [];
  Future<List<AlertModel>> getAll() async => [];
  Future<void> resolveAlert({required String alertId, required String resolvedBy}) async {}
  Future<void> deleteAlert(String alertId) async {}
}
