import 'dart:async';
import 'package:flutter/material.dart';
import 'add_plant_screen.dart';
import 'planting_history_screen.dart';
import 'profile_screen.dart';
import 'plant_detail_screen.dart';
import 'alerts_screen.dart';
import 'models/user_session.dart';
import 'services/plant_service.dart';
import 'services/alert_service.dart';
import 'services/notification_service.dart';
import 'utils/time_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _growingPlants = [];
  bool _isLoading = true;
  int _unreadAlertCount = 0;

  final Color primaryColor = const Color(0xFF005131);
  final Color primaryContainer = const Color(0xFF106B44);
  final Color tertiaryColor = const Color(0xFF5B411E);

  Timer? _alertCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Lặp tự động quét cảnh báo mỗi 15 giây để nổ thông báo hệ thống tự động
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _checkUnreadAlertsBackground();
      }
    });
  }

  @override
  void dispose() {
    _alertCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUnreadAlertsBackground() async {
    final userId = UserSession().currentUserId;
    try {
      final unreadCount = await AlertService.getUnreadCount(userId);
      await AlertService.getAlerts(userId, unreadOnly: true);
      if (mounted && unreadCount != _unreadAlertCount) {
        setState(() {
          _unreadAlertCount = unreadCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDashboardData() async {
    final userId = UserSession().currentUserId;
    setState(() {
      _isLoading = true;
    });

    // Yêu cầu cấp quyền gửi thông báo thật từ hệ điều hành OS (Android / iOS)
    NotificationService().requestPermissions();

    try {
      final plants = await PlantService.getPlants(userId, status: 'growing');
      debugPrint('Dashboard: Loaded ${plants.length} plants for userId=$userId');
      if (mounted) {
        setState(() {
          _growingPlants = plants;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách cây: $e');
    }

    try {
      final unreadCount = await AlertService.getUnreadCount(userId);
      // Tải và phát hiện cảnh báo chưa đọc để đẩy thông báo hệ thống
      await AlertService.getAlerts(userId, unreadOnly: true);

      if (mounted) {
        setState(() {
          _unreadAlertCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông báo: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;
    final headerGreen = isDark ? colorScheme.primary : const Color(0xFF005131);

    final List<Widget> pages = [
      _buildOverviewBody(),
      const PlantingHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: colorScheme.surface,
              elevation: 0,
              centerTitle: false,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco,
                    color: headerGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Khu Vườn Thông Minh',
                    style: TextStyle(
                      color: headerGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: headerGreen,
                        size: 26,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AlertsScreen(),
                          ),
                        );
                        _loadDashboardData();
                      },
                    ),
                    if (_unreadAlertCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_unreadAlertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPlantScreen(),
                  ),
                );
                if (result == true || result != null) {
                  _loadDashboardData();
                }
              },
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryContainer,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _loadDashboardData();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cây Đang Trồng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_growingPlants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn chưa có cây trồng nào.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryContainer,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPlantScreen(),
                          ),
                        );
                        if (result == true || result != null) {
                          _loadDashboardData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm cây mới'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _growingPlants.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final plant = _growingPlants[index];
                  final latestSensor = plant['latest_sensor'];
                  final moistureVal = latestSensor != null ? latestSensor['soil_humidity'] : null;


                  String moistureStatus = 'Chưa có dữ liệu';
                  if (moistureVal != null) {
                    moistureStatus = 'Độ ẩm: $moistureVal%';
                  }

                  String lightStatus = 'Ngoài trời';
                  if (plant['placement'] == 'shaded') {
                    lightStatus = 'Trong nhà / Che mát';
                  }

                  String subtitle = '${plant['type_label'] ?? plant['type']} • Ngày trồng: ${TimeUtils.formatDateOnly(plant['planted_at'])}';

                  return _buildPlantCard(
                    plantId: plant['plant_id'] ?? '',
                    title: plant['name'] ?? 'Chậu cây',
                    subtitle: subtitle,
                    badgeText: plant['sensor_name'] ?? 'Cảm biến',
                    badgeColor: primaryContainer,
                    imageUrl: plant['image_url'] ??
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBiRJpbNWRFGjJ_u-cDjQE5KbHs8z959pdLY5d8ELtWfBzRW-SbPe3sqC4l7P6KnESmPl7XWyk5KEF3X2NO7vn3QsB1kX0Oyuw9oBXMWpJMgf4r_4z6bQ2EQQQuHyvZ0CcN2BTkUVJIET3vu3dFPSRRDbiz4-JdwTA5KBtx5UW5--I4U3TXP5cRPMDtGiXsPPh7GxqiGeZFRsQxsZykv_-w4yFVhgNtRs0AVtZKuyenTchiPi5Kexo',
                    moistureStatus: moistureStatus,
                    lightStatus: lightStatus,
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard({
    required String plantId,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String imageUrl,
    required String moistureStatus,
    required String lightStatus,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final badgeBg = isDark ? const Color(0xFF2C322E) : Colors.white.withValues(alpha: 0.9);
    final badgeTextColor = isDark ? Colors.white : colorScheme.onSurface;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(
              plantId: plantId,
              plantName: title,
            ),
          ),
        );
        _loadDashboardData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF2C322E) : Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.grass, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop, size: 18, color: primaryContainer),
                          const SizedBox(width: 6),
                          Text(moistureStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.wb_sunny, size: 18, color: tertiaryColor),
                          const SizedBox(width: 6),
                          Text(lightStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}