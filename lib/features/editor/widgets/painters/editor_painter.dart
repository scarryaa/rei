import 'package:flutter/widgets.dart';
import 'package:rei/bridge/rust/api/buffer.dart';

class EditorPainter extends CustomPainter {
  EditorPainter({required this.textPainter, required this.buffer});

  final TextPainter textPainter;
  final Buffer buffer;

  @override
  void paint(Canvas canvas, Size size) {
    drawText(canvas, size);
  }

  void drawText(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant EditorPainter oldDelegate) {
    return oldDelegate.buffer.version != buffer.version ||
        oldDelegate.textPainter != textPainter;
  }
}
