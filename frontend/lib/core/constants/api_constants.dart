import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // If running on Android emulator, use 10.0.2.2. Otherwise use localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';
  
  static String get categories => '$baseUrl/categories';
  static String get foodItems => '$baseUrl/food-items';
}
