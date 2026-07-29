import 'api_service.dart';
import '../models/user_session.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (response is Map<String, dynamic>) {
      UserSession().setUser(
        userId: response['user_id'] ?? '',
        name: response['name'] ?? '',
        email: response['email'] ?? '',
        createdAt: response['created_at'],
      );
      return response;
    }
    throw ApiException('Dữ liệu đăng nhập không hợp lệ');
  }

  static Future<Map<String, dynamic>> googleAuth(String name, String email, {String? googleId, String? avatarUrl}) async {
    final response = await ApiService.post('/api/auth/google', body: {
      'name': name,
      'email': email,
      'google_id': googleId,
      'avatar_url': avatarUrl,
    });

    if (response is Map<String, dynamic>) {
      UserSession().setUser(
        userId: response['user_id'] ?? '',
        name: response['name'] ?? '',
        email: response['email'] ?? '',
        createdAt: response['created_at'],
      );
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        UserSession().avatarPath = avatarUrl;
      }
      return response;
    }
    throw ApiException('Dữ liệu đăng nhập Google không hợp lệ');
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await ApiService.post('/api/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });

    if (response is Map<String, dynamic>) {
      UserSession().setUser(
        userId: response['user_id'] ?? '',
        name: response['name'] ?? '',
        email: response['email'] ?? '',
        createdAt: response['created_at'],
      );
      return response;
    }
    throw ApiException('Dữ liệu đăng ký không hợp lệ');
  }

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await ApiService.get('/api/auth/profile/$userId');
    if (response is Map<String, dynamic>) {
      UserSession().setUser(
        userId: response['user_id'] ?? userId,
        name: response['name'] ?? UserSession().name ?? '',
        email: response['email'] ?? UserSession().email ?? '',
        createdAt: response['created_at'],
      );
      return response;
    }
    throw ApiException('Không thể lấy thông tin hồ sơ');
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, String name) async {
    final response = await ApiService.put('/api/auth/profile/$userId', body: {
      'name': name,
    });
    if (response is Map<String, dynamic>) {
      UserSession().name = response['name'] ?? name;
      return response;
    }
    throw ApiException('Cập nhật hồ sơ thất bại');
  }

  static Future<void> changePassword(String userId, String oldPassword, String newPassword) async {
    await ApiService.post('/api/auth/change-password', body: {
      'user_id': userId,
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
