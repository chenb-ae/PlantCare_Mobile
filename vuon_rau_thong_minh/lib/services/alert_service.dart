import 'api_service.dart';
import 'notification_service.dart';

class AlertService {
  static final Set<String> _notifiedAlertIds = {};

  static Future<List<Map<String, dynamic>>> getAlerts(
    String userId, {
    String? plantId,
    bool unreadOnly = false,
  }) async {
    final Map<String, String> queryParams = {
      'userId': userId,
      'unreadOnly': unreadOnly.toString(),
    };
    if (plantId != null && plantId.isNotEmpty) {
      queryParams['plantId'] = plantId;
    }

    try {
      final response = await ApiService.get('/api/alerts', queryParams: queryParams);
      if (response is List) {
        final alerts = List<Map<String, dynamic>>.from(response);

        // Bắn thông báo đẩy thật sự lên thanh hệ thống của điện thoại với các cảnh báo chưa đọc
        for (final alert in alerts) {
          final alertId = alert['alert_id']?.toString() ?? '';
          final isRead = alert['is_read'] == true;

          if (!isRead && alertId.isNotEmpty && !_notifiedAlertIds.contains(alertId)) {
            _notifiedAlertIds.add(alertId);
            final plantName = alert['plant_name'] ?? 'Chậu cây';
            final message = alert['message'] ?? 'Thông số chậu cây vượt ngưỡng sinh học!';

            NotificationService().showNotification(
              id: alertId.hashCode,
              title: '⚠️ Cảnh báo: $plantName',
              body: message,
              payload: alert['plant_id'],
            );
          }
        }

        return alerts;
      }
    } catch (_) {}
    return [];
  }

  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await ApiService.get('/api/alerts/unread-count', queryParams: {
        'userId': userId,
      });
      if (response is Map<String, dynamic> && response.containsKey('unread_count')) {
        return response['unread_count'] as int;
      }
    } catch (_) {}
    return 0;
  }

  static Future<bool> markAsRead(String alertId) async {
    try {
      await ApiService.patch('/api/alerts/$alertId/read');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> markAllAsRead(String userId) async {
    try {
      await ApiService.patch('/api/alerts/read-all', queryParams: {'userId': userId});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> triggerTestWarning(String userId) async {
    try {
      await ApiService.post('/api/alerts/trigger-test-warning', queryParams: {'userId': userId});
      return true;
    } catch (_) {
      return false;
    }
  }
}
