import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/session_manager.dart';
import '../../data/api/api_client.dart';
import '../../data/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
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
        await SessionManager.saveSession(token, _currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      await SessionManager.clearSession();
    }
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String username, String password) async {
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
      await SessionManager.saveSession(token, _currentUser!);

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

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout, {});
    } catch (_) {}
    await SessionManager.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
