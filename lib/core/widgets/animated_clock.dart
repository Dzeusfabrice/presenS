import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget d'horloge analogique animée et professionnelle
class AnimatedClock extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showGlow;

  const AnimatedClock({
    Key? key,
    this.size = 200,
    this.primaryColor,
    this.secondaryColor,
    this.showGlow = true,
  }) : super(key: key);

  @override
  State<AnimatedClock> createState() => _AnimatedClockState();
}

class _AnimatedClockState extends State<AnimatedClock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // Une rotation complète par minute
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primaryColor = widget.primaryColor ?? Colors.white;
    final secondaryColor = widget.secondaryColor ?? AppColors.primaryLight;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          if (widget.showGlow)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.4),
                    blurRadius: widget.size * 0.3,
                    spreadRadius: widget.size * 0.1,
                  ),
                ],
              ),
            ),

          // Cadran principal avec glassmorphism
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.15),
                  primaryColor.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: secondaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: ClockPainter(
                hour: now.hour % 12,
                minute: now.minute,
                second: now.second,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                size: widget.size,
              ),
            ),
          ),

          // Animation de la seconde aiguille
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final secondAngle = (now.second + _controller.value) * 6 * math.pi / 180;
              return Transform.rotate(
                angle: secondAngle,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: SecondHandPainter(
                    color: secondaryColor,
                    size: widget.size,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Painter pour le cadran et les aiguilles
class ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  ClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.primaryColor,
    required this.secondaryColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dessiner les marques des heures
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final startRadius = radius - (this.size * 0.08);
      final endRadius = radius - (this.size * 0.03);
      
      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);

      final paint = Paint()
        ..color = primaryColor.withOpacity(0.6)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // Dessiner les marques des minutes (plus petites)
    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        final angle = (i * 6 - 90) * math.pi / 180;
        final startRadius = radius - (this.size * 0.05);
        final endRadius = radius - (this.size * 0.02);
        
        final startX = center.dx + startRadius * math.cos(angle);
        final startY = center.dy + startRadius * math.sin(angle);
        final endX = center.dx + endRadius * math.cos(angle);
        final endY = center.dy + endRadius * math.sin(angle);

        final paint = Paint()
          ..color = primaryColor.withOpacity(0.3)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }
    }

    // Aiguille des heures
    final hourAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final hourLength = radius * 0.4;
    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * math.cos(hourAngle),
        center.dy + hourLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Aiguille des minutes
    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = primaryColor.withOpacity(0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final minuteLength = radius * 0.55;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // Centre de l'horloge
    final centerPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);
    
    final centerRingPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, centerRingPaint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.second != second;
  }
}

/// Painter pour l'aiguille des secondes animée
class SecondHandPainter extends CustomPainter {
  final Color color;
  final double size;

  SecondHandPainter({
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Aiguille des secondes
    final secondPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final secondLength = radius * 0.65;
    canvas.drawLine(
      center,
      Offset(
        center.dx + secondLength * math.cos(0),
        center.dy + secondLength * math.sin(0),
      ),
      secondPaint,
    );

    // Contrepoids de l'aiguille des secondes
    final counterweightPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(
        center.dx - (radius * 0.15) * math.cos(0),
        center.dy - (radius * 0.15) * math.sin(0),
      ),
      4,
      counterweightPaint,
    );
  }

  @override
  bool shouldRepaint(SecondHandPainter oldDelegate) => false;
}
