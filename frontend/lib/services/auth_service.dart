import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

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
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Register
  static Future<bool> register(String name, String email, String password) async {
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
    }
  }

  // Check Auth State
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}
