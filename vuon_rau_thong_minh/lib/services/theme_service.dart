import 'package:flutter/material.dart';

enum AppThemeOption {
  system('Hệ thống', ThemeMode.system),
  light('Sáng', ThemeMode.light),
  dark('Tối', ThemeMode.dark);

  final String label;
  final ThemeMode mode;

  const AppThemeOption(this.label, this.mode);
}

class ThemeService {
  static final ValueNotifier<AppThemeOption> currentTheme = ValueNotifier<AppThemeOption>(AppThemeOption.system);

  static void setTheme(AppThemeOption option) {
    currentTheme.value = option;
  }
}
