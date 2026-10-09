import 'dart:convert';

import 'package:lubrication_indicator/core/constants/app_constants.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';

class AppSettingsService {
  static Future<String> _getClientId() async {
    return ClientContextService.requireActiveClientId();
  }

  static Future<Duration?> getSessionTimeout() async {
    return const Duration(minutes: AppConstants.sessionDurationMinutes);
  }

  static Future<void> setSessionTimeout({
    required bool noTimeout,
    required int minutes,
  }) async {}

  static Future<Map<String, dynamic>> getDashboardDisplaySettings() async {
    try {
      final clientId = await _getClientId();
      final response = await ApiClient.get('/clients/$clientId/bootstrap');
      if (response is Map && response['success'] == true && response['data'] != null) {
        final settings = response['data']['settings'] as Map? ?? {};
        final display = _coerceSettingsMap(settings['dashboard_display']);
        return {
          'show_inspection_values': display['show_inspection_values'] ?? true,
          'show_completed_alerts': display['show_completed_alerts'] ?? true,
          'show_active_alerts': display['show_active_alerts'] ?? true,
          'show_inspection_compliance': display['show_inspection_compliance'] ?? true,
          'completion_proof_pin': display['completion_proof_pin']?.toString() ??
              display['task_completion_pin']?.toString() ??
              '',
        };
      }
    } catch (_) {}
    return {
      'show_inspection_values': true,
      'show_completed_alerts': true,
      'show_active_alerts': true,
      'show_inspection_compliance': true,
      'completion_proof_pin': '',
    };
  }

  static Map<String, dynamic> _coerceSettingsMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static Future<void> setDashboardDisplaySettings({
    required bool showInspectionValues,
    required bool showCompletedAlerts,
    required bool showActiveAlerts,
    required bool showInspectionCompliance,
    String? completionProofPin,
  }) async {
    final clientId = await _getClientId();
    Map<String, dynamic> display = {};
    try {
      final response = await ApiClient.get('/clients/$clientId/bootstrap');
      if (response is Map && response['success'] == true && response['data'] != null) {
        final settings = response['data']['settings'] as Map? ?? {};
        display = _coerceSettingsMap(settings['dashboard_display']);
      }
    } catch (_) {}

    display['show_inspection_values'] = showInspectionValues;
    display['show_completed_alerts'] = showCompletedAlerts;
    display['show_active_alerts'] = showActiveAlerts;
    display['show_inspection_compliance'] = showInspectionCompliance;
    final pin = completionProofPin?.trim() ?? '';
    if (pin.isNotEmpty) {
      display['completion_proof_pin'] = pin;
    } else {
      display.remove('completion_proof_pin');
      display.remove('task_completion_pin');
    }
    display['updated_at'] = DateTime.now().toIso8601String();

    await ApiClient.put('/clients/$clientId/settings', {
      'key': 'dashboard_display',
      'value': display,
    });
  }
}
