import 'package:flutter/material.dart';

/// Widget personnalisé pour dessiner des lignes de connexion courbes élégantes
/// entre les éléments du dashboard admin
class ZigzagConnector extends CustomPainter {
  final List<Offset> points;
  final Color lineColor;
  final double strokeWidth;
  final bool animated;
  final double animationProgress;

  ZigzagConnector({
    required this.points,
    this.lineColor = const Color(0xFFE0E0E0),
    this.strokeWidth = 2.5,
    this.animated = false,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Dessiner des lignes courbes élégantes entre les points
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      if (animated) {
        // Animation progressive
        final animatedEnd = Offset(
          start.dx + (end.dx - start.dx) * animationProgress,
          start.dy + (end.dy - start.dy) * animationProgress,
        );
        _drawCurvedLine(canvas, start, animatedEnd, i);
      } else {
        _drawCurvedLine(canvas, start, end, i);
      }
    }
  }

  void _drawCurvedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    int index,
  ) {
    // Calculer le point de contrôle pour une courbe douce
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    
    // Créer une courbe de Bézier quadratique pour un effet plus fluide
    final controlPoint = Offset(midX, midY);
    
    // Créer un gradient pour la ligne
    final gradient = LinearGradient(
      colors: [
        lineColor.withOpacity(0.6),
        lineColor.withOpacity(0.3),
        lineColor.withOpacity(0.6),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    // Dessiner la ligne principale avec gradient
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromPoints(start, end),
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dessiner une ligne pointillée élégante
    _drawDashedPath(canvas, path, paint);

    // Ajouter un point lumineux au début et à la fin
    _drawGlowPoint(canvas, start, lineColor);
    if (index == points.length - 2) {
      _drawGlowPoint(canvas, end, lineColor);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final dashEnd = distance + dashWidth;
        final dashEndDistance = dashEnd < pathMetric.length ? dashEnd : pathMetric.length;

        final dashPath = pathMetric.extractPath(distance, dashEndDistance);
        canvas.drawPath(dashPath, paint);

        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawGlowPoint(Canvas canvas, Offset point, Color color) {
    // Cercle extérieur avec glow
    final outerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 6, outerPaint);

    // Cercle intérieur
    final innerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 4, innerPaint);

    // Point central brillant
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 2, centerPaint);
  }

  @override
  bool shouldRepaint(ZigzagConnector oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.animationProgress != animationProgress;
  }
}
