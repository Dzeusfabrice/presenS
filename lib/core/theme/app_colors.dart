import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';

class AppColors {
  // Primary brand (institutional blue)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Helper to get theme controller safely
  static ThemeController? get _themeController {
    try {
      return Get.isRegistered<ThemeController>()
          ? Get.find<ThemeController>()
          : null;
    } catch (_) {
      return null;
    }
  }

  // Backgrounds (réactif au thème)
  static Color get background {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  }

  static Color get backgroundGrey {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
  }

  static Color get cardBackground {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  }

  // Text (réactif au thème)
  static Color get textPrimary {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFFF9FAFB) : const Color(0xFF374151);
  }

  static Color get textSecondary {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  }

  // Status colors (business logic)
  static const Color success = Color(0xFF16A34A); // PRESENT
  static const Color warning = Color(0xFFF59E0B); // RETARD
  static const Color error = Color(0xFFDC2626); // ABSENT

  // UI Greys
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey300 = Color(0xFFE5E7EB);
  static const Color grey500 = Color(0xFF9CA3AF);

  // Borders & Dividers (réactif au thème)
  static Color get border {
    final controller = _themeController;
    final isDark = controller?.isDarkMode ?? Get.isDarkMode;
    return isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  }

  // Gradients
  static const List<Color> mainGradient = [primary, primaryLight];
}
