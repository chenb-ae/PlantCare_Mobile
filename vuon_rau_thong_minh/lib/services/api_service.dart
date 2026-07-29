import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static dynamic _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 400) {
        String errorMsg = 'Đã xảy ra lỗi từ hệ thống (${response.statusCode})';
        if (body is Map<String, dynamic>) {
          if (body.containsKey('detail')) {
            errorMsg = body['detail'].toString();
          } else if (body.containsKey('message')) {
            errorMsg = body['message'].toString();
          } else if (body.containsKey('error')) {
            errorMsg = body['error'].toString();
          }
        }
        throw ApiException(errorMsg, statusCode: response.statusCode);
      }

      if (body is Map<String, dynamic> && body.containsKey('success')) {
        final bool success = body['success'] == true;
        if (success) {
          return body['data'];
        } else {
          final errorMsg = body['error'] ?? body['message'] ?? body['detail'] ?? 'Đã xảy ra lỗi từ hệ thống.';
          throw ApiException(errorMsg.toString(), statusCode: response.statusCode);
        }
      }
      return body;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException('Lỗi kết nối máy chủ (${response.statusCode})', statusCode: response.statusCode);
    }
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http
          .put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> patch(String endpoint, {dynamic body, Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối máy chủ: $e');
    }
  }
}
