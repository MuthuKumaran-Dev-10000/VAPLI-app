import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/app_settings_service.dart';
import 'package:lubrication_indicator/features/auth/data/models/user_model.dart';
import '../constants/app_constants.dart';

class SessionManager {
  static const _sessionKey = 'active_session';
  static const _sessionExpiry = 'session_expiry';
  static const _tokenKey = 'auth_token';

  static Future<void> saveSession(UserModel user, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    final timeout = await AppSettingsService.getSessionTimeout();
    final expiry = timeout == null
        ? 'never'
        : DateTime.now().add(timeout).toIso8601String();
    await prefs.setString(_sessionKey, jsonEncode(user.toMap()));
    await prefs.setString(_sessionExpiry, expiry);

    final tokenToSave = token ?? ApiClient.authToken;
    if (tokenToSave != null && tokenToSave.isNotEmpty) {
      await prefs.setString(_tokenKey, tokenToSave);
      ApiClient.authToken = tokenToSave;
    } else if (user.username == 'admin') {
      try {
        final res = await ApiClient.post('/auth/login', {
          'username': 'admin',
          'password': 'Admin@123',
        });
        if (res is Map && res['success'] == true && res['data'] != null) {
          final fetchedToken = res['data']['token'] as String?;
          if (fetchedToken != null) {
            await prefs.setString(_tokenKey, fetchedToken);
            ApiClient.authToken = fetchedToken;
          }
        }
      } catch (_) {}
    }
  }

  static Future<void> _restoreToken(SharedPreferences prefs) async {
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      ApiClient.authToken = savedToken;
    } else {
      final sessionStr = prefs.getString(_sessionKey);
      if (sessionStr != null) {
        try {
          final map = jsonDecode(sessionStr);
          if (map['username'] == 'admin') {
            final res = await ApiClient.post('/auth/login', {
              'username': 'admin',
              'password': 'Admin@123',
            });
            if (res is Map && res['success'] == true && res['data'] != null) {
              final fetchedToken = res['data']['token'] as String?;
              if (fetchedToken != null) {
                await prefs.setString(_tokenKey, fetchedToken);
                ApiClient.authToken = fetchedToken;
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_sessionExpiry);
    final sessionStr = prefs.getString(_sessionKey);
    if (expiryStr == null || sessionStr == null) return false;
    await _restoreToken(prefs);
    if (expiryStr == 'never') return true;
    final expiry = DateTime.parse(expiryStr);
    return DateTime.now().isBefore(expiry);
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString(_sessionKey);
    if (sessionStr == null) return null;
    final valid = await isSessionValid();
    if (!valid) return null;
    await _restoreToken(prefs);
    return UserModel.fromMap(jsonDecode(sessionStr));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionExpiry);
    await prefs.remove(_tokenKey);
    ApiClient.authToken = null;
  }

  /// Refresh session (reset 1hr timer)
  static Future<void> refreshSession() async {
    final user = await getCurrentUser();
    if (user != null) await saveSession(user);
  }
}
