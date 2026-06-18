import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cute Tooth painter with customizable emotional states and options.
class ToothPainter extends CustomPainter {
  final String expression; // 'happy', 'winking', 'brushing', 'dizzy'
  final double cheekBlushOpacity;
  final bool hasToothbrush;
  final double brushAnimationValue; // For animating brushing action

  ToothPainter({
    this.expression = 'happy',
    this.cheekBlushOpacity = 0.6,
    this.hasToothbrush = false,
    this.brushAnimationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // Draw Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.15, h * 0.88, w * 0.85, h * 0.96),
      shadowPaint,
    );

    // Main Tooth Path
    final path = Path();
    
    // Top-left crown cusp
    path.moveTo(w * 0.2, h * 0.25);
    
    // Top dip between cusps (crown dip)
    path.cubicTo(
      w * 0.2, h * 0.12,  // Control 1
      w * 0.45, h * 0.12, // Control 2
      w * 0.5, h * 0.23,  // End
    );
    
    // Top-right crown cusp
    path.cubicTo(
      w * 0.55, h * 0.12, // Control 1
      w * 0.8, h * 0.12,  // Control 2
      w * 0.8, h * 0.25,  // End
    );

    // Right cheek / side
    path.cubicTo(
      w * 0.85, h * 0.4,
      w * 0.88, h * 0.6,
      w * 0.8, h * 0.75,
    );

    // Right root (bottom right)
    path.cubicTo(
      w * 0.76, h * 0.85,
      w * 0.6, h * 0.92,
      w * 0.58, h * 0.78, // Inside root dip start
    );

    // Central bottom dip between roots
    path.cubicTo(
      w * 0.56, h * 0.68,
      w * 0.44, h * 0.68,
      w * 0.42, h * 0.78, // Inside root dip end
    );

    // Left root (bottom left)
    path.cubicTo(
      w * 0.4, h * 0.92,
      w * 0.24, h * 0.85,
      w * 0.2, h * 0.75,
    );

    // Left cheek / side
    path.cubicTo(
      w * 0.12, h * 0.6,
      w * 0.15, h * 0.4,
      w * 0.2, h * 0.25,
    );
    
    path.close();

    // Draw main tooth body (gradient for soft 3D look)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        const Color(0xFFF3F7FA),
        const Color(0xFFE1EFF7),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, paint);

    // Draw Inner Highlight (for 3D effect)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = Colors.white.withOpacity(0.85)
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path();
    highlightPath.moveTo(w * 0.23, h * 0.27);
    highlightPath.cubicTo(
      w * 0.23, h * 0.18,
      w * 0.38, h * 0.18,
      w * 0.45, h * 0.24,
    );
    canvas.drawPath(highlightPath, highlightPaint);

    // Draw Rosy Cheeks (Blush)
    final blushPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFB5C5).withOpacity(cheekBlushOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05);
    
    // Left cheek
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.28, h * 0.48), width: w * 0.12, height: h * 0.08),
      blushPaint,
    );
    // Right cheek
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.72, h * 0.48), width: w * 0.12, height: h * 0.08),
      blushPaint,
    );

    // Reset shader for details
    paint.shader = null;

    // Draw Eyes
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2C3E50);

    final eyeReflectionPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    if (expression == 'winking') {
      // Left Eye: Happy Arch (Winking)
      final eyePath = Path();
      eyePath.moveTo(w * 0.28, h * 0.43);
      eyePath.quadraticBezierTo(w * 0.34, h * 0.36, w * 0.4, h * 0.43);
      
      final winkStrokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..color = const Color(0xFF2C3E50)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(eyePath, winkStrokePaint);

      // Right Eye: Open
      canvas.drawCircle(Offset(w * 0.66, h * 0.42), w * 0.05, eyePaint);
      canvas.drawCircle(Offset(w * 0.64, h * 0.40), w * 0.016, eyeReflectionPaint);
      canvas.drawCircle(Offset(w * 0.68, h * 0.44), w * 0.008, eyeReflectionPaint);
    } else if (expression == 'dizzy') {
      // Dizzy eyes (crosses)
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..color = const Color(0xFF2C3E50)
        ..strokeCap = StrokeCap.round;
      
      // Left cross
      canvas.drawLine(Offset(w * 0.28, h * 0.38), Offset(w * 0.38, h * 0.46), strokePaint);
      canvas.drawLine(Offset(w * 0.38, h * 0.38), Offset(w * 0.28, h * 0.46), strokePaint);

      // Right cross
      canvas.drawLine(Offset(w * 0.62, h * 0.38), Offset(w * 0.72, h * 0.46), strokePaint);
      canvas.drawLine(Offset(w * 0.72, h * 0.38), Offset(w * 0.62, h * 0.46), strokePaint);
    } else {
      // Normal Happy Eyes (Both open)
      // Left eye
      canvas.drawCircle(Offset(w * 0.34, h * 0.42), w * 0.05, eyePaint);
      canvas.drawCircle(Offset(w * 0.32, h * 0.40), w * 0.016, eyeReflectionPaint);
      canvas.drawCircle(Offset(w * 0.36, h * 0.44), w * 0.008, eyeReflectionPaint);

      // Right eye
      canvas.drawCircle(Offset(w * 0.66, h * 0.42), w * 0.05, eyePaint);
      canvas.drawCircle(Offset(w * 0.64, h * 0.40), w * 0.016, eyeReflectionPaint);
      canvas.drawCircle(Offset(w * 0.68, h * 0.44), w * 0.008, eyeReflectionPaint);
    }

    // Draw Eyelashes (cute details)
    final lashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..color = const Color(0xFF2C3E50)
      ..strokeCap = StrokeCap.round;
    
    if (expression != 'dizzy') {
      // Left lashes
      canvas.drawLine(Offset(w * 0.27, h * 0.40), Offset(w * 0.24, h * 0.37), lashPaint);
      canvas.drawLine(Offset(w * 0.29, h * 0.39), Offset(w * 0.25, h * 0.34), lashPaint);
      
      // Right lashes
      canvas.drawLine(Offset(w * 0.73, h * 0.40), Offset(w * 0.76, h * 0.37), lashPaint);
      canvas.drawLine(Offset(w * 0.71, h * 0.39), Offset(w * 0.75, h * 0.34), lashPaint);
    }

    // Draw Mouth / Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..style = PaintingStyle.fill;

    if (expression == 'brushing') {
      // Circular "O" mouth for brushing/bubbling
      paint.style = PaintingStyle.fill;
      paint.color = const Color(0xFF2C3E50);
      canvas.drawCircle(Offset(w * 0.5, h * 0.53), w * 0.045, paint);
      paint.color = const Color(0xFFFF8A8A);
      canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.025, paint);
    } else {
      // Big open happy smile
      final mouthPath = Path();
      mouthPath.moveTo(w * 0.42, h * 0.5);
      // Curve down and back up
      mouthPath.cubicTo(
        w * 0.44, h * 0.62,
        w * 0.56, h * 0.62,
        w * 0.58, h * 0.5,
      );
      // Curve back up to starting corner to form lips
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.52, w * 0.42, h * 0.5);
      canvas.drawPath(mouthPath, mouthPaint);

      // Cute tiny tooth in mouth (single buck tooth)
      final tinyToothPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.48, h * 0.506, w * 0.04, h * 0.03),
        tinyToothPaint,
      );
    }

    // Draw Toothbrush if hasToothbrush is true (for Screen 2 / 3)
    if (hasToothbrush) {
      canvas.save();
      // Translate and rotate toothbrush in hand
      canvas.translate(w * 0.85 + (math.sin(brushAnimationValue * math.pi * 2) * 5), h * 0.5);
      canvas.rotate(-math.pi / 6);
      
      _drawToothbrushGraphic(canvas, w * 0.5, h * 0.8);
      canvas.restore();
    }
  }

  void _drawToothbrushGraphic(Canvas canvas, double w, double h) {
    // Toothbrush handle
    final handlePaint = Paint()
      ..color = const Color(0xFF3498DB)
      ..style = PaintingStyle.fill;
    
    final handlePath = Path();
    handlePath.moveTo(-w * 0.1, h * 0.4);
    handlePath.quadraticBezierTo(-w * 0.08, -h * 0.2, w * 0.05, -h * 0.4);
    handlePath.lineTo(w * 0.15, -h * 0.38);
    handlePath.quadraticBezierTo(-w * 0.02, -h * 0.18, -w * 0.02, h * 0.4);
    handlePath.close();
    canvas.drawPath(handlePath, handlePaint);

    // Head
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, -h * 0.48, w * 0.14, h * 0.12), const Radius.circular(6)),
      headPaint,
    );

    // Bristles
    final bristlePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.04, -h * 0.54, w * 0.1, h * 0.07), const Radius.circular(2)),
      bristlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ToothPainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.cheekBlushOpacity != cheekBlushOpacity ||
        oldDelegate.hasToothbrush != hasToothbrush ||
        oldDelegate.brushAnimationValue != brushAnimationValue;
  }
}

/// Cartoon Toothbrush painter.
class ToothbrushPainter extends CustomPainter {
  final Color mainColor;

  ToothbrushPainter({this.mainColor = const Color(0xFF4A90E2)});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.9, w * 0.8, h * 0.08), shadowPaint);

    // Draw handle
    final handlePaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    final handlePath = Path();
    handlePath.moveTo(w * 0.35, h * 0.9);
    handlePath.cubicTo(w * 0.3, h * 0.9, w * 0.35, h * 0.4, w * 0.45, h * 0.25);
    handlePath.quadraticBezierTo(w * 0.47, h * 0.2, w * 0.5, h * 0.15);
    handlePath.lineTo(w * 0.6, h * 0.15);
    handlePath.quadraticBezierTo(w * 0.56, h * 0.23, w * 0.53, h * 0.28);
    handlePath.cubicTo(w * 0.45, h * 0.45, w * 0.45, h * 0.9, w * 0.42, h * 0.9);
    handlePath.close();
    canvas.drawPath(handlePath, handlePaint);

    // Soft Grip Accent
    final gripPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.55), width: w * 0.04, height: h * 0.12),
      gripPaint,
    );

    // Brush head base (white plastic)
    final headPaint = Paint()
      ..color = const Color(0xFFF0F4F8)
      ..style = PaintingStyle.fill;
    
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.08, w * 0.18, h * 0.09),
      const Radius.circular(8),
    );
    canvas.drawRRect(headRect, headPaint);

    // Bristles (green/cyan)
    final bristlePaint = Paint()
      ..color = const Color(0xFF26D07C)
      ..style = PaintingStyle.fill;
    
    final bristleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.5, h * 0.02, w * 0.14, h * 0.07),
      const Radius.circular(3),
    );
    canvas.drawRRect(bristleRect, bristlePaint);

    // Paste dollop (cute toothpaste)
    final pastePaint = Paint()
      ..color = const Color(0xFFFF7675) // Pinkish paste
      ..style = PaintingStyle.fill;
    
    final pastePath = Path();
    pastePath.moveTo(w * 0.52, h * 0.02);
    pastePath.cubicTo(
      w * 0.5, -h * 0.04,
      w * 0.62, -h * 0.04,
      w * 0.6, h * 0.02,
    );
    pastePath.close();
    canvas.drawPath(pastePath, pastePaint);

    // Swirl highlight on paste
    final pasteHighlight = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.54, -h * 0.01), Offset(w * 0.57, -h * 0.015), pasteHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cartoon Mouthwash Bottle painter.
class MouthwashBottlePainter extends CustomPainter {
  final Color liquidColor;

  MouthwashBottlePainter({this.liquidColor = const Color(0xFF2ECC71)});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.9, w * 0.7, h * 0.08), shadowPaint);

    // Draw Cap
    final capPaint = Paint()
      ..color = const Color(0xFF2980B9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.1, w * 0.24, h * 0.12), const Radius.circular(6)),
      capPaint,
    );

    // Ribbed stripes on cap
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2;
    for (double i = 0.42; i <= 0.58; i += 0.04) {
      canvas.drawLine(Offset(w * i, h * 0.11), Offset(w * i, h * 0.21), linePaint);
    }

    // Neck of the bottle
    final neckPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.22, w * 0.14, h * 0.06), neckPaint);

    // Main Bottle Body (transparent glass containing colorful mouthwash liquid)
    final bottlePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final bottleOutline = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final bodyPath = Path();
    bodyPath.moveTo(w * 0.4, h * 0.28);
    bodyPath.quadraticBezierTo(w * 0.22, h * 0.32, w * 0.22, h * 0.42);
    bodyPath.lineTo(w * 0.22, h * 0.84);
    bodyPath.quadraticBezierTo(w * 0.22, h * 0.9, w * 0.32, h * 0.9);
    bodyPath.lineTo(w * 0.68, h * 0.9);
    bodyPath.quadraticBezierTo(w * 0.78, h * 0.9, w * 0.78, h * 0.84);
    bodyPath.lineTo(w * 0.78, h * 0.42);
    bodyPath.quadraticBezierTo(w * 0.78, h * 0.32, w * 0.6, h * 0.28);
    bodyPath.close();

    // Fill with liquid first
    final liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, liquidPaint);

    // Glass overlay & outline
    canvas.drawPath(bodyPath, bottlePaint);
    canvas.drawPath(bodyPath, bottleOutline);

    // White label on bottle
    final labelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.48, w * 0.36, h * 0.28),
      const Radius.circular(8),
    );
    canvas.drawRRect(labelRect, labelPaint);

    // Cute tooth shape on label (green/blue logo)
    final toothLogoPaint = Paint()
      ..color = liquidColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Draw simple mini-tooth in center of label
    canvas.drawCircle(Offset(w * 0.45, h * 0.58), w * 0.04, toothLogoPaint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.58), w * 0.04, toothLogoPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.58, w * 0.14, w * 0.06), toothLogoPaint);
    canvas.drawCircle(Offset(w * 0.45, h * 0.64), w * 0.02, toothLogoPaint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.64), w * 0.02, toothLogoPaint);

    // Bubbles inside liquid (child-like details)
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.3, h * 0.4), 4, bubblePaint);
    canvas.drawCircle(Offset(w * 0.33, h * 0.45), 2.5, bubblePaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.38), 3.5, bubblePaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.44), 5, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cartoon Dental Floss box painter.
class FlossBoxPainter extends CustomPainter {
  final Color boxColor;

  FlossBoxPainter({this.boxColor = const Color(0xFFFFA801)});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.9, w * 0.7, h * 0.08), shadowPaint);

    // Box body (rounded trapezoid/square)
    final bodyPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;

    final bodyPath = Path();
    bodyPath.moveTo(w * 0.25, h * 0.28);
    bodyPath.lineTo(w * 0.75, h * 0.28);
    bodyPath.quadraticBezierTo(w * 0.88, h * 0.28, w * 0.88, h * 0.4);
    bodyPath.lineTo(w * 0.82, h * 0.82);
    bodyPath.quadraticBezierTo(w * 0.8, h * 0.9, w * 0.7, h * 0.9);
    bodyPath.lineTo(w * 0.3, h * 0.9);
    bodyPath.quadraticBezierTo(w * 0.2, h * 0.9, w * 0.18, h * 0.82);
    bodyPath.lineTo(w * 0.12, h * 0.4);
    bodyPath.quadraticBezierTo(w * 0.12, h * 0.28, w * 0.25, h * 0.28);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Top Lid accent line
    final accentPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.15, h * 0.42), Offset(w * 0.85, h * 0.42), accentPaint);

    // Inner spool circle window (glass look)
    final spoolWindowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.2, spoolWindowPaint);

    // Inner white floss roll
    final rollPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.13, rollPaint);
    
    // Spool center hub
    final hubPaint = Paint()
      ..color = boxColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.05, hubPaint);

    // Silver clip on top (where floss is pulled)
    final clipPaint = Paint()
      ..color = const Color(0xFFBDC3C7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.22, w * 0.1, h * 0.07), clipPaint);

    // Floss thread coming out of the box
    final threadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final threadPath = Path();
    threadPath.moveTo(w * 0.5, h * 0.22);
    threadPath.quadraticBezierTo(w * 0.58, h * 0.12, w * 0.72, h * 0.18);
    canvas.drawPath(threadPath, threadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cartoon Cloud Painter.
class CloudPainter extends CustomPainter {
  final Color cloudColor;

  CloudPainter({this.cloudColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFFD3E7F3).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw main cloud shadow/bottom part
    final path = Path();
    path.moveTo(w * 0.2, h * 0.7);
    path.arcToPoint(Offset(w * 0.1, h * 0.5), radius: Radius.circular(w * 0.15));
    path.arcToPoint(Offset(w * 0.3, h * 0.25), radius: Radius.circular(w * 0.2));
    path.arcToPoint(Offset(w * 0.6, h * 0.2), radius: Radius.circular(w * 0.25));
    path.arcToPoint(Offset(w * 0.85, h * 0.4), radius: Radius.circular(w * 0.2));
    path.arcToPoint(Offset(w * 0.85, h * 0.7), radius: Radius.circular(w * 0.15));
    path.arcToPoint(Offset(w * 0.2, h * 0.7), radius: Radius.circular(w * 0.2));
    path.close();

    // Draw shadow offset slightly
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main cloud
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cloud Background Header for Auth Screen with kids and a giant tooth.
class AuthHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background Gradient (Sky blue to lighter sky blue)
    final rect = Rect.fromLTWH(0, 0, w, h);
    final bgGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF00A2E8),
        Color(0xFF35B8FF),
      ],
    );
    final bgPaint = Paint()..shader = bgGradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Draw cloud-like border frame at the bottom (arch layout)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPath = Path();
    borderPath.moveTo(0, h);
    borderPath.lineTo(0, h * 0.7);
    borderPath.quadraticBezierTo(w * 0.25, h * 0.55, w * 0.5, h * 0.7);
    borderPath.quadraticBezierTo(w * 0.75, h * 0.85, w, h * 0.7);
    borderPath.lineTo(w, h);
    borderPath.close();
    canvas.drawPath(borderPath, borderPaint);

    // Draw giant tooth character in the center, resting on the arch
    final toothCenter = Offset(w * 0.5, h * 0.58);
    final toothSize = size.width * 0.26;
    _drawGiantTooth(canvas, toothCenter, toothSize);

    // Draw cartoon kids standing on both sides
    _drawCartoonKidLeft(canvas, Offset(w * 0.25, h * 0.72), size.width * 0.16);
    _drawCartoonKidRight(canvas, Offset(w * 0.75, h * 0.72), size.width * 0.16);

    // Draw small floating clouds in sky
    _drawCloud(canvas, Offset(w * 0.15, h * 0.2), w * 0.2, h * 0.12);
    _drawCloud(canvas, Offset(w * 0.8, h * 0.25), w * 0.22, h * 0.13);
  }

  void _drawGiantTooth(Canvas canvas, Offset center, double size) {
    final w = size;
    final h = size;

    canvas.save();
    canvas.translate(center.dx - w / 2, center.dy - h / 2);

    final toothPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer shadow for the giant tooth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.85, w * 0.8, h * 0.1), shadowPaint);

    // Giant Tooth Path
    final path = Path();
    path.moveTo(w * 0.2, h * 0.25);
    path.cubicTo(w * 0.2, h * 0.1, w * 0.45, h * 0.1, w * 0.5, h * 0.22);
    path.cubicTo(w * 0.55, h * 0.1, w * 0.8, h * 0.1, w * 0.8, h * 0.25);
    path.cubicTo(w * 0.85, h * 0.4, w * 0.88, h * 0.6, w * 0.8, h * 0.75);
    path.cubicTo(w * 0.75, h * 0.85, w * 0.6, h * 0.9, w * 0.58, h * 0.78);
    path.cubicTo(w * 0.55, h * 0.7, w * 0.45, h * 0.7, w * 0.42, h * 0.78);
    path.cubicTo(w * 0.4, h * 0.9, w * 0.25, h * 0.85, w * 0.2, h * 0.75);
    path.cubicTo(w * 0.12, h * 0.6, w * 0.15, h * 0.4, w * 0.2, h * 0.25);
    path.close();
    canvas.drawPath(path, toothPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final reflectPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.35, h * 0.42), w * 0.06, eyePaint);
    canvas.drawCircle(Offset(w * 0.33, h * 0.4), w * 0.02, reflectPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.42), w * 0.06, eyePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.4), w * 0.02, reflectPaint);

    // Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..style = PaintingStyle.fill;
    final mouthPath = Path();
    mouthPath.moveTo(w * 0.42, h * 0.52);
    mouthPath.cubicTo(w * 0.45, h * 0.65, w * 0.55, h * 0.65, w * 0.58, h * 0.52);
    mouthPath.quadraticBezierTo(w * 0.5, h * 0.54, w * 0.42, h * 0.52);
    canvas.drawPath(mouthPath, mouthPaint);

    // Blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFFB5C5).withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04);
    canvas.drawCircle(Offset(w * 0.26, h * 0.5), w * 0.08, blushPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.5), w * 0.08, blushPaint);

    canvas.restore();
  }

  void _drawCartoonKidLeft(Canvas canvas, Offset origin, double size) {
    // Left Kid (Boy in red shirt)
    final paint = Paint();
    
    // Head / Face
    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(Offset(origin.dx, origin.dy - size * 0.6), size * 0.3, paint);

    // Hair (Brown, messy)
    paint.color = const Color(0xFF6E473B);
    final hairPath = Path();
    hairPath.moveTo(origin.dx - size * 0.35, origin.dy - size * 0.6);
    hairPath.quadraticBezierTo(origin.dx - size * 0.1, origin.dy - size * 0.98, origin.dx + size * 0.35, origin.dy - size * 0.6);
    hairPath.quadraticBezierTo(origin.dx, origin.dy - size * 0.7, origin.dx - size * 0.35, origin.dy - size * 0.6);
    canvas.drawPath(hairPath, paint);

    // Shirt (Red)
    paint.color = const Color(0xFFE74C3C);
    final shirtPath = Path();
    shirtPath.moveTo(origin.dx - size * 0.2, origin.dy - size * 0.3);
    shirtPath.lineTo(origin.dx + size * 0.2, origin.dy - size * 0.3);
    shirtPath.lineTo(origin.dx + size * 0.3, origin.dy);
    shirtPath.lineTo(origin.dx - size * 0.3, origin.dy);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    // Eyes
    paint.color = const Color(0xFF2C3E50);
    canvas.drawCircle(Offset(origin.dx - size * 0.08, origin.dy - size * 0.58), 2.5, paint);
    canvas.drawCircle(Offset(origin.dx + size * 0.08, origin.dy - size * 0.58), 2.5, paint);

    // Happy smile
    final smilePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(origin.dx, origin.dy - size * 0.52), width: 8, height: 6),
      0,
      math.pi,
      false,
      smilePaint,
    );
  }

  void _drawCartoonKidRight(Canvas canvas, Offset origin, double size) {
    // Right Kid (Girl in yellow shirt with pigtails)
    final paint = Paint();
    
    // Pigtails (Hair buns on sides)
    paint.color = const Color(0xFFF39C12); // Orange/Yellow hair
    canvas.drawCircle(Offset(origin.dx - size * 0.32, origin.dy - size * 0.72), size * 0.12, paint);
    canvas.drawCircle(Offset(origin.dx + size * 0.32, origin.dy - size * 0.72), size * 0.12, paint);

    // Head / Face
    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(Offset(origin.dx, origin.dy - size * 0.6), size * 0.3, paint);

    // Hair Front
    paint.color = const Color(0xFFF39C12);
    final hairPath = Path();
    hairPath.moveTo(origin.dx - size * 0.32, origin.dy - size * 0.62);
    hairPath.quadraticBezierTo(origin.dx, origin.dy - size * 0.95, origin.dx + size * 0.32, origin.dy - size * 0.62);
    hairPath.quadraticBezierTo(origin.dx, origin.dy - size * 0.72, origin.dx - size * 0.32, origin.dy - size * 0.62);
    canvas.drawPath(hairPath, paint);

    // Shirt (Teal/Green)
    paint.color = const Color(0xFF1ABC9C);
    final shirtPath = Path();
    shirtPath.moveTo(origin.dx - size * 0.2, origin.dy - size * 0.3);
    shirtPath.lineTo(origin.dx + size * 0.2, origin.dy - size * 0.3);
    shirtPath.lineTo(origin.dx + size * 0.28, origin.dy);
    shirtPath.lineTo(origin.dx - size * 0.28, origin.dy);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    // Eyes
    paint.color = const Color(0xFF2C3E50);
    canvas.drawCircle(Offset(origin.dx - size * 0.08, origin.dy - size * 0.58), 2.5, paint);
    canvas.drawCircle(Offset(origin.dx + size * 0.08, origin.dy - size * 0.58), 2.5, paint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(origin.dx, origin.dy - size * 0.52), width: 8, height: 6),
      0,
      math.pi,
      false,
      smilePaint,
    );
  }

  void _drawCloud(Canvas canvas, Offset center, double w, double h) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(center.dx - w * 0.3, center.dy + h * 0.2);
    path.arcToPoint(Offset(center.dx - w * 0.4, center.dy - h * 0.1), radius: Radius.circular(w * 0.2));
    path.arcToPoint(Offset(center.dx - w * 0.1, center.dy - h * 0.3), radius: Radius.circular(w * 0.25));
    path.arcToPoint(Offset(center.dx + w * 0.2, center.dy - h * 0.3), radius: Radius.circular(w * 0.3));
    path.arcToPoint(Offset(center.dx + w * 0.4, center.dy - h * 0.1), radius: Radius.circular(w * 0.25));
    path.arcToPoint(Offset(center.dx + w * 0.3, center.dy + h * 0.2), radius: Radius.circular(center.dy * 0.02));
    path.arcToPoint(Offset(center.dx - w * 0.3, center.dy + h * 0.2), radius: Radius.circular(w * 0.2));
    path.close();
    canvas.drawPath(path, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
