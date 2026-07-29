import 'package:flutter/material.dart';
import 'models/user_session.dart';
import 'services/auth_service.dart';
import 'utils/app_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Colors
  final Color primaryColor = const Color(0xFF005131);
  final Color primaryContainer = const Color(0xFF106B44);
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(context).colorScheme.surface;
  Color get textColor => Theme.of(context).colorScheme.onSurface;
  Color get subTextColor => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get inputBgColor => Theme.of(context).colorScheme.surfaceContainerHighest;
  final Color surfaceVariant = const Color(0xFFE1E3E4);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      AppSnackBar.showWarning(context, "Vui lòng đăng nhập lại để đổi mật khẩu!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.changePassword(
        userId,
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, "Đổi mật khẩu thành công!");
        Navigator.pop(context);
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: subTextColor,
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
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
          "Đổi mật khẩu",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: "Mật khẩu hiện tại",
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                onToggleVisibility: () {
                  setState(() {
                    _obscureOld = !_obscureOld;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                label: "Mật khẩu mới",
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                label: "Xác nhận mật khẩu mới",
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Cập nhật mật khẩu",
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
