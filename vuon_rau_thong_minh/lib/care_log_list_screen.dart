import 'package:flutter/material.dart';
import 'add_care_log_screen.dart';
import 'services/log_service.dart';
import 'utils/time_utils.dart';

class CareLogListScreen extends StatefulWidget {
  final String? plantId;
  final String plantName;

  const CareLogListScreen({
    super.key,
    this.plantId,
    required this.plantName,
  });

  @override
  State<CareLogListScreen> createState() => _CareLogListScreenState();
}

class _CareLogListScreenState extends State<CareLogListScreen> {
  static const Color primaryColor = Color(0xFF005131);
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(context).colorScheme.surface;
  Color get textColor => Theme.of(context).colorScheme.onSurface;
  Color get subTextColor => Theme.of(context).colorScheme.onSurfaceVariant;

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
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
      final logs = await LogService.getCareLogs(widget.plantId!, limit: 100);
      if (mounted) {
        setState(() {
          _logs = logs;
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

  IconData _getIconForType(String action) {
    switch (action) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizing':
        return Icons.eco;
      case 'sun_exposure':
        return Icons.wb_sunny;
      case 'shade_covering':
        return Icons.home;
      case 'harvesting':
        return Icons.agriculture;
      default:
        return Icons.grass;
    }
  }

  Color _getColorForType(String action, bool isDark, ColorScheme colorScheme) {
    if (isDark) return colorScheme.primary;
    switch (action) {
      case 'watering':
        return primaryColor;
      case 'fertilizing':
        return const Color(0xFF755833);
      case 'sun_exposure':
        return Colors.orange;
      case 'shade_covering':
        return const Color(0xFF755833);
      case 'harvesting':
        return primaryColor;
      default:
        return primaryColor;
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'watering':
        return 'Tưới nước';
      case 'fertilizing':
        return 'Bón phân';
      case 'sun_exposure':
        return 'Đưa ra nắng';
      case 'shade_covering':
        return 'Che mát';
      case 'harvesting':
        return 'Thu hoạch';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? colorScheme.primary : textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhật ký chăm sóc',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.primary : textColor,
              ),
            ),
            Text(
              widget.plantName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: isDark ? colorScheme.primary : primaryColor, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCareLogScreen(
                    plantId: widget.plantId,
                    plantName: widget.plantName,
                  ),
                ),
              );
              if (result == true || result != null) {
                _fetchLogs();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: _logs.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Text('Chưa có nhật ký chăm sóc.', style: TextStyle(color: subTextColor)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final action = log['action'] ?? '';
                        final title = _getActionTitle(action);
                        final ts = TimeUtils.formatVietnamTime(log['timestamp']);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getColorForType(action, isDark, colorScheme).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(action),
                                  color: _getColorForType(action, isDark, colorScheme),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ts,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      log['notes'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
