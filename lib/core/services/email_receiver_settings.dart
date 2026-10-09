import 'dart:convert';

import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';

/// Firebase-compatible receiver keys (typo Recievers preserved).
class EmailReceiverSettings {
  static const reportKey = 'Report_Recievers';
  static const alertsKey = 'Alerts_Recievers';
  static const missingTanksKey = 'Missing Tanks_Recievers';

  static Future<String> _clientId() => ClientContextService.requireActiveClientId();

  static List<String> parseEmailids(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is Map) {
      return raw.values
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];
      if (s.startsWith('{') || s.startsWith('[')) {
        try {
          return parseEmailids(jsonDecode(s));
        } catch (_) {}
      }
      return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  static List<String> _emailsFromSettingValue(dynamic settingValue) {
    if (settingValue == null) return [];
    if (settingValue is String) {
      try {
        final decoded = jsonDecode(settingValue);
        return _emailsFromSettingValue(decoded);
      } catch (_) {
        return parseEmailids(settingValue);
      }
    }
    if (settingValue is Map) {
      final emailids = settingValue['Emailids'] ?? settingValue['emailids'];
      return parseEmailids(emailids);
    }
    return parseEmailids(settingValue);
  }

  static Future<List<String>> loadEmails(String settingKey) async {
    final clientId = await _clientId();
    final response = await ApiClient.get('/clients/$clientId/bootstrap');
    if (response is! Map || response['success'] != true || response['data'] == null) {
      return [];
    }
    final settings = response['data']['settings'];
    if (settings is! Map) return [];
    final raw = settings[settingKey];
    return _emailsFromSettingValue(raw);
  }

  static Future<void> saveEmails(String settingKey, List<String> emails) async {
    final clientId = await _clientId();
    final unique = <String>{};
    for (final e in emails) {
      final t = e.trim();
      if (t.isNotEmpty) unique.add(t);
    }
    final list = unique.toList();
    await ApiClient.put('/clients/$clientId/settings', {
      'key': settingKey,
      'value': {'Emailids': list},
    });
  }

  static List<String> mergeParsedInput(String rawText, List<String> existing) {
    final added = parseEmailids(rawText.split(','));
    final merged = <String>{...existing, ...added};
    return merged.toList();
  }
}
