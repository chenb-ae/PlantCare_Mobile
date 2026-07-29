import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/plant_service.dart';
import 'services/sensor_service.dart';
import 'models/user_session.dart';

import 'services/upload_service.dart';
import 'utils/app_snackbar.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // Controller quản lý dữ liệu ô nhập
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Biến lưu trạng thái lựa chọn
  DateTime _selectedDate = DateTime.now();
  String _selectedPlantType = 'Cải Thìa';
  String _selectedSensor = 'sensor_01';
  String _selectedPlacement = 'outdoor';
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  final Map<String, String> _plantTypeMap = {
    'Cải Thìa': 'cai_thia',
    'Cải Ngọt': 'cai_ngot',
    'Rau Muống': 'rau_muong',
    'Xà Lách': 'xa_lach',
  };

  // Danh sách loại cây mẫu
  final List<Map<String, dynamic>> _plantTypes = [
    {'name': 'Cải Thìa', 'icon': Icons.yard},
    {'name': 'Cải Ngọt', 'icon': Icons.local_florist},
    {'name': 'Rau Muống', 'icon': Icons.grass},
    {'name': 'Xà Lách', 'icon': Icons.spa},
  ];

  // Danh sách bộ cảm biến mẫu
  List<Map<String, String>> _sensors = [
    {'id': 'sensor_01', 'name': 'Cảm biến #1 (Ban công)', 'status': 'Sẵn sàng'},
    {'id': 'sensor_02', 'name': 'Cảm biến #2 (Sân thượng)', 'status': 'Sẵn sàng'},
  ];

  // Danh sách vị trí đặt chậu (khớp API: outdoor | shaded)
  final List<Map<String, dynamic>> _placements = [
    {'id': 'outdoor', 'label': 'Ngoài trời', 'icon': Icons.wb_sunny, 'desc': 'Ban công, sân thượng'},
    {'id': 'shaded', 'label': 'Trong nhà / Che mát', 'icon': Icons.home, 'desc': 'Phòng khách, hiên có mái'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSensors();
  }

  Future<void> _fetchSensors() async {
    try {
      final userId = UserSession().currentUserId;
      final sensorList = await SensorService.listSensors(userId: userId);
      if (sensorList.isNotEmpty && mounted) {
        setState(() {
          _sensors = sensorList.map((s) => {
            'id': s['sensor_id'].toString(),
            'name': s['name'].toString(),
            'status': s['status'] == 'available' ? 'Sẵn sàng' : 'Đã gán (${s['current_plant_name'] ?? ''})',
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _showAddSensorDialog() async {
    final TextEditingController nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm cảm biến mới'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Nhập tên cảm biến (vd: Cảm biến Ban Công #2)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final userId = UserSession().currentUserId;
                  final newSensor = await SensorService.createSensor(name: name, userId: userId);
                  if (newSensor != null) {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    await _fetchSensors();
                    if (mounted && newSensor['sensor_id'] != null) {
                      setState(() {
                        _selectedSensor = newSensor['sensor_id'];
                      });
                    }
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Hàm mở DatePicker chọn ngày bắt đầu trồng
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
              onPrimary: Colors.white,
              onSurface: Color(0xFF191C1D),
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

  // Hàm xử lý lưu / bắt đầu trồng
  Future<void> _handleSavePlant() async {
    final name = _plantNameController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.showWarning(context, 'Vui lòng nhập tên chậu cây!');
      return;
    }

    final userId = UserSession().currentUserId;
    final apiType = _plantTypeMap[_selectedPlantType] ?? 'cai_thia';

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await UploadService.uploadImage(_selectedImage!);
      }

      await PlantService.createPlant(
        userId: userId,
        name: name,
        type: apiType,
        sensorId: _selectedSensor,
        placement: _selectedPlacement,
        imageUrl: imageUrl,
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Đã thêm cây "$name" thành công!');
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
    
    // Bảng màu chuẩn Tailwind từ HTML của bro
    const primaryColor = Color(0xFF005131);
    const primaryContainer = Color(0xFF106B44);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final inputBgColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;
    final subTextColor = colorScheme.onSurfaceVariant;
    final surfaceColor = colorScheme.surface;

    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? colorScheme.primary : primaryColor;
    final unselectedCardBg = colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: backgroundColor,
      // 1. TopAppBar
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: subTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm cây mới',
          style: TextStyle(
            color: headerColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: headerColor),
            onPressed: _handleSavePlant,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Form Container (Bento Style)
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF106B44).withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field 1: Tên chậu cây
                          Text('Tên chậu cây',
                              style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _plantNameController,
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: Chậu Cải Thìa Ban Công',
                              hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: inputBgColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Field 2: Loại cây trồng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Loại cây trồng',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Xem tất cả',
                                  style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _plantTypes.map((plant) {
                                final isSelected = _selectedPlantType == plant['name'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPlantType = plant['name'];
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 85,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryContainer : unselectedCardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryContainer : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isSelected ? primaryContainer.withValues(alpha: 0.2) : inputBgColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              plant['icon'],
                                              color: isSelected ? Colors.white : subTextColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            plant['name'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Colors.white : textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(color: Color(0xFFE1E3E4)),
                          ),

                          // Field 3: Ngày bắt đầu trồng
                          Text('Ngày bắt đầu trồng',
                              style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: inputBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                                    style: TextStyle(fontSize: 15, color: textColor),
                                  ),
                                  Icon(Icons.calendar_today, color: subTextColor, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Field 4: Lựa chọn cảm biến
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Lựa chọn cảm biến',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _showAddSensorDialog,
                                icon: Icon(Icons.add, size: 16, color: colorScheme.primary),
                                label: Text(
                                  'Thêm cảm biến',
                                  style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _sensors.map((sensor) {
                                final isSelected = _selectedSensor == sensor['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSensor = sensor['id']!;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 130,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryContainer : unselectedCardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryContainer : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.sensors,
                                                size: 18,
                                                color: isSelected ? Colors.white : subTextColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  sensor['name']!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isSelected ? Colors.white : textColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sensor['status']!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? Colors.white.withValues(alpha: 0.8)
                                                  : subTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Field 5: Vị trí đặt chậu (outdoor / shaded)
                          Text('Vị trí đặt chậu',
                              style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 10),
                          Row(
                            children: _placements.map((placement) {
                              final isSelected = _selectedPlacement == placement['id'];
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: placement['id'] == 'outdoor' ? 8.0 : 0,
                                    left: placement['id'] == 'shaded' ? 8.0 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPlacement = placement['id'];
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryContainer : unselectedCardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryContainer : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            placement['icon'],
                                            size: 28,
                                            color: isSelected ? Colors.white : subTextColor,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            placement['label'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            placement['desc'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Colors.white.withValues(alpha: 0.8)
                                                  : subTextColor.withValues(alpha: 0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ảnh chậu cây (Chọn từ thư viện / Chụp hình)
                    _buildImagePicker(),
                  ],
                ),
              ),
            ),

            // Nút "Bắt đầu trồng" cố định ở đáy
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _isLoading ? null : _handleSavePlant,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.eco),
                  label: Text(
                    _isLoading ? 'Đang tạo...' : 'Bắt đầu trồng',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CHỌN / CHỤP ẢNH ---
  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    const primaryColor = Color(0xFF005131);
    const primaryContainer = Color(0xFF106B44);
    final subTextColor = colorScheme.onSurfaceVariant;
    final surfaceColor = colorScheme.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1E3E4),
          width: 1,
        ),
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: subTextColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm ảnh chậu cây',
                    style: TextStyle(fontSize: 14, color: subTextColor.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nút Chụp hình
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Chụp hình'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Chọn ảnh
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Thư viện'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Hàm chọn ảnh từ camera hoặc gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
      if (mounted) {
        AppSnackBar.showWarning(context, 'Không thể chọn ảnh. Vui lòng thử lại.');
      }
    }
  }
}