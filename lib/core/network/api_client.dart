import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode = 200,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = AppConstants.defaultLocalApiUrl;
  bool _isDemoMode = false;
  String? _sessionCookie;

  String get baseUrl => _baseUrl;
  bool get isDemoMode => _isDemoMode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(AppConstants.keyApiBaseUrl) ?? AppConstants.defaultLocalApiUrl;
    _isDemoMode = prefs.getBool(AppConstants.keyIsDemoMode) ?? false;
    _sessionCookie = prefs.getString(AppConstants.keyUserSession);
  }

  Future<void> updateBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyApiBaseUrl, _baseUrl);
  }

  Future<void> setDemoMode(bool isDemo) async {
    _isDemoMode = isDemo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsDemoMode, isDemo);
  }

  Future<void> saveSessionCookie(String cookie) async {
    _sessionCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserSession, cookie);
  }

  Future<void> clearSession() async {
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserSession);
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  void _updateCookiesFromResponse(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null && rawCookie.isNotEmpty) {
      // Extract the PHPSESSID or general session cookie
      final parts = rawCookie.split(';');
      if (parts.isNotEmpty) {
        final cookiePart = parts.firstWhere(
          (element) => element.trim().startsWith('PHPSESSID='),
          orElse: () => parts.first,
        );
        saveSessionCookie(cookiePart.trim());
      }
    }
  }

  String _cleanEndpoint(String endpoint) {
    String clean = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    if (!clean.startsWith('/backend/api') && !clean.startsWith('/api')) {
      clean = '/backend/api$clean';
    }
    return '$_baseUrl$clean';
  }

  Future<ApiResponse<dynamic>> get(String endpoint) async {
    if (_isDemoMode) {
      return ApiResponse(success: true, message: 'Demo mode active', data: null);
    }

    try {
      final uri = Uri.parse(_cleanEndpoint(endpoint));
      final response = await http.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 10),
      );
      _updateCookiesFromResponse(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET error on $endpoint: $e');
      return ApiResponse(success: false, message: 'Network error: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    if (_isDemoMode) {
      return ApiResponse(success: true, message: 'Demo mode active', data: null);
    }

    try {
      final uri = Uri.parse(_cleanEndpoint(endpoint));
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      _updateCookiesFromResponse(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST error on $endpoint: $e');
      return ApiResponse(success: false, message: 'Network error: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    if (_isDemoMode) {
      return ApiResponse(success: true, message: 'Demo mode active', data: null);
    }

    try {
      final uri = Uri.parse(_cleanEndpoint(endpoint));
      final response = await http.put(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      _updateCookiesFromResponse(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT error on $endpoint: $e');
      return ApiResponse(success: false, message: 'Network error: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> delete(String endpoint, {Map<String, dynamic>? body}) async {
    if (_isDemoMode) {
      return ApiResponse(success: true, message: 'Demo mode active', data: null);
    }

    try {
      final uri = Uri.parse(_cleanEndpoint(endpoint));
      final response = await http.delete(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      _updateCookiesFromResponse(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE error on $endpoint: $e');
      return ApiResponse(success: false, message: 'Network error: $e', statusCode: 500);
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] == true || decoded['status'] == 'success';
        final message = decoded['message']?.toString() ?? (success ? 'Success' : 'Request failed');
        final data = decoded.containsKey('data') ? decoded['data'] : decoded;
        return ApiResponse(
          success: success,
          message: message,
          data: data,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Response received',
        data: decoded,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to parse server response: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}
