import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';

class DatabaseModeService {
  static const _prefKey = 'db_mode_development';
  static const _clientScopeKey = 'db_client_scope';

  static final ValueNotifier<bool> isDevelopment = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> activeClientId =
      ValueNotifier<String?>(null);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDevelopment.value = prefs.getBool(_prefKey) ?? false;
    final cid = prefs.getString(_clientScopeKey);
    activeClientId.value = (cid == null || cid.trim().isEmpty) ? null : cid;
    ApiClient.currentClientId = activeClientId.value;
  }

  static Future<void> setDevelopment(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    isDevelopment.value = enabled;
  }

  static Future<void> toggle() => setDevelopment(!isDevelopment.value);

  static Future<void> setClientScope(String? clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        (clientId == null || clientId.trim().isEmpty) ? null : clientId.trim();
    activeClientId.value = normalized;
    ApiClient.currentClientId = normalized;
    if (normalized == null) {
      await prefs.remove(_clientScopeKey);
    } else {
      await prefs.setString(_clientScopeKey, normalized);
    }
  }

  static String path(String rawPath) {
    return rawPath;
  }
}
