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
    required this.firstVisibleLine,
    required this.firstVisibleChar,
    required this.startCharOffset,
    required this.endCharOffset,
  });

  final TextPainter textPainter;
  final Buffer buffer;
  final Cursor cursor;
  final Selection selection;
  final FontMetrics fontMetrics;
  final int firstVisibleLine;
  final int firstVisibleChar;
  final int startCharOffset;
  final int endCharOffset;

  static final Color cursorColor = Colors.lightBlue;
  static final Color selectionColor = Colors.lightBlue.withValues(alpha: 0.3);
  static const double cursorWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate(
      firstVisibleChar * fontMetrics.charWidth,
      firstVisibleLine * fontMetrics.lineHeight,
    );

    drawSelection(canvas, size);
    drawText(canvas, size);
    drawCursor(canvas, size);
  }

  void drawText(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  void drawCursor(Canvas canvas, Size size) {
    final actualColumn = cursor.column - firstVisibleChar;

    if (actualColumn < 0) return;

    final cursorX = actualColumn * fontMetrics.charWidth;
    final cursorY = (cursor.row - firstVisibleLine) * fontMetrics.lineHeight;

    final rect = Rect.fromLTWH(
      cursorX,
      cursorY,
      cursorWidth,
      fontMetrics.lineHeight,
    );

    canvas.drawRect(rect, Paint()..color = cursorColor);
  }

  void drawSelection(Canvas canvas, Size size) {
    final normalized = selection.normalized();
    final visibleLineCount = (size.height / fontMetrics.lineHeight).ceil();

    if (normalized.isEmpty()) {
      return;
    }

    if (normalized.end.row < firstVisibleLine ||
        normalized.start.row >= firstVisibleLine + visibleLineCount) {
      return;
    }

    for (int row = normalized.start.row; row <= normalized.end.row; row++) {
      if (row < firstVisibleLine ||
          row >= firstVisibleLine + visibleLineCount) {
        continue;
      }

      final lineLength = buffer.lineLen(row: row);
      int startCol, endCol;

      if (row == normalized.start.row) {
        startCol = normalized.start.column;
      } else {
        startCol = 0;
      }

      if (row == normalized.end.row) {
        endCol = normalized.end.column;
      } else {
        endCol = lineLength;
      }

      final visibleStartCol = startCol - firstVisibleChar;
      final visibleEndCol = endCol - firstVisibleChar;

      final maxVisibleChars = (size.width / fontMetrics.charWidth).ceil();

      if (visibleEndCol < 0 || visibleStartCol >= maxVisibleChars) {
        continue;
      }

      final drawStartCol = visibleStartCol.clamp(0, double.infinity).toInt();
      final drawEndCol = visibleEndCol
          .clamp(0, (size.width / fontMetrics.charWidth).ceil())
          .toInt();

      final selectionWidth =
          (drawEndCol - drawStartCol) * fontMetrics.charWidth;
      final finalWidth =
          (selectionWidth <= 0 ||
              (endCol > lineLength && drawEndCol > drawStartCol))
          ? fontMetrics.charWidth
          : selectionWidth;

      final selectionX = drawStartCol * fontMetrics.charWidth;
      final selectionY = (row - firstVisibleLine) * fontMetrics.lineHeight;

      final rect = Rect.fromLTWH(
        selectionX,
        selectionY,
        finalWidth,
        fontMetrics.lineHeight,
      );

      canvas.drawRect(rect, Paint()..color = selectionColor);
    }
  }

  @override
  bool shouldRepaint(covariant EditorPainter oldDelegate) {
    return oldDelegate.buffer.version != buffer.version ||
        oldDelegate.textPainter != textPainter ||
        oldDelegate.cursor != cursor ||
        oldDelegate.selection != selection ||
        oldDelegate.firstVisibleLine != firstVisibleLine ||
        oldDelegate.firstVisibleChar != firstVisibleChar;
  }
}
