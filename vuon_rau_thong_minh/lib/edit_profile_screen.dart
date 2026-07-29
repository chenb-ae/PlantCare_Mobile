import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/user_session.dart';
import 'services/auth_service.dart';
import 'services/upload_service.dart';
import 'utils/app_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  final Color primaryColor = const Color(0xFF005131);
  final Color primaryContainer = const Color(0xFF106B44);
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(context).colorScheme.surface;
  Color get textColor => Theme.of(context).colorScheme.onSurface;
  Color get subTextColor => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get inputBgColor => Theme.of(context).colorScheme.surfaceContainerHighest;
  final Color surfaceVariant = const Color(0xFFE1E3E4);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserSession().name ?? 'Nguyễn Văn A');
    _emailController = TextEditingController(text: UserSession().email ?? 'nguyen.van.a@example.com');
    if (UserSession().avatarPath != null && UserSession().avatarPath!.isNotEmpty) {
      _avatarImage = File(UserSession().avatarPath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _avatarImage = File(pickedFile.path);
        });
        UserSession().avatarPath = pickedFile.path;
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Không thể chọn ảnh: $e');
      }
    }
  }

  void _showImagePickerModal() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              children: [
                Center(
                  child: Text(
                    'Chọn ảnh đại diện',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: colorScheme.primary),
                  title: Text('Chụp ảnh từ Camera', style: TextStyle(color: colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: colorScheme.primary),
                  title: Text('Chọn ảnh từ Thư viện', style: TextStyle(color: colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = UserSession().currentUserId;
    final newName = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_avatarImage != null) {
        final avatarUrl = await UploadService.uploadImage(_avatarImage!);
        UserSession().avatarPath = avatarUrl;
      }
      await AuthService.updateProfile(userId, newName);
      if (mounted) {
        AppSnackBar.showSuccess(context, "Cập nhật hồ sơ thành công!");
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
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Chỉnh sửa hồ sơ",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.check, color: primaryColor),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerModal,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage: _avatarImage != null
                            ? FileImage(_avatarImage!)
                            : (UserSession().avatarPath != null && UserSession().avatarPath!.startsWith('http')
                                ? NetworkImage(UserSession().avatarPath!) as ImageProvider
                                : null),
                        child: (_avatarImage == null && (UserSession().avatarPath == null || UserSession().avatarPath!.isEmpty))
                            ? Icon(
                                Icons.person,
                                size: 56,
                                color: primaryColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Họ tên",
                  labelStyle: TextStyle(color: subTextColor),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: subTextColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Vui lòng nhập họ tên";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(color: subTextColor),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: subTextColor),
                  helperText: "Email không thể thay đổi",
                  helperStyle: TextStyle(color: subTextColor),
                  filled: true,
                  fillColor: surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Lưu thay đổi",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
