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

  static const String _usersRegistryKey = 'registered_users_registry_v1';

  String _getUserAvatarKey(String email) => 'user_avatar_${email.toLowerCase().trim()}';

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    await _loadSavedAccounts();

    final prefs = await SharedPreferences.getInstance();
    final loggedInFlag = prefs.getBool('is_logged_in') ?? false;
    final savedUserJson = prefs.getString('cached_user');

    if (!loggedInFlag || savedUserJson == null) {
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      return;
    }

    try {
      if (_apiClient.isDemoMode) {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
        final userAvatar = prefs.getString(_getUserAvatarKey(_currentUser!.email));
        if (userAvatar != null && userAvatar.isNotEmpty) {
          _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
        } else {
          _currentUser = _currentUser!.copyWith(avatarUrl: null);
        }
        _isLoggedIn = true;
      } else {
        final response = await _apiClient.get('/auth-status.php');
        if (response.success && response.data != null) {
          final userData = response.data is Map<String, dynamic>
              ? (response.data['user'] ?? response.data)
              : response.data;
          _currentUser = UserModel.fromJson(userData);
          final userAvatar = prefs.getString(_getUserAvatarKey(_currentUser!.email));
          if (userAvatar != null && userAvatar.isNotEmpty) {
            _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
          }
          _isLoggedIn = true;
          await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        } else {
          _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
          final userAvatar = prefs.getString(_getUserAvatarKey(_currentUser!.email));
          if (userAvatar != null && userAvatar.isNotEmpty) {
            _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
          }
          _isLoggedIn = true;
        }
      }
    } catch (_) {
      _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
      final userAvatar = prefs.getString(_getUserAvatarKey(_currentUser!.email));
      if (userAvatar != null && userAvatar.isNotEmpty) {
        _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
      }
      _isLoggedIn = true;
    }

    if (_currentUser != null) {
      await _saveAccountToDevice(_currentUser!);
    }

    _setLoading(false);
  }

  Future<Map<String, Map<String, dynamic>>> _loadRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_usersRegistryKey);
    Map<String, Map<String, dynamic>> users = {};

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            users[key.toLowerCase()] = value;
          }
        });
      } catch (_) {}
    }

    // Ensure built-in demo account exists
    if (!users.containsKey('demo@financetracker.com')) {
      users['demo@financetracker.com'] = {
        'id': 1,
        'fullName': 'Demo User',
        'email': 'demo@financetracker.com',
        'password': 'demo123',
        'isDemo': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    return users;
  }

  Future<void> _saveRegisteredUsers(Map<String, Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static const String _usersKey = _usersRegistryKey;

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

    final prefs = await SharedPreferences.getInstance();
    final userAvatar = prefs.getString(_getUserAvatarKey(account.email));

    if (account.userJson != null) {
      try {
        final userMap = jsonDecode(account.userJson!);
        _currentUser = UserModel.fromJson(userMap).copyWith(avatarUrl: userAvatar);
      } catch (_) {
        _currentUser = UserModel(
          id: account.id,
          fullName: account.fullName,
          email: account.email,
          avatarUrl: userAvatar,
          currency: account.currency,
          createdAt: DateTime.now(),
        );
      }
    } else {
      _currentUser = UserModel(
        id: account.id,
        fullName: account.fullName,
        email: account.email,
        avatarUrl: userAvatar,
        currency: account.currency,
        createdAt: DateTime.now(),
      );
    }

    _isLoggedIn = true;
    await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
    await prefs.setBool('is_logged_in', true);

    await _saveAccountToDevice(_currentUser!);
    _setLoading(false);
    return true;
  }

  Future<bool> removeSavedAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.toLowerCase().trim();
    _savedAccounts.removeWhere((a) => a.email.toLowerCase() == normalized);
    final accountsJson = jsonEncode(_savedAccounts.map((a) => a.toJson()).toList());
    await prefs.setString('saved_accounts_list', accountsJson);
    await prefs.remove(_getUserAvatarKey(normalized));

    // If removing currently logged in user
    if (_currentUser != null && _currentUser!.email.toLowerCase() == normalized) {
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

    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPass = password.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      _setLoading(false);
      return false;
    }

    if (trimmedPass.isEmpty && !forceDemo) {
      _errorMessage = 'Please enter your password.';
      _setLoading(false);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final userAvatar = prefs.getString(_getUserAvatarKey(trimmedEmail));

    // 1. If Online Backend is Available, attempt API login
    if (!_apiClient.isDemoMode && !forceDemo) {
      try {
        final response = await _apiClient.post('/login.php', {
          'email': trimmedEmail,
          'password': trimmedPass,
        });

        if (response.success && response.data != null) {
          final userData = response.data is Map<String, dynamic>
              ? (response.data['user'] ?? response.data)
              : {'id': 1, 'full_name': trimmedEmail.split('@').first, 'email': trimmedEmail};
          _currentUser = UserModel.fromJson(userData);
          if (userAvatar != null) {
            _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
          }
          _isLoggedIn = true;
          await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
          await prefs.setBool('is_logged_in', true);
          await _saveAccountToDevice(_currentUser!);
          _setLoading(false);
          return true;
        }
      } catch (_) {}
    }

    // 2. Offline / Local User Account Registry Validation
    final usersMap = await _loadRegisteredUsers();

    if (forceDemo || trimmedEmail == 'demo@financetracker.com') {
      await _apiClient.setDemoMode(true);
      _currentUser = UserModel(
        id: 1,
        fullName: 'Demo User',
        email: 'demo@financetracker.com',
        avatarUrl: userAvatar,
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

    if (!usersMap.containsKey(trimmedEmail)) {
      _errorMessage = 'Account not found for "$trimmedEmail". Please create an account first.';
      _setLoading(false);
      return false;
    }

    final userRecord = usersMap[trimmedEmail]!;
    final storedPassword = userRecord['password']?.toString() ?? '';

    if (storedPassword.isNotEmpty && storedPassword != trimmedPass) {
      _errorMessage = 'Incorrect password for "$trimmedEmail". Please try again.';
      _setLoading(false);
      return false;
    }

    // Login successful
    await _apiClient.setDemoMode(true);
    _currentUser = UserModel(
      id: userRecord['id'] is int ? userRecord['id'] : (int.tryParse(userRecord['id'].toString()) ?? 100),
      fullName: userRecord['fullName']?.toString() ?? trimmedEmail.split('@').first,
      email: trimmedEmail,
      avatarUrl: userAvatar,
      currency: '\$',
      createdAt: DateTime.tryParse(userRecord['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );

    _isLoggedIn = true;
    await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
    await prefs.setBool('is_logged_in', true);
    await _saveAccountToDevice(_currentUser!);
    _setLoading(false);
    return true;
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPass = password.trim();

    if (trimmedName.length < 2) {
      _errorMessage = 'Please enter a valid full name (at least 2 characters).';
      _setLoading(false);
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      _errorMessage = 'Please enter a valid email address (e.g. name@domain.com).';
      _setLoading(false);
      return false;
    }

    if (trimmedPass.length < 6) {
      _errorMessage = 'Password must be at least 6 characters long.';
      _setLoading(false);
      return false;
    }

    final usersMap = await _loadRegisteredUsers();

    if (usersMap.containsKey(trimmedEmail)) {
      _errorMessage = 'An account with "$trimmedEmail" is already registered. Please log in.';
      _setLoading(false);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    // If online backend is reachable
    if (!_apiClient.isDemoMode) {
      try {
        final response = await _apiClient.post('/register.php', {
          'full_name': trimmedName,
          'email': trimmedEmail,
          'password': trimmedPass,
        });

        if (response.success) {
          return await login(trimmedEmail, trimmedPass);
        }
      } catch (_) {}
    }

    // Register user locally
    final newId = DateTime.now().millisecondsSinceEpoch;
    usersMap[trimmedEmail] = {
      'id': newId,
      'fullName': trimmedName,
      'email': trimmedEmail,
      'password': trimmedPass,
      'isDemo': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _saveRegisteredUsers(usersMap);

    // CRITICAL: New user starts with NO custom avatar (pure initial letters), 0 transactions, 0 goals, 0 budgets!
    await prefs.remove(_getUserAvatarKey(trimmedEmail));
    await prefs.setString('user_transactions_$trimmedEmail', jsonEncode([]));
    await prefs.setString('user_goals_$trimmedEmail', jsonEncode([]));
    await prefs.setString('user_budgets_$trimmedEmail', jsonEncode([]));

    _setLoading(false);
    return true;
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
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserAvatarKey(_currentUser!.email);

    if (avatarData != null && avatarData.isNotEmpty) {
      await prefs.setString(userKey, avatarData);
    } else {
      await prefs.remove(userKey);
    }

    _currentUser = _currentUser!.copyWith(avatarUrl: avatarData);
    await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
    await _saveAccountToDevice(_currentUser!);
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
    final userAvatar = prefs.getString(_getUserAvatarKey(_currentUser!.email));

    if (_apiClient.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        email: email ?? _currentUser!.email,
        avatarUrl: userAvatar,
      );

      final usersMap = await _loadRegisteredUsers();
      final emailKey = _currentUser!.email.toLowerCase();
      if (usersMap.containsKey(emailKey)) {
        usersMap[emailKey]!['fullName'] = _currentUser!.fullName;
        if (newPassword != null && newPassword.trim().isNotEmpty) {
          usersMap[emailKey]!['password'] = newPassword.trim();
        }
        await _saveRegisteredUsers(usersMap);
      }

      await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
      await _saveAccountToDevice(_currentUser!);
      _setLoading(false);
      return true;
    }

    try {
      final response = await _apiClient.put('/profile.php', {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      });

      if (response.success && response.data != null) {
        final userData = response.data is Map<String, dynamic>
            ? (response.data['user'] ?? response.data)
            : response.data;
        _currentUser = UserModel.fromJson(userData);
        if (userAvatar != null) {
          _currentUser = _currentUser!.copyWith(avatarUrl: userAvatar);
        }
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));
        await _saveAccountToDevice(_currentUser!);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to update profile';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
