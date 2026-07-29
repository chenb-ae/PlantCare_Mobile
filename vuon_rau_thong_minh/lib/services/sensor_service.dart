import 'api_service.dart';

class SensorService {
  static Future<List<Map<String, dynamic>>> listSensors({String? userId}) async {
    final Map<String, String> queryParams = {};
    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }
    final response = await ApiService.get('/api/sensors', queryParams: queryParams.isNotEmpty ? queryParams : null);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createSensor({required String name, String? userId, String? code}) async {
    final Map<String, dynamic> body = {'name': name};
    if (userId != null && userId.isNotEmpty) body['user_id'] = userId;
    if (code != null && code.isNotEmpty) body['code'] = code;

    final response = await ApiService.post('/api/sensors', body: body);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }

  static Future<bool> deleteSensor(String sensorId) async {
    try {
      await ApiService.delete('/api/sensors/$sensorId');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLatestReading(String plantId) async {
    try {
      final response = await ApiService.get('/api/sensor-readings/latest/$plantId');
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getSensorHistory(String plantId, {int limit = 50, int? hours}) async {
    final Map<String, String> queryParams = {'limit': limit.toString()};
    if (hours != null) {
      queryParams['hours'] = hours.toString();
    }

    try {
      final response = await ApiService.get('/api/sensor-readings/history/$plantId', queryParams: queryParams);
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (_) {}
    return [];
  }
}
