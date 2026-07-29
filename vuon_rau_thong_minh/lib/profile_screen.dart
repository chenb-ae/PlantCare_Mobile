import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'models/user_session.dart';
import 'services/auth_service.dart';
import 'services/sensor_service.dart';
import 'services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isNotificationEnabled = true;

  static const primaryColor = Color(0xFF005131);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userId = UserSession().currentUserId;
    try {
      await AuthService.getProfile(userId);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _showSensorManagementModal() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final userId = UserSession().currentUserId;
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: SensorService.listSensors(userId: userId),
                builder: (context, snapshot) {
                  final sensors = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quản lý Cảm biến',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: colorScheme.primary),
                            onPressed: () async {
                              final nameCtrl = TextEditingController();
                              await showDialog(
                                context: ctx,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Thêm cảm biến mới'),
                                  content: TextField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(hintText: 'Tên cảm biến (vd: Cảm biến Ban Công)'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (nameCtrl.text.trim().isNotEmpty) {
                                          await SensorService.createSensor(
                                            name: nameCtrl.text.trim(),
                                            userId: userId,
                                          );
                                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                          setModalState(() {});
                                        }
                                      },
                                      child: const Text('Thêm'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : sensors.isEmpty
                                ? Center(
                                    child: Text(
                                      'Bạn chưa có cảm biến cá nhân nào.\nBấm nút "+" góc phải để thêm!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: sensors.length,
                                    itemBuilder: (ctx, index) {
                                      final sensor = sensors[index];
                                      final sId = sensor['sensor_id'] ?? '';
                                      final sName = sensor['name'] ?? 'Cảm biến';
                                      final plantName = sensor['current_plant_name'];
                                      final statusText = plantName != null && plantName.toString().isNotEmpty
                                          ? 'Đã gán: $plantName'
                                          : 'Sẵn sàng';

                                      return Card(
                                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        elevation: 0,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                                            child: Icon(Icons.sensors, color: colorScheme.primary),
                                          ),
                                          title: Text(sName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          subtitle: Text(statusText, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () async {
                                              if (plantName != null && plantName.toString().isNotEmpty) {
                                                showDialog(
                                                  context: ctx,
                                                  builder: (alertCtx) => AlertDialog(
                                                    title: const Text('Không thể xóa cảm biến'),
                                                    content: Text('Cảm biến "$sName" đang được gắn cho chậu cây "$plantName". Vui lòng tháo hoặc thu hoạch chậu cây trước khi xóa cảm biến!'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(alertCtx),
                                                        child: const Text('Đã hiểu'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                return;
                                              }

                                              final confirm = await showDialog<bool>(
                                                context: ctx,
                                                builder: (confirmCtx) => AlertDialog(
                                                  title: const Text('Xóa cảm biến'),
                                                  content: Text('Bạn có chắc chắn muốn xóa "$sName" không?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(confirmCtx, false),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                      onPressed: () => Navigator.pop(confirmCtx, true),
                                                      child: const Text('Xóa'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await SensorService.deleteSensor(sId);
                                                setModalState(() {});
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xác nhận đăng xuất',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF191C1D),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF3F4942)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF3F4942)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: onErrorContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  await GoogleSignIn().signOut();
                } catch (_) {}
                await UserSession().clear();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(theme, isDark),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildSettingsSection(
                    theme: theme,
                    title: 'Cài đặt tài khoản',
                    children: [
                      _buildSettingsTile(
                        theme: theme,
                        icon: Icons.edit_outlined,
                        title: 'Chỉnh sửa hồ sơ',
                        subtitle: 'Tên hiển thị, avatar',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      ),
                      _buildSettingsTile(
                        theme: theme,
                        icon: Icons.sensors_outlined,
                        title: 'Quản lý thiết bị cảm biến',
                        subtitle: 'Xem & xóa cảm biến cá nhân',
                        onTap: _showSensorManagementModal,
                      ),
                      _buildSettingsTile(
                        theme: theme,
                        icon: Icons.lock_outline,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Mật khẩu hiện tại, mật khẩu mới',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsSection(
                    theme: theme,
                    title: 'Ứng dụng & Cài đặt',
                    children: [
                      _buildSwitchTile(
                        theme: theme,
                        icon: Icons.notifications_none_outlined,
                        title: 'Thông báo cảnh báo',
                        subtitle: 'Bật/tắt nhận thông báo tức thì',
                        value: isNotificationEnabled,
                        onChanged: (val) {
                          setState(() {
                            isNotificationEnabled = val;
                          });
                        },
                      ),
                      _buildThemeDropdownTile(theme),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsSection(
                    theme: theme,
                    title: 'Hỗ trợ & Thông tin',
                    children: [
                      _buildSettingsTile(
                        theme: theme,
                        icon: Icons.help_outline,
                        title: 'Trung tâm trợ giúp',
                        subtitle: 'Hướng dẫn sử dụng & FAQ',
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        theme: theme,
                        icon: Icons.info_outline,
                        title: 'Về ứng dụng',
                        subtitle: 'Phiên bản 1.0.0 (PlanCare)',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 32),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorContainer,
                        foregroundColor: onErrorContainer,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final userName = UserSession().name ?? 'Nguyễn Văn A';
    final userEmail = UserSession().email ?? 'nguyen.van.a@example.com';
    final avatarPath = UserSession().avatarPath;

    ImageProvider? imageProvider;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      if (avatarPath.startsWith('http')) {
        imageProvider = NetworkImage(avatarPath);
      } else {
        imageProvider = FileImage(File(avatarPath));
      }
    }

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
                    Icons.person,
                    size: 48,
                    color: primaryColor,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF3F4942),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required ThemeData theme,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF3F4942),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE1E3E4).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF6F7A71), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF3F4942),
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : const Color(0xFF6F7A71)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF6F7A71), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF3F4942),
          fontSize: 12,
        ),
      ),
      activeThumbColor: primaryColor,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildThemeDropdownTile(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.color_lens_outlined, color: isDark ? Colors.white70 : const Color(0xFF6F7A71), size: 20),
      ),
      title: Text(
        'Chủ đề giao diện',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        'Tùy chỉnh chế độ hiển thị Sáng / Tối',
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF3F4942),
          fontSize: 12,
        ),
      ),
      trailing: DropdownButton<AppThemeOption>(
        value: ThemeService.currentTheme.value,
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface,
        onChanged: (AppThemeOption? newOption) {
          if (newOption != null) {
            setState(() {
              ThemeService.setTheme(newOption);
            });
          }
        },
        items: AppThemeOption.values.map((option) {
          return DropdownMenuItem<AppThemeOption>(
            value: option,
            child: Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}