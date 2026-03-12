import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/preferences_service.dart';
import 'app_theme.dart';

class ThemeController extends GetxController {
  // ─── Dependency ───────────────────────────────────────────
  // SharedPreferences key: "theme_mode"
  final _prefs = Get.find<PreferencesService>();

  // ─── State ────────────────────────────────────────────────
  late final Rx<ThemeMode> themeMode;

  // ─── Init ─────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Load from SharedPreferences
    final saved = _prefs.themeMode.value; // "dark" | "light" | "system"
    themeMode = _toThemeMode(saved).obs;

    // React to prefs changes
    ever(_prefs.themeMode, (String val) {
      themeMode.value = _toThemeMode(val);
      _applyTheme();
    });
  }

  // ─── Public Methods ───────────────────────────────────────
  bool get isDark => themeMode.value == ThemeMode.dark;

  void setDark()   => _updateTheme('dark');
  void setLight()  => _updateTheme('light');
  void setSystem() => _updateTheme('system');

  void toggle() {
    if (isDark) {
      setLight();
    } else {
      setDark();
    }
  }

  ThemeData get currentTheme =>
      isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

  // ─── Private ──────────────────────────────────────────────
  void _updateTheme(String val) {
    _prefs.themeMode.value = val; // auto-saves to SharedPreferences
  }

  void _applyTheme() {
    Get.changeThemeMode(themeMode.value);
  }

  ThemeMode _toThemeMode(String val) {
    switch (val) {
      case 'light':  return ThemeMode.light;
      case 'system': return ThemeMode.system;
      default:       return ThemeMode.dark;
    }
  }
}