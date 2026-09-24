import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/utils/session_manager.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String username, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'username': username,
      'password': password,
    });

    if (response is Map && response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final token = data['token'] as String;
      final userData = Map<String, dynamic>.from(data['user']);
      final clientsData = (data['clients'] as List?) ?? [];

      ApiClient.authToken = token;

      // Extract client IDs from clients list
      final clientIds = clientsData.map((c) => c['id'].toString()).toList();
      userData['client_ids'] = clientIds;

      final user = UserModel.fromMap(userData);
      await SessionManager.saveSession(user);
      return user;
    } else {
      final msg = (response is Map && response['error'] != null && response['error']['message'] != null)
          ? response['error']['message'].toString()
          : 'Login failed';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      if (ApiClient.authToken != null) {
        await ApiClient.post('/auth/logout', {});
      }
    } catch (_) {}
    ApiClient.authToken = null;
    ApiClient.currentClientId = null;
    await SessionManager.clearSession();
  }

  Future<UserModel> createUser({
    required String username,
    required String fullName,
    required String password,
    String role = 'user',
    List<String> clientIds = const [],
    Map<String, bool>? privileges,
    String? phone,
    String? email,
  }) async {
    final response = await ApiClient.post('/users', {
      'username': username,
      'display_name': fullName,
      'password': password,
      'role': role,
      'client_ids': clientIds,
      'privileges': privileges,
      'phone': phone,
      'email': email,
    });

    if (response is Map && response['success'] == true && response['data'] != null) {
      final userData = Map<String, dynamic>.from(response['data']);
      return UserModel.fromMap(userData);
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final response = await ApiClient.get('/users');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      return list
          .map((item) => UserModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates) async {
    final response = await ApiClient.put('/users/$userId', updates);
    if (response is Map && response['success'] == true && response['data'] != null) {
      final userData = Map<String, dynamic>.from(response['data']);
      return UserModel.fromMap(userData);
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(String userId) async {
    await ApiClient.delete('/users/$userId');
  }
}
