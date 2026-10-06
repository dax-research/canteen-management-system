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

  static Future<dynamic> _processResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await AuthService.clearLocalSession();
      AuthService.onUnauthorized?.call();
    }

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
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Invalid response format from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      String errorMessage = 'An error occurred. Please try again.';
      if (responseData is Map && responseData['detail'] != null) {
        final detail = responseData['detail'];
        if (detail is List) {
          final messages = detail
              .whereType<Map>()
              .map((entry) => entry['msg']?.toString())
              .whereType<String>()
              .where((message) => message.isNotEmpty)
              .toList();
          errorMessage = messages.isEmpty
              ? detail.toString()
              : messages.join('\n');
        } else {
          errorMessage = detail.toString();
        }
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
      return await _processResponse(response);
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
      return await _processResponse(response);
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
      return await _processResponse(response);
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
      return await _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}
