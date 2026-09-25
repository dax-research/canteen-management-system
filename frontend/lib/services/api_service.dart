import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['detail'] ?? 'An error occurred. Please try again.');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server.');
      }
      rethrow;
    }
  }

  static Future<dynamic> get(String url, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(
          (responseData is Map && responseData['detail'] != null)
              ? responseData['detail']
              : 'An error occurred. Please try again.',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server.');
      }
      rethrow;
    }
  }
}
