import 'package:flutter/foundation.dart';
import '../utils/session_manager.dart';

class DatabaseModeService {
  static final ValueNotifier<bool> isDevelopment = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> activeClientId = ValueNotifier<String?>(null);

  static Future<void> init() async {
    final client = await SessionManager.getActiveClient();
    if (client != null) {
      activeClientId.value = client.dbKey.isNotEmpty ? client.dbKey : client.id;
      debugPrint('[DatabaseModeService] Initialized activeClientId: ${activeClientId.value}');
    }
  }

  static String path(String rawPath) {
    return rawPath;
  }
}
