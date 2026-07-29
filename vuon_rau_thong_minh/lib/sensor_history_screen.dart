import 'package:flutter/material.dart';
import 'services/sensor_service.dart';
import 'utils/time_utils.dart';

class SensorRecord {
  final String time;
  final String date;
  final String temp;
  final String humidity;
  final String npk;

  const SensorRecord({
    required this.time,
    required this.date,
    required this.temp,
    required this.humidity,
    required this.npk,
  });
}

class SensorHistoryScreen extends StatefulWidget {
  final String? plantId;

  const SensorHistoryScreen({
    super.key,
    this.plantId,
  });

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  static const primaryColor = Color(0xFF005131);
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get surfaceContainerLowest => Theme.of(context).colorScheme.surface;
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const surfaceVariant = Color(0xFFE1E3E4);
  static const primaryContainerColor = Color(0xFF106B44);
  static const onPrimaryContainerColor = Color(0xFF96E9B7);
  Color get textColor => Theme.of(context).colorScheme.onSurface;
  Color get subTextColor => Theme.of(context).colorScheme.onSurfaceVariant;
  static const secondaryColor = Color(0xFF56615D);

  bool isTodaySelected = true;
  List<SensorRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSensorHistory();
  }

  Future<void> _fetchSensorHistory() async {
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
      final hours = isTodaySelected ? 24 : 168;
      final history = await SensorService.getSensorHistory(widget.plantId!, hours: hours, limit: 100);

      final records = history.map((item) {
        final tsStr = item['timestamp']?.toString() ?? '';
        final timeStr = TimeUtils.formatShortTime(tsStr);
        final dateStr = TimeUtils.formatDateOnly(tsStr);

        final tempVal = (item['temperature'] as num?)?.toStringAsFixed(1) ?? '--';
        final humVal = (item['soil_humidity'] as num?)?.toStringAsFixed(0) ?? '--';

        String npkStr = '50-30-40';
        if (item['npk'] is Map) {
          final npkMap = item['npk'] as Map;
          final n = (npkMap['n'] as num?)?.toInt() ?? 0;
          final p = (npkMap['p'] as num?)?.toInt() ?? 0;
          final k = (npkMap['k'] as num?)?.toInt() ?? 0;
          npkStr = '$n-$p-$k';
        }

        return SensorRecord(
          time: timeStr,
          date: dateStr,
          temp: '$tempVal°C',
          humidity: '$humVal%',
          npk: npkStr,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _records = records;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? colorScheme.primary : primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: headerColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Lịch Sử Cảm Biến',
          style: TextStyle(
            color: headerColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSegmentedControl(),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_records.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('Chưa có dữ liệu lịch sử cảm biến.', style: TextStyle(color: subTextColor)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildHistoryCard(_records[index]);
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isTodaySelected) {
                  setState(() {
                    isTodaySelected = true;
                  });
                  _fetchSensorHistory();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isTodaySelected ? primaryContainerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hôm Nay',
                  style: TextStyle(
                    color: isTodaySelected ? onPrimaryContainerColor : secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isTodaySelected) {
                  setState(() {
                    isTodaySelected = false;
                  });
                  _fetchSensorHistory();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isTodaySelected ? primaryContainerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  '7 Ngày Qua',
                  style: TextStyle(
                    color: !isTodaySelected ? onPrimaryContainerColor : secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(SensorRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    record.time,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Text(
                record.date,
                style: TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: surfaceVariant),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(Icons.thermostat, record.temp, 'Nhiệt độ', const Color(0xFFBA1A1A)),
              _buildMetricItem(Icons.water_drop, record.humidity, 'Độ ẩm', primaryContainerColor),
              _buildMetricItem(Icons.science, record.npk, 'NPK', const Color(0xFF755833)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: subTextColor,
          ),
        ),
      ],
    );
  }
}