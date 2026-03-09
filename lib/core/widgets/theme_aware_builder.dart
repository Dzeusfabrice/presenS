import 'package:chrono/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget qui reconstruit automatiquement quand le thème change
class ThemeAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const ThemeAwareBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => builder(context));
  }
}
