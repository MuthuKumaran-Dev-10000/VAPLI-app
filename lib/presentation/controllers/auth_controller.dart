import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/database_mode_service.dart';
import '../../core/utils/session_manager.dart';
import '../../data/api/api_client.dart';
import '../../data/models/client_model.dart';
import '../../data/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  ClientModel? _activeClient;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  ClientModel? get activeClient => _activeClient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = await _apiClient.get(ApiConstants.me);
      if (data != null && data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
        
        // Restore active client from session or resolve default
        _activeClient = await SessionManager.getActiveClient();
        if (_activeClient == null) {
          await _autoResolveAndSetClient();
        }

        await SessionManager.saveSession(token, _currentUser!, activeClient: _activeClient);
        await DatabaseModeService.init();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthController] checkSession error: $e');
      await SessionManager.clearSession();
    }
    _currentUser = null;
    _activeClient = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String username, String password, {ClientModel? selectedClient}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.post(
        ApiConstants.login,
        {'username': username.trim(), 'password': password},
        authRequired: false,
      );

      final token = data['token']?.toString() ?? '';
      _currentUser = UserModel.fromJson(data['user']);

      // Determine active client
      if (selectedClient != null) {
        _activeClient = selectedClient;
      } else if (data['client'] != null) {
        _activeClient = ClientModel.fromJson(data['client']);
      } else {
        await _autoResolveAndSetClient();
      }

      await SessionManager.saveSession(token, _currentUser!, activeClient: _activeClient);
      await DatabaseModeService.init();

      debugPrint('[AuthController] Login successful for ${_currentUser!.username}. Active client: ${_activeClient?.name}');

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _autoResolveAndSetClient() async {
    try {
      final res = await _apiClient.get('${ApiConstants.clients}/public', authRequired: false);
      final List<dynamic> list = res is List ? res : (res is Map ? (res['clients'] ?? []) : []);
      final clients = list.map((e) => ClientModel.fromJson(e)).toList();

      if (clients.isNotEmpty) {
        if (_currentUser != null && _currentUser!.clientIds.isNotEmpty) {
          final matched = clients.firstWhere(
            (c) => _currentUser!.clientIds.contains(c.id),
            orElse: () => clients.first,
          );
          _activeClient = matched;
        } else {
          _activeClient = clients.first;
        }
      }
    } catch (e) {
      debugPrint('[AuthController] Auto resolve client error: $e');
    }
  }

  Future<void> setActiveClient(ClientModel client) async {
    _activeClient = client;
    await SessionManager.saveActiveClient(client);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout, {});
    } catch (_) {}
    await SessionManager.clearSession();
    _currentUser = null;
    _activeClient = null;
    notifyListeners();
  }
}
