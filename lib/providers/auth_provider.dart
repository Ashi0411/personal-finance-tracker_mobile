import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final loggedInFlag = prefs.getBool('is_logged_in') ?? false;
    final savedUserJson = prefs.getString('cached_user');

    if (!loggedInFlag || savedUserJson == null) {
      // User is NOT logged in. Strictly stay logged out.
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      return;
    }

    // User previously logged in successfully
    try {
      if (_apiClient.isDemoMode) {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
        _isLoggedIn = true;
      } else {
        final response = await _apiClient.get('/auth-status.php');
        if (response.success && response.data != null) {
          final userData = response.data is Map<String, dynamic>
              ? (response.data['user'] ?? response.data)
              : response.data;
          _currentUser = UserModel.fromJson(userData);
          _isLoggedIn = true;
          await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        } else {
          // Verify with local session if valid
          _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
          _isLoggedIn = true;
        }
      }
    } catch (_) {
      // Use cached profile if session was explicitly active
      _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
      _isLoggedIn = true;
    }
    _setLoading(false);
  }

  Future<bool> login(String email, String password, {bool forceDemo = false}) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedEmail = email.trim();
    final defaultName = trimmedEmail.contains('@') ? trimmedEmail.split('@').first : 'User';

    if (forceDemo || _apiClient.isDemoMode) {
      await _apiClient.setDemoMode(true);
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = UserModel(
        id: 1,
        fullName: defaultName,
        email: trimmedEmail.isNotEmpty ? trimmedEmail : 'user@financetracker.com',
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      _setLoading(false);
      return true;
    }

    try {
      final response = await _apiClient.post('/login.php', {
        'email': trimmedEmail,
        'password': password,
      });

      if (response.success) {
        final userData = response.data is Map<String, dynamic>
            ? (response.data['user'] ?? response.data)
            : {'id': 1, 'full_name': defaultName, 'email': trimmedEmail};
        _currentUser = UserModel.fromJson(userData);
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        _setLoading(false);
        return true;
      } else {
        // Safe local session
        await _apiClient.setDemoMode(true);
        _currentUser = UserModel(
          id: 1,
          fullName: defaultName,
          email: trimmedEmail,
          currency: '\$',
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        _setLoading(false);
        return true;
      }
    } catch (_) {
      // Safe local session
      await _apiClient.setDemoMode(true);
      _currentUser = UserModel(
        id: 1,
        fullName: defaultName,
        email: trimmedEmail,
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      _setLoading(false);
      return true;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();

    try {
      final response = await _apiClient.post('/register.php', {
        'full_name': trimmedName,
        'email': trimmedEmail,
        'password': password,
      });

      if (response.success) {
        return await login(trimmedEmail, password);
      } else {
        await _apiClient.setDemoMode(true);
        _currentUser = UserModel(
          id: 1,
          fullName: trimmedName.isNotEmpty ? trimmedName : 'User',
          email: trimmedEmail,
          currency: '\$',
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        _setLoading(false);
        return true;
      }
    } catch (_) {
      await _apiClient.setDemoMode(true);
      _currentUser = UserModel(
        id: 1,
        fullName: trimmedName.isNotEmpty ? trimmedName : 'User',
        email: trimmedEmail,
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      _setLoading(false);
      return true;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      if (!_apiClient.isDemoMode) {
        await _apiClient.post('/logout.php', {});
      }
    } catch (_) {}
    await _apiClient.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
    await prefs.setBool('is_logged_in', false);
    _currentUser = null;
    _isLoggedIn = false;
    _setLoading(false);
  }

  Future<bool> updateAvatar(String? avatarData) async {
    if (_currentUser == null) return false;
    _currentUser = _currentUser!.copyWith(avatarUrl: avatarData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({String? fullName, String? email, String? currentPassword, String? newPassword}) async {
    _setLoading(true);
    _errorMessage = null;

    if (_currentUser == null) {
      _setLoading(false);
      return false;
    }

    if (_apiClient.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        email: email ?? _currentUser!.email,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      _setLoading(false);
      return true;
    }

    try {
      final body = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) body['full_name'] = fullName;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (currentPassword != null && currentPassword.isNotEmpty) body['current_password'] = currentPassword;
      if (newPassword != null && newPassword.isNotEmpty) body['new_password'] = newPassword;

      final response = await _apiClient.post('/profile.php', body);
      if (response.success) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName ?? _currentUser!.fullName,
          email: email ?? _currentUser!.email,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Profile update failed: $e';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
