import 'package:flutter/material.dart';

/// Простой сервис для управления текущей темой приложения.
///
/// Используется в `main.dart` и в `ProfilePage`.
class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static void toggleTheme() {
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
