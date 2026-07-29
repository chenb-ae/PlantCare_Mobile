import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_service.dart';

class UploadService {
  static Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload');
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map<String, dynamic> && body['success'] == true) {
          final String relativeUrl = body['data']['url'];
          if (relativeUrl.startsWith('http')) {
            return relativeUrl;
          }
          return '${ApiConfig.baseUrl}$relativeUrl';
        }
      }
    } catch (_) {}

    // Fallback sang upload Base64 nếu MultipartRequest gặp vấn đề
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final filename = imageFile.path.split(Platform.pathSeparator).last;

      final data = await ApiService.post('/api/upload/base64', body: {
        'image_base64': base64String,
        'filename': filename,
      });

      if (data is Map<String, dynamic> && data.containsKey('url')) {
        final String relativeUrl = data['url'];
        if (relativeUrl.startsWith('http')) {
          return relativeUrl;
        }
        return '${ApiConfig.baseUrl}$relativeUrl';
      }
    } catch (e) {
      throw ApiException('Không thể tải ảnh lên máy chủ: $e');
    }

    throw ApiException('Tải ảnh thất bại');
  }
}
