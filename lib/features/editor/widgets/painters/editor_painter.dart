import 'package:flutter/widgets.dart';

class EditorPainter extends CustomPainter {
  EditorPainter({required this.textPainter});

  final TextPainter textPainter;

  @override
  void paint(Canvas canvas, Size size) {
    drawText(canvas, size);
  }

  void drawText(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
