import 'package:flutter/material.dart';
import 'models/user_session.dart';
import 'services/alert_service.dart';
import 'plant_detail_screen.dart';
import 'utils/time_utils.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const primaryColor = Color(0xFF005131);

  static const tertiaryColor = Color(0xFF5B411E);
  static const tertiaryContainerColor = Color(0xFF755833);

  static const primaryContainerColor = Color(0xFF106B44);

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    final userId = UserSession().currentUserId;
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await AlertService.getAlerts(userId);
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    final userId = UserSession().userId ?? 'demo_user';
    await AlertService.markAllAsRead(userId);
    _fetchAlerts();
  }

  Future<void> _handleAlertTap(Map<String, dynamic> alert) async {
    final alertId = alert['alert_id'];
    if (alertId != null && alert['is_read'] != true) {
      await AlertService.markAsRead(alertId);
    }

    final plantId = alert['plant_id'];
    final plantName = alert['plant_name'] ?? 'Chậu cây';
    if (plantId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantDetailScreen(
            plantId: plantId,
            plantName: plantName,
          ),
        ),
      );
    } else {
      _fetchAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? colorScheme.primary : primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: headerColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông Báo Cảnh Báo',
          style: TextStyle(
            color: headerColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: headerColor),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAlerts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh Báo Hệ Thống',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cập nhật tình trạng & sự cố khu vườn theo thời gian thực',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_alerts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('Không có thông báo cảnh báo nào.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _alerts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildAlertCard(_alerts[index]);
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = alert['type'] ?? 'LOW_SOIL_MOISTURE';
    final isRead = alert['is_read'] == true;
    final message = alert['message'] ?? '';
    final plantName = alert['plant_name'] ?? 'Chậu cây';
    final ts = TimeUtils.formatVietnamTime(alert['timestamp']);

    IconData icon = Icons.water_drop;
    Color containerColor = Colors.blue.withValues(alpha: 0.15);
    Color contentColor = Colors.blue;
    Color badgeBg = Colors.blue;
    String badgeText = 'Độ Ẩm';

    if (type.contains('TEMP')) {
      icon = Icons.thermostat;
      containerColor = tertiaryContainerColor.withValues(alpha: 0.15);
      contentColor = tertiaryColor;
      badgeBg = tertiaryContainerColor;
      badgeText = 'Nhiệt Độ';
    } else if (type.contains('NPK') || type.contains('GROWTH')) {
      icon = Icons.eco;
      containerColor = primaryContainerColor.withValues(alpha: 0.15);
      contentColor = primaryColor;
      badgeBg = primaryContainerColor;
      badgeText = 'Dinh Dưỡng';
    }

    return GestureDetector(
      onTap: () => _handleAlertTap(alert),
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? colorScheme.surface : containerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? colorScheme.surfaceContainerHighest : badgeBg.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: contentColor, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  ts,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plantName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}