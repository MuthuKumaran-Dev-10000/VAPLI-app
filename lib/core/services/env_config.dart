import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl => _optional('API_BASE_URL', fallback: 'http://192.168.1.7:8081/api/v1');
  static String get cloudinaryCloudName => _optional('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryApiKey => _optional('CLOUDINARY_API_KEY');
  static String get cloudinaryApiSecret => _optional('CLOUDINARY_API_SECRET');

  static String _optional(String key, {String fallback = ''}) {
    final value = dotenv.env[key]?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }
}
