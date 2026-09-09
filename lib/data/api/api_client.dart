import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/session_manager.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders({bool authRequired = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authRequired) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map && jsonBody['success'] == true) {
        return jsonBody['data'];
      }
      return jsonBody;
    }

    if (jsonBody is Map && jsonBody['error'] is Map) {
      final err = jsonBody['error'];
      throw ApiException(
        code: err['code']?.toString() ?? 'ERROR',
        message: err['message']?.toString() ?? 'HTTP ${response.statusCode} error',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      code: 'HTTP_${response.statusCode}',
      message: 'Server returned HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  Future<dynamic> get(String path, {bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body, {bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.patch(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.delete(uri, headers: headers);
    return _handleResponse(response);
  }
}
