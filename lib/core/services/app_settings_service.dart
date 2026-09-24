import 'package:lubrication_indicator/core/constants/app_constants.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';

class AppSettingsService {
  static Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  static Future<Duration?> getSessionTimeout() async {
    return const Duration(minutes: AppConstants.sessionDurationMinutes);
  }

  static Future<void> setSessionTimeout({
    required bool noTimeout,
    required int minutes,
  }) async {}

  static Future<Map<String, bool>> getDashboardDisplaySettings() async {
    try {
      final clientId = await _getClientId();
      final response = await ApiClient.get('/clients/$clientId/bootstrap');
      if (response is Map && response['success'] == true && response['data'] != null) {
        final settings = response['data']['settings'] as Map? ?? {};
        final display = settings['dashboard_display'] as Map? ?? {};
        return {
          'show_inspection_values': display['show_inspection_values'] ?? true,
          'show_completed_alerts': display['show_completed_alerts'] ?? true,
          'show_active_alerts': display['show_active_alerts'] ?? true,
          'show_inspection_compliance': display['show_inspection_compliance'] ?? true,
        };
      }
    } catch (_) {}
    return {
      'show_inspection_values': true,
      'show_completed_alerts': true,
      'show_active_alerts': true,
      'show_inspection_compliance': true,
    };
  }

  static Future<void> setDashboardDisplaySettings({
    required bool showInspectionValues,
    required bool showCompletedAlerts,
    required bool showActiveAlerts,
    required bool showInspectionCompliance,
  }) async {}
}
