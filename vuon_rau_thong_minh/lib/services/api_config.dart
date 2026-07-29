import 'package:flutter/foundation.dart';

class ApiConfig {
  // 🟢 Đổi thành true khi muốn dùng API online trên Vercel, false khi test local
  static const bool useLiveApi = false;

  // Lấy IP được truyền qua lệnh --dart-define=API_BASE_URL=...
  static const String _envApiUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    // Nếu có truyền --dart-define=API_BASE_URL thì ưu tiên hàng đầu!
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }

    if (useLiveApi) {
      return "https://plant-care-fastapi.vercel.app";
    }

    // Nếu chạy trên Web / Desktop -> localhost
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    // Nếu chạy trên Máy ảo Android Emulator -> 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000";
    }
    return "http://localhost:8000";
  }
}

