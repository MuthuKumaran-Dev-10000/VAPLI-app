import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/client_model.dart';
import '../utils/session_manager.dart';
import 'database_mode_service.dart';

class ClientContextService {
  static const _key = 'active_client';
  static const _lastUsedKey = 'last_used_client';

  static Future<String?> resolveClientName({String? fallback}) async {
    // 1. Try SessionManager active client
    final activeClientName = await SessionManager.getActiveClientName();
    if (activeClientName != null && activeClientName.isNotEmpty) {
      return activeClientName;
    }

    // 2. Try SharedPreferences JSON
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? prefs.getString(_lastUsedKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw);
        if (map is Map && map['name'] != null && map['name'].toString().isNotEmpty) {
          return map['name'].toString();
        }
      } catch (_) {}
    }

    // 3. Fallback to passed fallback parameter if valid
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }

    // 4. Default fallback if nothing else resolved
    return null;
  }

  static Future<ClientModel?> resolveActiveClient() async {
    return await SessionManager.getActiveClient();
  }

  static Future<void> setActiveClient(ClientModel client) async {
    await SessionManager.saveActiveClient(client);
    DatabaseModeService.activeClientId.value = client.dbKey.isNotEmpty ? client.dbKey : client.id;
  }
}
