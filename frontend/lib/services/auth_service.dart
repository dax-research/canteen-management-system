import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'auth_role';
  static const String _userKey = 'auth_user';
  static VoidCallback? onUnauthorized;

  // Login
  static Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      final token = response['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        // Cache the role so a restart still knows whether this is an admin.
        final user = response['user'];
        final role = user is Map
            ? user['role']?.toString()
            : response['role']?.toString();
        if (role != null) {
          await prefs.setString(_roleKey, role);
        }
        if (user is Map) {
          await prefs.setString(
            _userKey,
            jsonEncode(User.fromJson(user.cast<String, dynamic>()).toJson()),
          );
        } else if (response is Map && response['id'] != null) {
          await prefs.setString(
            _userKey,
            jsonEncode(User.fromJson(response.cast<String, dynamic>()).toJson()),
          );
        } else {
          await prefs.remove(_userKey);
        }

        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// The role cached at the last successful login, or null if unknown.
  static Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_userKey);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Cached user data is invalid.');
    }
    return User.fromJson(decoded.cast<String, dynamic>());
  }

  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userKey);
  }

  // Register
  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      await ApiService.post(ApiConstants.register, {
        'name': name,
        'email': email,
        'password': password,
      });
      return true; // Registration successful, now they can login
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      // Call logout API optionally
      await ApiService.post(ApiConstants.logout, {});
    } catch (e) {
      // Ignore API errors on logout, proceed to clear local state
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_userKey);
    }
  }

  // Check Auth State
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
