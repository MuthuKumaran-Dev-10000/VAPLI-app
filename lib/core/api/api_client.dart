import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  // =========================================================
  // EDIT THIS LINE TO CHANGE THE VAPLI API SERVER ADDRESS.
  // Mac Localhost / Desktop: http://127.0.0.1:8081/api/v1
  // Android Emulator: http://10.0.2.2:8081/api/v1
  // Physical Android Phone: http://<MAC-LAN-IP>:8081/api/v1
  // =========================================================
  static const String baseUrl = 'http://10.0.2.2:8081/api/v1';

  static String? authToken;
  static String? currentClientId;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        if (currentClientId != null) 'x-client-id': currentClientId!,
      };

  static void _log(String message) {
    final time = DateTime.now().toIso8601String();
    print('[$time] [ApiClient] $message');
  }

  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    _log('GET -> $uri');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, 'GET $endpoint');
    } catch (e) {
      _log('GET Error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    _log('POST -> $uri | Body: ${jsonEncode(body)}');
    try {
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, 'POST $endpoint');
    } catch (e) {
      _log('POST Error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    _log('PUT -> $uri | Body: ${jsonEncode(body)}');
    try {
      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, 'PUT $endpoint');
    } catch (e) {
      _log('PUT Error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    _log('DELETE -> $uri');
    try {
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, 'DELETE $endpoint');
    } catch (e) {
      _log('DELETE Error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<String> uploadFile(File file, {String category = 'general'}) async {
    final uri = Uri.parse('$baseUrl/uploads/$category');
    _log('UPLOAD -> $uri | File: ${file.path} | Category: $category');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (currentClientId != null) {
      request.headers['x-client-id'] = currentClientId!;
    }
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response, 'UPLOAD ${file.path}');
    if (data is Map && data['success'] == true) {
      final url = data['url'] ?? data['secure_url'] ?? (data['data'] is Map ? data['data']['url'] : null);
      if (url != null) return url.toString();
    }
    throw Exception('Upload failed: Invalid response format');
  }

  static Future<String> uploadBytes(List<int> bytes, {required String filename, String category = 'general'}) async {
    final uri = Uri.parse('$baseUrl/uploads/$category');
    _log('UPLOAD BYTES -> $uri | Filename: $filename | Category: $category');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (currentClientId != null) {
      request.headers['x-client-id'] = currentClientId!;
    }
    request.fields['category'] = category;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response, 'UPLOAD BYTES $filename');
    if (data is Map && data['success'] == true) {
      final url = data['url'] ?? data['secure_url'] ?? (data['data'] is Map ? data['data']['url'] : null);
      if (url != null) return url.toString();
    }
    throw Exception('Upload bytes failed: Invalid response format');
  }

  static dynamic _handleResponse(http.Response response, String context) {
    _log('RESPONSE [$context] Status: ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      final json = jsonDecode(response.body);
      return json;
    } else {
      String errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json.containsKey('error')) {
          final err = json['error'];
          errorMessage = err is Map ? (err['message'] ?? errorMessage) : err.toString();
        }
      } catch (_) {}
      _log('API ERROR [$context]: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}
