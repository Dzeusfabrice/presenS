import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget de chargement circulaire avec arc animé (style horloge moderne)
class CircularProgressClock extends StatelessWidget {
  final double progress; // 0.0 à 1.0
  final double size;
  final String? centerText;
  final String? minLabel;
  final String? maxLabel;

  const CircularProgressClock({
    Key? key,
    required this.progress,
    this.size = 200,
    this.centerText,
    this.minLabel,
    this.maxLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.clamp(0.0, 1.0);
    final percentage = (progressValue * 100).toInt();
    final displayText = centerText ?? '$percentage%';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc de progression avec gradient
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: progressValue,
              size: size,
            ),
          ),

          // Texte central
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayText,
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          // Labels min/max en bas
          Positioned(
            bottom: size * 0.15,
            left: size * 0.15,
            child: Text(
              minLabel ?? '0%',
              style: TextStyle(
                fontSize: size * 0.08,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.15,
            right: size * 0.15,
            child: Text(
              maxLabel ?? '100%',
              style: TextStyle(
                fontSize: size * 0.08,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour l'arc de progression circulaire
class CircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 à 1.0
  final double size;

  CircularProgressPainter({
    required this.progress,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.35;
    final strokeWidth = size * 0.08;

    // Angle de départ (en haut, -90 degrés)
    final startAngle = -90 * math.pi / 180;
    // Angle de fin basé sur le progrès (environ 240 degrés pour 2/3 du cercle)
    final sweepAngle = 240 * math.pi / 180 * progress;

    // Créer le gradient pour l'arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        const Color(0xFFFBBF24), // Jaune-vert
        const Color(0xFF34D399), // Vert clair
        const Color(0xFF60A5FA), // Bleu clair
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Dessiner l'arc de progression
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Dessiner le point indicateur à la fin de l'arc
    if (progress > 0) {
      final indicatorAngle = startAngle + sweepAngle;
      final indicatorX = center.dx + radius * math.cos(indicatorAngle);
      final indicatorY = center.dy + radius * math.sin(indicatorAngle);

      // Cercle indicateur avec glow
      final indicatorPaint = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.fill;

      // Glow externe
      final glowPaint = Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(indicatorX, indicatorY),
        strokeWidth * 0.6,
        glowPaint,
      );

      // Cercle principal
      canvas.drawCircle(
        Offset(indicatorX, indicatorY),
        strokeWidth * 0.4,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
