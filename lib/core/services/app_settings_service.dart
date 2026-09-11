import 'package:flutter/foundation.dart';
import '../../../data/api/api_client.dart';

class AppSettingsService {
  static final ApiClient _api = ApiClient();

  static Future<Duration?> getSessionTimeout() async {
    try {
      final res = await _api.get('/settings/session_timeout');
      if (res is Map && res['value'] is Map) {
        final data = Map<String, dynamic>.from(res['value'] as Map);
        final mode = (data['mode'] ?? 'minutes').toString();
        if (mode == 'none') return null;
        final minutes = (data['minutes'] as num?)?.toInt() ?? 60;
        return Duration(minutes: minutes.clamp(1, 1440));
      }
    } catch (e) {
      debugPrint('[AppSettingsService] getSessionTimeout error: $e');
    }
    return const Duration(minutes: 60);
  }

  static Future<void> setSessionTimeout({
    required bool noTimeout,
    required int minutes,
  }) async {
    try {
      await _api.post('/settings/session_timeout', {
        'mode': noTimeout ? 'none' : 'minutes',
        'minutes': minutes.clamp(1, 1440),
      });
    } catch (e) {
      debugPrint('[AppSettingsService] setSessionTimeout error: $e');
    }
  }

  static Future<Map<String, bool>> getDashboardDisplaySettings() async {
    try {
      final res = await _api.get('/settings/dashboard_display');
      if (res is Map && res['value'] is Map) {
        final data = Map<String, dynamic>.from(res['value'] as Map);
        return {
          'show_inspection_values': data['show_inspection_values'] ?? true,
          'show_completed_alerts': data['show_completed_alerts'] ?? true,
          'show_active_alerts': data['show_active_alerts'] ?? true,
          'show_inspection_compliance': data['show_inspection_compliance'] ?? true,
        };
      }
    } catch (e) {
      debugPrint('[AppSettingsService] getDashboardDisplaySettings error: $e');
    }
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
  }) async {
    try {
      await _api.post('/settings/dashboard_display', {
        'show_inspection_values': showInspectionValues,
        'show_completed_alerts': showCompletedAlerts,
        'show_active_alerts': showActiveAlerts,
        'show_inspection_compliance': showInspectionCompliance,
      });
    } catch (e) {
      debugPrint('[AppSettingsService] setDashboardDisplaySettings error: $e');
    }
  }

  static Future<dynamic> getSetting(String key) async {
    try {
      final res = await _api.get('/settings/$key');
      if (res is Map && res.containsKey('value')) {
        return res['value'];
      }
    } catch (e) {
      debugPrint('[AppSettingsService] getSetting ($key) error: $e');
    }
    return null;
  }

  static Future<void> setSetting(String key, dynamic value) async {
    try {
      await _api.post('/settings/$key', {
        'value': value,
      });
    } catch (e) {
      debugPrint('[AppSettingsService] setSetting ($key) error: $e');
    }
  }
}
