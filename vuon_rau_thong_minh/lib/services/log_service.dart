import 'api_service.dart';

class LogService {
  static Future<List<Map<String, dynamic>>> getCareLogs(String plantId, {int limit = 50}) async {
    try {
      final response = await ApiService.get('/api/logs', queryParams: {
        'plantId': plantId,
        'limit': limit.toString(),
      });
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createCareLog({
    required String plantId,
    required String action,
    String? notes,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'plant_id': plantId,
      'action': action,
      'notes': notes ?? '',
    };
    if (imageUrl != null) {
      body['image_url'] = imageUrl;
    }

    final response = await ApiService.post('/api/logs', body: body);

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Thêm nhật ký thất bại');
  }
}
