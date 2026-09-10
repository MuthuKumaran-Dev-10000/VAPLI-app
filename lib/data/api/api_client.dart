import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

    String errorMsg = 'Server returned HTTP ${response.statusCode}';
    String errorCode = 'HTTP_${response.statusCode}';

    if (jsonBody is Map) {
      if (jsonBody['error'] is Map) {
        errorMsg = jsonBody['error']['message']?.toString() ?? errorMsg;
        errorCode = jsonBody['error']['code']?.toString() ?? errorCode;
      } else if (jsonBody['message'] != null) {
        errorMsg = jsonBody['message'].toString();
      } else if (jsonBody['error'] != null && jsonBody['error'] is String) {
        errorMsg = jsonBody['error'].toString();
      }
    }

    throw ApiException(
      code: errorCode,
      message: errorMsg,
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

  Future<dynamic> delete(String path, {Map<String, dynamic>? body, bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.delete(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    Map<String, String>? fields,
    bool authRequired = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final req = http.MultipartRequest('POST', uri);

    if (authRequired) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (fields != null) {
      req.fields.addAll(fields);
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'png'),
      ),
    );

    final streamedResponse = await _client.send(req);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
