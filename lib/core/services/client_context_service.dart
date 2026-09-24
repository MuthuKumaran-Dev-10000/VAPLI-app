import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lubrication_indicator/core/models/client_model.dart';
import 'package:lubrication_indicator/core/services/database_mode_service.dart';

class ClientContextService {
  static const _key = 'active_client';
  static const _lastUsedKey = 'last_used_client';

  static final StreamController<ClientModel?> _activeClientController =
      StreamController<ClientModel?>.broadcast();

  static Stream<ClientModel?> get activeClientStream =>
      _activeClientController.stream;

  static Future<void> setActiveClient(ClientModel client) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(client.toMap());
    await prefs.setString(_key, raw);
    await prefs.setString(_lastUsedKey, raw);
    await DatabaseModeService.setClientScope(client.dbKey);
    _activeClientController.add(client);
  }

  static Future<ClientModel?> getActiveClient() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    return ClientModel.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  static Future<void> clearActiveClient() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await DatabaseModeService.setClientScope(null);
    _activeClientController.add(null);
  }

  static Future<void> setLastUsedClient(ClientModel client) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsedKey, jsonEncode(client.toMap()));
  }

  static Future<ClientModel?> getLastUsedClient() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastUsedKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return ClientModel.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  static Future<String?> resolveClientName({String? fallback}) async {
    final active = await getActiveClient();
    final activeName = active?.name.trim();
    if (activeName != null && activeName.isNotEmpty) return activeName;

    final lastUsed = await getLastUsedClient();
    final lastName = lastUsed?.name.trim();
    if (lastName != null && lastName.isNotEmpty) return lastName;

    final fallbackName = fallback?.trim();
    if (fallbackName != null && fallbackName.isNotEmpty) return fallbackName;
    return null;
  }
}
