import 'package:flutter/material.dart';
import 'models/user_session.dart';
import 'services/log_service.dart';
import 'services/alert_service.dart';
import 'utils/app_snackbar.dart';

class AddCareLogScreen extends StatefulWidget {
  final String? plantId;
  final String plantName;
  final String? placement;

  const AddCareLogScreen({
    super.key,
    this.plantId,
    this.plantName = 'Chậu Cải Thìa F1',
    this.placement,
  });

  @override
  State<AddCareLogScreen> createState() => _AddCareLogScreenState();
}

class _AddCareLogScreenState extends State<AddCareLogScreen> {
  String _selectedAction = 'Tưới nước';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _actionKeyMap = {
    'Tưới nước': 'watering',
    'Bón phân': 'fertilizing',
    'Thu hoạch': 'harvesting',
    'Đưa ra ngoài': 'sun_exposure',
    'Đưa vào nhà': 'shade_covering',
  };

  final List<Map<String, dynamic>> _actions = [
    {'name': 'Tưới nước', 'icon': Icons.water_drop},
    {'name': 'Bón phân', 'icon': Icons.eco},
    {'name': 'Thu hoạch', 'icon': Icons.agriculture},
    {'name': 'Đưa ra ngoài', 'icon': Icons.light_mode},
    {'name': 'Đưa vào nhà', 'icon': Icons.home},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005131),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005131),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    final notes = _notesController.text.trim();
    if (widget.plantId == null || widget.plantId!.isEmpty) {
      AppSnackBar.showWarning(context, 'Thiếu mã chậu cây để thêm nhật ký!');
      return;
    }

    final apiAction = _actionKeyMap[_selectedAction] ?? 'watering';

    setState(() {
      _isLoading = true;
    });

    try {
      await LogService.createCareLog(
        plantId: widget.plantId!,
        action: apiAction,
        notes: notes,
      );

      // Kích hoạt ngay việc tải và nổ thông báo đẩy OS nếu tác động nhật ký khiến thông số vượt ngưỡng
      final userId = UserSession().currentUserId;
      await AlertService.getAlerts(userId, unreadOnly: true);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Đã thêm nhật ký "$_selectedAction" cho ${widget.plantName}!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
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
    
    const primaryColor = Color(0xFF005131);
    const primaryContainer = Color(0xFF106B44);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceContainer = colorScheme.surface;
    final secondaryContainer = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;
    final subTextColor = colorScheme.onSurfaceVariant;
    const outlineVariant = Color(0xFFBEC9BF);
    final surfaceColor = colorScheme.surface;

    final formattedDateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final formattedTimeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: subTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm Nhật ký Chăm sóc',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: primaryColor),
            onPressed: _saveLog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thẻ thông tin chậu cây
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineVariant),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBDQCODZZPa7YqYj5KF02OgsBLlZzTpsPfB4p0P1SCcgdbaBfH3G2iKrhbYdwRKQLcprKh3onwhIbH-TINLp0yRlSqzAC3me6_5AiZurKiBuWUpB5yC4AGym85HisjnYLKGtLUHMKtwpz252Fj6oJwmFAmdFG4-m2TZxL6O2Iv_7J0T-7-pRgUiK7NT58mjPOzlsUdWZ5X_cvUk_vwuqTFZFzyTN0VlWEtoIHE_xnU0Kz3tdLSiVpY',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: outlineVariant,
                          child: const Icon(Icons.yard, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plantName, // Hiển thị tên cây
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vườn Ban Công',
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Chọn loại hoạt động
              Text(
                'Hoạt động',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  final isSelected = _selectedAction == action['name'];

                  final bool isDisabled = (widget.placement == 'outdoor' && action['name'] == 'Đưa ra ngoài') ||
                      (widget.placement == 'shaded' && action['name'] == 'Đưa vào nhà');

                  return InkWell(
                    onTap: isDisabled
                        ? () {
                            AppSnackBar.showInfo(
                              context,
                              widget.placement == 'outdoor'
                                  ? 'Chậu cây hiện tại đã ở ngoài trời rồi!'
                                  : 'Chậu cây hiện tại đã ở trong nhà rồi!',
                            );
                          }
                        : () {
                            setState(() {
                              _selectedAction = action['name'];
                            });
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Opacity(
                      opacity: isDisabled ? 0.4 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? primaryContainer : (isDisabled ? surfaceContainer : surfaceColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? primaryContainer : outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              action['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : subTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              action['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : subTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. Chọn Ngày & Giờ
              Text(
                'Thời gian',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Chọn ngày
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: subTextColor),
                            const SizedBox(width: 10),
                            Text(
                              formattedDateStr,
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chọn giờ
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: subTextColor),
                            const SizedBox(width: 8),
                            Text(
                              formattedTimeStr,
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Ghi chú
              Text(
                'Ghi chú',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Thêm chi tiết về tình trạng cây, lượng nước...',
                  hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                  fillColor: secondaryContainer,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Hình ảnh
              Text(
                'Hình ảnh (Tùy chọn)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // Mở Camera / Thư viện ảnh
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 28, color: subTextColor),
                      SizedBox(height: 6),
                      Text(
                        'Tải ảnh lên',
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. Nút Lưu nhật ký
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveLog,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Đang lưu...' : 'Lưu nhật ký',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}