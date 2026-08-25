import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/saved_account_model.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<SavedAccountModel> _savedAccounts = [];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SavedAccountModel> get savedAccounts => _savedAccounts;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    await _loadSavedAccounts();

    final prefs = await SharedPreferences.getInstance();
    final loggedInFlag = prefs.getBool('is_logged_in') ?? false;
    final savedUserJson = prefs.getString('cached_user');
    final savedAvatar = prefs.getString('user_custom_avatar_base64');

    if (!loggedInFlag || savedUserJson == null) {
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      return;
    }

    try {
      if (_apiClient.isDemoMode) {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
        if (savedAvatar != null) {
          _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
        }
        _isLoggedIn = true;
      } else {
        final response = await _apiClient.get('/auth-status.php');
        if (response.success && response.data != null) {
          final userData = response.data is Map<String, dynamic>
              ? (response.data['user'] ?? response.data)
              : response.data;
          _currentUser = UserModel.fromJson(userData);
          if (savedAvatar != null) {
            _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
          }
          _isLoggedIn = true;
          await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        } else {
          _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
          if (savedAvatar != null) {
            _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
          }
          _isLoggedIn = true;
        }
      }
    } catch (_) {
      _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
      if (savedAvatar != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
      }
      _isLoggedIn = true;
    }

    if (_currentUser != null) {
      await _saveAccountToDevice(_currentUser!);
    }

    _setLoading(false);
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('saved_accounts_list');
      if (accountsJson != null && accountsJson.isNotEmpty) {
        final List decoded = jsonDecode(accountsJson);
        _savedAccounts = decoded.map((item) => SavedAccountModel.fromJson(item)).toList();
      } else {
        _savedAccounts = [];
      }
    } catch (e) {
      _savedAccounts = [];
    }
  }

  Future<void> _saveAccountToDevice(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = _savedAccounts.indexWhere((a) => a.email.toLowerCase() == user.email.toLowerCase());
      
      final updatedAccount = SavedAccountModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        currency: user.currency,
        userJson: jsonEncode(user.toJson()),
        lastActive: DateTime.now(),
      );

      if (index >= 0) {
        _savedAccounts[index] = updatedAccount;
      } else {
        _savedAccounts.add(updatedAccount);
      }

      // Sort with latest active first
      _savedAccounts.sort((a, b) => b.lastActive.compareTo(a.lastActive));

      final accountsJson = jsonEncode(_savedAccounts.map((a) => a.toJson()).toList());
      await prefs.setString('saved_accounts_list', accountsJson);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> switchAccount(String targetEmail) async {
    _setLoading(true);
    await _loadSavedAccounts();
    final account = _savedAccounts.firstWhere(
      (a) => a.email.toLowerCase() == targetEmail.toLowerCase(),
      orElse: () => _savedAccounts.first,
    );

    if (account.userJson != null) {
      try {
        final userMap = jsonDecode(account.userJson!);
        _currentUser = UserModel.fromJson(userMap);
      } catch (_) {
        _currentUser = UserModel(
          id: account.id,
          fullName: account.fullName,
          email: account.email,
          avatarUrl: account.avatarUrl,
          currency: account.currency,
          createdAt: DateTime.now(),
        );
      }
    } else {
      _currentUser = UserModel(
        id: account.id,
        fullName: account.fullName,
        email: account.email,
        avatarUrl: account.avatarUrl,
        currency: account.currency,
        createdAt: DateTime.now(),
      );
    }

    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
    await prefs.setBool('is_logged_in', true);
    if (account.avatarUrl != null) {
      await prefs.setString('user_custom_avatar_base64', account.avatarUrl!);
    }

    await _saveAccountToDevice(_currentUser!);
    _setLoading(false);
    return true;
  }

  Future<bool> removeSavedAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _savedAccounts.removeWhere((a) => a.email.toLowerCase() == email.toLowerCase());
    final accountsJson = jsonEncode(_savedAccounts.map((a) => a.toJson()).toList());
    await prefs.setString('saved_accounts_list', accountsJson);

    // If removing currently logged in user
    if (_currentUser != null && _currentUser!.email.toLowerCase() == email.toLowerCase()) {
      if (_savedAccounts.isNotEmpty) {
        await switchAccount(_savedAccounts.first.email);
      } else {
        await logout();
      }
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<bool> login(String email, String password, {bool forceDemo = false}) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedEmail = email.trim();
    final defaultName = trimmedEmail.contains('@') ? trimmedEmail.split('@').first : 'User';
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('user_custom_avatar_base64');

    if (forceDemo || _apiClient.isDemoMode) {
      await _apiClient.setDemoMode(true);
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = UserModel(
        id: 1,
        fullName: defaultName,
        email: trimmedEmail.isNotEmpty ? trimmedEmail : 'user@financetracker.com',
        avatarUrl: savedAvatar,
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      await _saveAccountToDevice(_currentUser!);
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
        if (savedAvatar != null) {
          _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
        }
        _isLoggedIn = true;
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        await _saveAccountToDevice(_currentUser!);
        _setLoading(false);
        return true;
      } else {
        await _apiClient.setDemoMode(true);
        _currentUser = UserModel(
          id: 1,
          fullName: defaultName,
          email: trimmedEmail,
          avatarUrl: savedAvatar,
          currency: '\$',
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        await _saveAccountToDevice(_currentUser!);
        _setLoading(false);
        return true;
      }
    } catch (_) {
      await _apiClient.setDemoMode(true);
      _currentUser = UserModel(
        id: 1,
        fullName: defaultName,
        email: trimmedEmail,
        avatarUrl: savedAvatar,
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      await _saveAccountToDevice(_currentUser!);
      _setLoading(false);
      return true;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('user_custom_avatar_base64');

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
          avatarUrl: savedAvatar,
          currency: '\$',
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await prefs.setBool('is_logged_in', true);
        await _saveAccountToDevice(_currentUser!);
        _setLoading(false);
        return true;
      }
    } catch (_) {
      await _apiClient.setDemoMode(true);
      _currentUser = UserModel(
        id: 1,
        fullName: trimmedName.isNotEmpty ? trimmedName : 'User',
        email: trimmedEmail,
        avatarUrl: savedAvatar,
        currency: '\$',
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
      await _saveAccountToDevice(_currentUser!);
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
    final prefs = await SharedPreferences.getInstance();
    if (avatarData != null) {
      await prefs.setString('user_custom_avatar_base64', avatarData);
    } else {
      await prefs.remove('user_custom_avatar_base64');
    }

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarUrl: avatarData);
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await _saveAccountToDevice(_currentUser!);
    }
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

    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('user_custom_avatar_base64');

    if (_apiClient.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        email: email ?? _currentUser!.email,
        avatarUrl: savedAvatar ?? _currentUser!.avatarUrl,
      );
      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await _saveAccountToDevice(_currentUser!);
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
          avatarUrl: savedAvatar ?? _currentUser!.avatarUrl,
        );
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await _saveAccountToDevice(_currentUser!);
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
