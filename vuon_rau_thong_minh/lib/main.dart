import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'models/user_session.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await UserSession().loadFromPrefs();
  runApp(SmartGardenApp(isLoggedIn: isLoggedIn));
}

class SmartGardenApp extends StatelessWidget {
  final bool isLoggedIn;
  const SmartGardenApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeOption>(
      valueListenable: ThemeService.currentTheme,
      builder: (context, themeOption, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vườn Rau Thông Minh',
          themeMode: themeOption.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005131)),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF1E2421),
              contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF2C302E),
              contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              primary: const Color(0xFF81C784),
              primaryContainer: const Color(0xFF1B4D2E),
              onPrimaryContainer: const Color(0xFFA5D6A7),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
              surfaceContainerHighest: const Color(0xFF2C2C2C),
              onSurface: Colors.white,
              onSurfaceVariant: const Color(0xFFB0BEC5),
            ),
          ),
          home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}
