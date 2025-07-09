import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/models/state.dart';

class GutterPainter extends CustomPainter {
  GutterPainter({
    required this.visibleLines,
    required this.fontMetrics,
    required this.state,
    required this.textStyle,
  });

  final ({int first, int last}) visibleLines;
  final FontMetrics fontMetrics;
  final EditorState state;
  final TextStyle textStyle;

  final TextPainter textPainter = TextPainter();

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(canvas, size);
  }

  void drawLines(Canvas canvas, Size size) {
    final widthAdjustment =
        state.buffer.lineCountWithTrailingNewline().toString().length *
        fontMetrics.charWidth /
        2;

    for (int i = visibleLines.first; i < max(1, visibleLines.last); i++) {
      final lineHasCursor = state.cursor.row == i;
      final lineHasSelection = state.selection.normalized().contains(row: i);
      final modifiedTextStyle = textStyle.copyWith(
        color: (lineHasCursor || lineHasSelection)
            ? Colors.white
            : Color(0x50FFFFFF),
      );

      textPainter
        ..textDirection = TextDirection.ltr
        ..text = TextSpan(text: (i + 1).toString(), style: modifiedTextStyle)
        ..textAlign = TextAlign.end
        ..layout();

      final xOffset = (size.width / 2) - textPainter.width + widthAdjustment;
      final yOffset = i * fontMetrics.lineHeight;

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }
  }

  @override
  bool shouldRepaint(covariant GutterPainter oldDelegate) {
    return oldDelegate.visibleLines.first != visibleLines.first ||
        oldDelegate.visibleLines.last != visibleLines.last ||
        oldDelegate.fontMetrics != fontMetrics ||
        oldDelegate.state.buffer.version != state.buffer.version ||
        oldDelegate.state.cursor != state.cursor ||
        oldDelegate.state.selection != state.selection ||
        oldDelegate.state != state;
  }
}
