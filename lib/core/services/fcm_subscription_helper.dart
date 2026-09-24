import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmSubscriptionHelper {
  static Future<void> handleFcmTopicSubscription(String dbKey) async {
    try {
      final topicName = dbKey.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscribed_fcm_topic', topicName);
      debugPrint('[Topic Helper] Set client topic scope: $topicName');
    } catch (e) {
      debugPrint('[Topic Helper ERROR] Failed to set topic scope: $e');
    }
  }
}
