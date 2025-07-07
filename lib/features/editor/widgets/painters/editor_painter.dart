import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rei/bridge/rust/api/buffer.dart';
import 'package:rei/bridge/rust/api/cursor.dart';
import 'package:rei/bridge/rust/api/selection.dart';
import 'package:rei/features/editor/models/font_metrics.dart';

class EditorPainter extends CustomPainter {
  EditorPainter({
    required this.textPainter,
    required this.buffer,
    required this.cursor,
    required this.selection,
    required this.fontMetrics,
  });

  final TextPainter textPainter;
  final Buffer buffer;
  final Cursor cursor;
  final Selection selection;
  final FontMetrics fontMetrics;

  static final Color cursorColor = Colors.lightBlue;
  static final Color selectionColor = Colors.lightBlue.withValues(alpha: 0.3);
  static const double cursorWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    drawSelection(canvas, size);
    drawText(canvas, size);
    drawCursor(canvas, size);
  }

  void drawText(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  void drawCursor(Canvas canvas, Size size) {
    final offset = buffer.rowColumnToIdx(
      row: cursor.row,
      column: cursor.column,
    );
    final position = TextPosition(offset: offset);
    final cursorOffset = textPainter.getOffsetForCaret(position, Rect.zero);
    final rect = Rect.fromLTWH(
      cursorOffset.dx,
      cursorOffset.dy,
      cursorWidth,
      textPainter.preferredLineHeight,
    );

    canvas.drawRect(rect, Paint()..color = cursorColor);
  }

  void drawSelection(Canvas canvas, Size size) {
    final normalized = selection.normalized();

    final baseOffset = buffer.rowColumnToIdx(
      row: normalized.start.row,
      column: normalized.start.column,
    );
    final extentOffset = buffer.rowColumnToIdx(
      row: normalized.end.row,
      column: normalized.end.column,
    );

    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      boxHeightStyle: BoxHeightStyle.max,
    );

    for (final box in boxes) {
      final rect = box.toRect();

      // Handle empty lines.
      if (rect.width == 0) {
        final newRect = Rect.fromLTWH(
          0,
          rect.top,
          fontMetrics.charWidth,
          fontMetrics.lineHeight,
        );
        canvas.drawRect(newRect, Paint()..color = selectionColor);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.top,
            rect.width,
            fontMetrics.lineHeight,
          ),
          Paint()..color = selectionColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EditorPainter oldDelegate) {
    return oldDelegate.buffer.version != buffer.version ||
        oldDelegate.textPainter != textPainter ||
        oldDelegate.cursor != cursor ||
        oldDelegate.selection != selection;
  }
}
