import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    // Forcer la mise à jour de Get.isDarkMode
    Get.forceAppUpdate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    // Forcer la mise à jour de Get.isDarkMode
    Get.forceAppUpdate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}
