import 'package:flutter/material.dart';
import 'add_care_log_screen.dart';
import 'sensor_history_screen.dart';
import 'care_log_list_screen.dart';
import 'services/plant_service.dart';
import 'services/sensor_service.dart';
import 'services/log_service.dart';
import 'utils/time_utils.dart';
import 'utils/app_snackbar.dart';

class PlantDetailScreen extends StatefulWidget {
  final String? plantId;
  final String plantName;
  final bool showSensorCards;
  final bool isHarvested;

  const PlantDetailScreen({
    super.key,
    this.plantId,
    this.plantName = 'Chậu Cải Thìa F1',
    this.showSensorCards = true,
    this.isHarvested = false,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const primaryColor = Color(0xFF005131);
  static const primaryContainer = Color(0xFF106B44);
  static const onPrimaryContainer = Color(0xFF96E9B7);
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(context).colorScheme.surface;
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceVariant = Color(0xFFE1E3E4);
  Color get textColor => Theme.of(context).colorScheme.onSurface;
  Color get subTextColor => Theme.of(context).colorScheme.onSurfaceVariant;
  static const errorColor = Color(0xFFBA1A1A);
  static const tertiaryColor = Color(0xFF755833);

  Map<String, dynamic>? _plantData;
  Map<String, dynamic>? _latestSensor;
  List<Map<String, dynamic>> _sensorHistory = [];
  List<Map<String, dynamic>> _careLogs = [];
  bool _isLoading = true;
  bool get isPlantHarvested => widget.isHarvested || _plantData?['status'] == 'harvested';

  @override
  void initState() {
    super.initState();
    _fetchDetailData();
  }

  Future<void> _fetchDetailData() async {
    if (widget.plantId == null || widget.plantId!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plantDetail = await PlantService.getPlantDetail(widget.plantId!);
      if (mounted) setState(() => _plantData = plantDetail);
    } catch (e) {
      debugPrint('Lỗi tải thông tin cây: $e');
    }

    try {
      final latest = await SensorService.getLatestReading(widget.plantId!);
      if (mounted) setState(() => _latestSensor = latest);
    } catch (e) {
      debugPrint('Lỗi tải chỉ số cảm biến mới nhất: $e');
    }

    try {
      final history = await SensorService.getSensorHistory(widget.plantId!, limit: 10);
      if (mounted) setState(() => _sensorHistory = history);
    } catch (e) {
      debugPrint('Lỗi tải lịch sử cảm biến: $e');
    }

    try {
      final logs = await LogService.getCareLogs(widget.plantId!, limit: 5);
      if (mounted) setState(() => _careLogs = logs);
    } catch (e) {
      debugPrint('Lỗi tải nhật ký chăm sóc: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeletePlant() async {
    if (widget.plantId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa chậu cây "${widget.plantName}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PlantService.deletePlant(widget.plantId!);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Đã xóa kế hoạch trồng cây!');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? colorScheme.primary : primaryColor;
    final displayName = _plantData?['name'] ?? widget.plantName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: headerColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          displayName,
          style: TextStyle(
            color: headerColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (widget.plantId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: headerColor),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeletePlant();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa cây này', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDetailData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(),
                    const SizedBox(height: 12),
                    _buildPlantInfoCard(),
                    const SizedBox(height: 16),
                    if (widget.showSensorCards && !isPlantHarvested) ...[
                      _buildBentoSensorGrid(),
                      const SizedBox(height: 16),
                    ],
                    _buildSensorOverviewChart(),
                    const SizedBox(height: 16),
                    _buildCareLogSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroImage() {
    final imageUrl = _plantData?['image_url'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCDrmAXPOkvZUvhcppmu3EiTauOGNmtIAWIS6hUl06e_0i5NFQRmlhJ18aochL1BRROvWKMNQaOoQ9YpXP09raGG3QDqdz3y8JFI-zT7eO1I97apXkl3YDBOda0ATUo6IKlbWCptvW_7IQRGz5FOovUVzuAvJx_YmKTIFAKElADD_Qvdaz0TbvJSf_ZxEf3-YgN4tE5elSDyQmVR_lFedcKlnJ0IIge8O3MeCIoppPx86SkBzXEvdk';
    final name = _plantData?['name'] ?? widget.plantName;
    final typeLabel = _plantData?['type_label'] ?? _plantData?['type'] ?? 'Rau ăn lá';
    final statusText = isPlantHarvested ? 'Đã thu hoạch' : 'Đang phát triển';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: surfaceContainerLow,
              child: const Icon(Icons.grass, size: 50, color: Colors.grey),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryContainer.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, color: onPrimaryContainer, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.grass, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Loại cây: $typeLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfoCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeLabel = _plantData?['type_label'] ?? _plantData?['type'] ?? 'Rau màu';
    final placementLabel = _plantData?['placement_label'] ??
        (_plantData?['placement'] == 'shaded' ? 'Trong nhà / Che mát' : 'Ngoài trời (Phơi nắng)');
    final plantedAt = _plantData?['planted_at'] ?? 'Mới gieo trồng';
    final formattedDate = TimeUtils.formatDateOnly(plantedAt);
    final sensorName = isPlantHarvested ? 'Đã ngắt kết nối' : (_plantData?['sensor_name'] ?? 'Cảm biến mặc định');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Thông tin chi tiết chậu cây',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoSpecTile(
                  icon: Icons.eco,
                  label: 'Loại cây',
                  value: typeLabel,
                  iconColor: Colors.green,
                ),
              ),
              Expanded(
                child: _buildInfoSpecTile(
                  icon: _plantData?['placement'] == 'shaded' ? Icons.home : Icons.wb_sunny,
                  label: 'Vị trí đặt',
                  value: placementLabel,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoSpecTile(
                  icon: Icons.calendar_today,
                  label: 'Ngày gieo trồng',
                  value: formattedDate,
                  iconColor: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildInfoSpecTile(
                  icon: Icons.sensors,
                  label: 'Thiết bị cảm biến',
                  value: sensorName,
                  iconColor: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSpecTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoSensorGrid() {
    final temp = _latestSensor?['temperature'] ?? 28.5;
    final soilHumidity = _latestSensor?['soil_humidity'] ?? 58.0;

    String npkText = 'N: 50 | P: 30 | K: 40 mg/kg';
    double npkTotal = 120.0;
    if (_latestSensor != null && _latestSensor!['npk'] is Map) {
      final npk = _latestSensor!['npk'] as Map;
      final n = (npk['n'] as num?)?.toDouble() ?? 0.0;
      final p = (npk['p'] as num?)?.toDouble() ?? 0.0;
      final k = (npk['k'] as num?)?.toDouble() ?? 0.0;
      npkText = 'N: ${n.toStringAsFixed(0)} | P: ${p.toStringAsFixed(0)} | K: ${k.toStringAsFixed(0)}';
      npkTotal = n + p + k;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                title: 'Nhiệt độ',
                value: '${temp.toStringAsFixed(1)}°C',
                icon: Icons.thermostat,
                iconColor: errorColor,
                progressColor: errorColor,
                progressValue: (temp / 45.0).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                title: 'Dinh dưỡng NPK',
                value: npkText,
                icon: Icons.science,
                iconColor: subTextColor,
                progressColor: subTextColor,
                progressValue: (npkTotal / 300.0).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          title: 'Độ ẩm đất',
          value: '${soilHumidity.toStringAsFixed(0)}%',
          icon: Icons.grass,
          iconColor: tertiaryColor,
          progressColor: tertiaryColor,
          progressValue: (soilHumidity / 100.0).clamp(0.0, 1.0),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color progressColor,
    required double progressValue,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryContainer.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: surfaceVariant,
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorOverviewChart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryContainer.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng quan cảm biến',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: _sensorHistory.isEmpty
                ? Center(child: Text('Chưa có dữ liệu lịch sử', style: TextStyle(color: subTextColor)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _sensorHistory.take(5).toList().reversed.map((item) {
                      final temp = (item['temperature'] as num?)?.toDouble() ?? 25.0;
                      final humidity = (item['soil_humidity'] as num?)?.toDouble() ?? 50.0;
                      final ts = TimeUtils.formatShortTime(item['timestamp']);

                      return _buildChartGroup(
                        (temp / 45.0).clamp(0.1, 1.0),
                        (humidity / 100.0).clamp(0.1, 1.0),
                        0.5,
                        label: ts,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          const Divider(color: surfaceVariant),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorHistoryScreen(
                      plantId: widget.plantId,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.history, color: colorScheme.primary, size: 18),
              label: Text(
                'Xem lịch sử chi tiết',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartGroup(double h1, double h2, double h3, {required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(h1, errorColor),
            const SizedBox(width: 4),
            _buildBar(h2, onPrimaryContainer),
            const SizedBox(width: 4),
            _buildBar(h3, tertiaryColor),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBar(double heightFactor, Color color) {
    return Container(
      width: 6,
      height: 80 * heightFactor,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  Widget _buildCareLogSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final displayLogs = _careLogs.take(2).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CareLogListScreen(
              plantId: widget.plantId,
              plantName: _plantData?['name'] ?? widget.plantName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: surfaceVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: primaryContainer.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nhật ký chăm sóc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                if (!isPlantHarvested)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      foregroundColor: isDark ? colorScheme.onPrimaryContainer : colorScheme.primary,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCareLogScreen(
                            plantId: widget.plantId,
                            plantName: _plantData?['name'] ?? widget.plantName,
                            placement: _plantData?['placement'],
                          ),
                        ),
                      );
                      if (result == true || result != null) {
                        _fetchDetailData();
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (displayLogs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Chưa có nhật ký chăm sóc.', style: TextStyle(color: subTextColor)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayLogs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = displayLogs[index];
                  final action = log['action'] ?? '';
                  final isWater = action == 'watering';
                  final title = action == 'watering'
                      ? 'Tưới nước'
                      : action == 'fertilizing'
                          ? 'Bón phân'
                          : action == 'shade_covering'
                              ? 'Che mát'
                              : action == 'sun_exposure'
                                  ? 'Đưa ra nắng'
                                  : action == 'harvesting'
                                      ? 'Thu hoạch'
                                      : action;

                  final ts = TimeUtils.formatVietnamTime(log['timestamp']);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWater ? Icons.water_drop : Icons.eco,
                            color: isDark ? colorScheme.onPrimaryContainer : primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    ts,
                                    style: TextStyle(fontSize: 11, color: subTextColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['notes'] ?? '',
                                style: TextStyle(fontSize: 13, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            const Divider(color: surfaceVariant),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, color: isDark ? colorScheme.primary : primaryColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Xem tất cả nhật ký',
                    style: TextStyle(color: isDark ? colorScheme.primary : primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: isDark ? colorScheme.primary : primaryColor, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}