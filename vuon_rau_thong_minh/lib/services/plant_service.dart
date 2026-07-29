import 'api_service.dart';

class PlantService {
  static Future<List<Map<String, dynamic>>> getPlants(String userId, {String status = 'growing'}) async {
    final response = await ApiService.get('/api/plants', queryParams: {
      'userId': userId,
      'status': status,
    });

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getPlantHistory(String userId) async {
    final response = await ApiService.get('/api/plants/history', queryParams: {
      'userId': userId,
    });

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  static Future<Map<String, dynamic>> getPlantDetail(String plantId) async {
    final response = await ApiService.get('/api/plants/$plantId');
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Không tìm thấy chi tiết chậu cây');
  }

  static Future<Map<String, dynamic>> createPlant({
    required String userId,
    required String name,
    required String type,
    String sensorId = 'sensor_01',
    String placement = 'outdoor',
    String? imageUrl,
  }) async {
    final response = await ApiService.post('/api/plants', body: {
      'user_id': userId,
      'name': name,
      'type': type,
      'sensor_id': sensorId,
      'placement': placement,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    });

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Tạo cây mới thất bại');
  }

  static Future<Map<String, dynamic>> updatePlant(
    String plantId, {
    String? name,
    String? sensorId,
    String? placement,
    String? status,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (sensorId != null) body['sensor_id'] = sensorId;
    if (placement != null) body['placement'] = placement;
    if (status != null) body['status'] = status;
    if (imageUrl != null) body['image_url'] = imageUrl;

    final response = await ApiService.patch('/api/plants/$plantId', body: body);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Cập nhật cây thất bại');
  }

  static Future<bool> deletePlant(String plantId) async {
    await ApiService.delete('/api/plants/$plantId');
    return true;
  }
}
