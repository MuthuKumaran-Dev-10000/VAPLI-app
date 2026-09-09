import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'vapli_auth_token';
  static const String _keyUser = 'vapli_auth_user';

  static Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
