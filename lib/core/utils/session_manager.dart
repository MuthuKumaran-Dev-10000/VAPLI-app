import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/client_model.dart';
import '../../data/models/user_model.dart';
import '../services/database_mode_service.dart';

class SessionManager {
  static const String _keyToken = 'vapli_auth_token';
  static const String _keyUser = 'vapli_auth_user';
  static const String _keyActiveClient = 'active_client';
  static const String _keyLastUsedClient = 'last_used_client';

  static Future<void> saveSession(
    String token,
    UserModel user, {
    ClientModel? activeClient,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));

    if (activeClient != null) {
      await saveActiveClient(activeClient);
    }
  }

  static Future<void> saveActiveClient(ClientModel client) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(client.toJson());
    await prefs.setString(_keyActiveClient, jsonStr);
    await prefs.setString(_keyLastUsedClient, jsonStr);

    final dbKey = client.dbKey.isNotEmpty ? client.dbKey : client.id;
    DatabaseModeService.activeClientId.value = dbKey;
    debugPrint('[SessionManager] Active client saved: name="${client.name}", id="${client.id}", dbKey="$dbKey"');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString(_keyUser);
    if (userRaw == null || userRaw.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(userRaw);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<ClientModel?> getActiveClient() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveClient) ?? prefs.getString(_keyLastUsedClient);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      final client = ClientModel.fromJson(map);
      if (DatabaseModeService.activeClientId.value == null) {
        DatabaseModeService.activeClientId.value = client.dbKey.isNotEmpty ? client.dbKey : client.id;
      }
      return client;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getActiveClientName() async {
    final client = await getActiveClient();
    return client?.name;
  }

  static Future<String?> getActiveClientId() async {
    final client = await getActiveClient();
    return client?.id;
  }

  static Future<String?> getActiveClientDbKey() async {
    final client = await getActiveClient();
    return client?.dbKey.isNotEmpty == true ? client!.dbKey : client?.id;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyActiveClient);
    await prefs.remove(_keyLastUsedClient);
    DatabaseModeService.activeClientId.value = null;
    debugPrint('[SessionManager] Session and active client cleared.');
  }
}
