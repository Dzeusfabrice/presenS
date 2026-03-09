import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WatermarkBackground extends StatelessWidget {
  final Widget child;
  final bool opacity;

  const WatermarkBackground({
    Key? key,
    required this.child,
    this.opacity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watermark in the background
        Center(
          child: Opacity(
            opacity: opacity ? 0.05 : 0.0,
            child: Icon(
              Icons.school_rounded,
              size: MediaQuery.of(context).size.width * 0.8,
              color: AppColors.primary,
            ),
          ),
        ),
        // Main content
        child,
      ],
    );
  }
}
