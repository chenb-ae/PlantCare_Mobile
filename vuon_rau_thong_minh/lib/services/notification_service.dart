import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    await init();
    try {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      bool granted = false;
      if (androidImplementation != null) {
        granted = await androidImplementation.requestNotificationsPermission() ?? false;
      }

      final iosImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }

      return granted;
    } catch (e) {
      debugPrint('Lỗi yêu cầu quyền thông báo OS: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'plant_care_alerts_channel',
      'Cảnh báo Vườn rau Smart Garden',
      channelDescription: 'Thông báo hệ thống khi thông số chậu cây vượt ngưỡng sinh học',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'plant_alert',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Lỗi gửi thông báo hệ thống: $e');
    }
  }
}
