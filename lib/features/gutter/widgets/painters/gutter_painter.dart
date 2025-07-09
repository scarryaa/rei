import 'package:flutter/widgets.dart';
import 'package:rei/features/editor/models/font_metrics.dart';

class GutterPainter extends CustomPainter {
  GutterPainter({
    required this.textPainter,
    required this.visibleLines,
    required this.fontMetrics,
  });

  final TextPainter textPainter;
  final ({int first, int last}) visibleLines;
  final FontMetrics fontMetrics;

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(canvas, size);
  }

  void drawLines(Canvas canvas, Size size) {
    final xOffset = (size.width - textPainter.width) / 2;
    final yOffset = visibleLines.first * fontMetrics.lineHeight;

    textPainter.paint(canvas, Offset(xOffset, yOffset));
  }

  @override
  bool shouldRepaint(covariant GutterPainter oldDelegate) {
    return oldDelegate.visibleLines.first != visibleLines.first ||
        oldDelegate.visibleLines.last != visibleLines.last ||
        oldDelegate.fontMetrics != fontMetrics;
  }
}
