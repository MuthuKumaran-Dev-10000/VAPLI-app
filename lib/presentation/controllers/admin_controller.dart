import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api/api_client.dart';
import '../../data/models/client_model.dart';
import '../../data/models/user_model.dart';

class ClientGroupedUsers {
  final ClientModel client;
  final List<UserModel> users;

  ClientGroupedUsers({required this.client, required this.users});
}

class AdminController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ClientModel> _clients = [];
  List<ClientGroupedUsers> _groupedUsers = [];
  List<UserModel> _allUsers = [];
  ClientModel? _selectedClient;

  bool _isLoadingClients = false;
  bool _isLoadingUsers = false;
  String? _errorMessage;

  List<ClientModel> get clients => _clients;
  List<ClientGroupedUsers> get groupedUsers => _groupedUsers;
  List<UserModel> get allUsers => _allUsers;
  ClientModel? get selectedClient => _selectedClient;

  bool get isLoadingClients => _isLoadingClients;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get errorMessage => _errorMessage;

  void selectClient(ClientModel? client) {
    _selectedClient = client;
    notifyListeners();
  }

  Future<void> loadPublicClients() async {
    _isLoadingClients = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[DEBUG_CLIENTS] Requesting public clients from ${ApiConstants.baseUrl}${ApiConstants.clients}/public');
      final data = await _apiClient.get('${ApiConstants.clients}/public', authRequired: false);
      final List<dynamic> list = data['clients'] ?? [];
      _clients = list.map((e) => ClientModel.fromJson(e)).toList();
      debugPrint('[DEBUG_CLIENTS] Successfully loaded ${_clients.length} public clients: ${_clients.map((c) => c.name).toList()}');
      if (_clients.isNotEmpty && _selectedClient == null) {
        _selectedClient = _clients.first;
      }
    } catch (e) {
      debugPrint('[DEBUG_CLIENTS_ERROR] Failed to load public clients: $e');
      _errorMessage = 'Failed to load public clients: $e';
    }

    _isLoadingClients = false;
    notifyListeners();
  }

  Future<void> loadClients() async {
    _isLoadingClients = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.get(ApiConstants.clients);
      final List<dynamic> list = data['clients'] ?? [];
      _clients = list.map((e) => ClientModel.fromJson(e)).toList();
      if (_clients.isNotEmpty && _selectedClient == null) {
        _selectedClient = _clients.first;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load clients.';
    }

    _isLoadingClients = false;
    notifyListeners();
  }

  Future<bool> createClient(String name, String description) async {
    _errorMessage = null;
    try {
      await _apiClient.post(ApiConstants.clients, {
        'name': name.trim(),
        'description': description.trim(),
      });
      await loadClients();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create client.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateClient(String id, String name, String description) async {
    _errorMessage = null;
    try {
      await _apiClient.patch('${ApiConstants.clients}/$id', {
        'name': name.trim(),
        'description': description.trim(),
      });
      await loadClients();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to update client.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteClient(String id) async {
    _errorMessage = null;
    try {
      await _apiClient.delete('${ApiConstants.clients}/$id');
      await loadClients();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to delete client.';
    }
    notifyListeners();
    return false;
  }

  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.get(ApiConstants.users);

      final List<dynamic> rawAllUsers = data['allUsers'] ?? [];
      _allUsers = rawAllUsers.map((e) => UserModel.fromJson(e)).toList();

      final List<dynamic> rawGrouped = data['groupedByClient'] ?? [];
      _groupedUsers = rawGrouped.map((g) {
        final c = ClientModel.fromJson(g['client']);
        final List<dynamic> uList = g['users'] ?? [];
        final users = uList.map((e) => UserModel.fromJson(e)).toList();
        return ClientGroupedUsers(client: c, users: users);
      }).toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load users.';
    }

    _isLoadingUsers = false;
    notifyListeners();
  }

  Future<bool> createUser({
    required String username,
    required String fullName,
    required String password,
    required String role,
    required List<String> clientIds,
    String? email,
    String? mobile,
    String? address,
    Map<String, bool>? privileges,
  }) async {
    _errorMessage = null;
    try {
      final body = <String, dynamic>{
        'username': username.trim(),
        'fullName': fullName.trim(),
        'password': password,
        'role': role,
        'clientIds': clientIds,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (mobile != null && mobile.isNotEmpty) body['phone'] = mobile;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (privileges != null) body['privileges'] = privileges;

      await _apiClient.post(ApiConstants.users, body);
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create user.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateUser({
    required String id,
    String? fullName,
    String? role,
    String? password,
    Map<String, bool>? privileges,
  }) async {
    _errorMessage = null;
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName.trim();
      if (role != null) body['role'] = role;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (privileges != null) body['privileges'] = privileges;

      await _apiClient.patch('${ApiConstants.users}/$id', body);
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to update user.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteUser(String id) async {
    _errorMessage = null;
    try {
      await _apiClient.delete('${ApiConstants.users}/$id');
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to delete user.';
    }
    notifyListeners();
    return false;
  }
}
