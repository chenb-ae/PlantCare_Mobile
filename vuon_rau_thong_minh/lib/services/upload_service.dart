import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_service.dart';

class UploadService {
  static Future<String> uploadImage(File imageFile) async {
    // 1. Thử upload multipart form-data tới server
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload');
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 8));
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

    // 2. Thử upload dạng Base64 tới server
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final filename = imageFile.path.split(Platform.pathSeparator).last;

      final data = await ApiService.post('/api/upload/base64', body: {
        'image_base64': base64String,
        'filename': filename,
      }).timeout(const Duration(seconds: 8));

      if (data is Map<String, dynamic> && data.containsKey('url')) {
        final String relativeUrl = data['url'];
        if (relativeUrl.startsWith('http')) {
          return relativeUrl;
        }
        return '${ApiConfig.baseUrl}$relativeUrl';
      }
    } catch (_) {}

    // 3. Fallback an toàn tuyệt đối: Chuyển ảnh thành Data URI dạng Base64
    // Đảm bảo chọn ảnh xong 100% LUÔN HIỂN THỊ ĐƯỢC dù offline hay không kết nối được server upload!
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final isPng = imageFile.path.toLowerCase().endsWith('.png');
      final mimeType = isPng ? 'image/png' : 'image/jpeg';
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      throw ApiException('Không thể đọc file ảnh: $e');
    }
  }
}
