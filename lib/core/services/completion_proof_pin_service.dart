import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';

/// Optional admin PIN to complete a task without verification photos.
class CompletionProofPinService {
  static String? _cachedPin;
  static bool _loaded = false;

  static Future<void> refresh() async {
    _loaded = false;
    await configuredPin();
  }

  static Future<String?> configuredPin() async {
    if (_loaded) return _cachedPin;
    _loaded = true;
    _cachedPin = null;

    final fromEnv = dotenv.env['TASK_COMPLETION_PIN']?.trim() ?? '';
    if (fromEnv.isNotEmpty) {
      _cachedPin = fromEnv;
      return _cachedPin;
    }

    try {
      final clientId = await ClientContextService.requireActiveClientId();
      final response = await ApiClient.get('/clients/$clientId/bootstrap');
      if (response is Map && response['success'] == true && response['data'] != null) {
        final settings = response['data']['settings'];
        if (settings is Map) {
          final display = settings['dashboard_display'];
          Map<String, dynamic>? displayMap;
          if (display is Map) {
            displayMap = Map<String, dynamic>.from(display);
          } else if (display is String && display.trim().isNotEmpty) {
            try {
              displayMap = Map<String, dynamic>.from(
                jsonDecode(display) as Map,
              );
            } catch (_) {}
          }
          final pin = displayMap?['completion_proof_pin']?.toString().trim() ??
              displayMap?['task_completion_pin']?.toString().trim() ??
              '';
          if (pin.isNotEmpty) {
            _cachedPin = pin;
          }
        }
      }
    } catch (_) {}

    return _cachedPin;
  }

  static Future<bool> verify(String entered) async {
    final pin = await configuredPin();
    if (pin == null || pin.isEmpty) return false;
    return entered.trim() == pin;
  }
}
