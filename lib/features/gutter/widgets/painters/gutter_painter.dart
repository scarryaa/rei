import 'package:flutter/widgets.dart';

class GutterPainter extends CustomPainter {
  GutterPainter({required this.textPainter});

  TextPainter textPainter;

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(canvas, size);
  }

  void drawLines(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
