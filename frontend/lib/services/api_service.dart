import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _processResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
    }

    dynamic responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw Exception('Invalid response format from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      String errorMessage = 'An error occurred. Please try again.';
      if (responseData is Map && responseData['detail'] != null) {
        errorMessage = responseData['detail'].toString();
      } else if (response.statusCode == 401) {
        errorMessage = 'Unauthorized. Please login again.';
      }
      throw Exception(errorMessage);
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> get(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: await _getHeaders());
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> delete(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}
