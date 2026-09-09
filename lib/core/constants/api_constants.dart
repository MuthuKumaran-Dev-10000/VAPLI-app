import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL automatically detects platform:
  // - Web / Desktop / iOS: http://localhost:3000/api/v1
  // - Android Emulator: http://10.0.2.2:3000/api/v1 (10.0.2.2 maps to host machine's 127.0.0.1)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Clients
  static const String clients = '/clients';

  // Users
  static const String users = '/users';

  // Audit Logs
  static const String auditLogs = '/audit-logs';
}
