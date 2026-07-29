import 'package:flutter/material.dart';

class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF81C784),
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.error_outline,
      iconColor: const Color(0xFFFF8A80),
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFFFD54F),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.info_outline,
      iconColor: const Color(0xFF64B5F6),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? const Color(0xFF2C302E) : const Color(0xFF1E2421),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
