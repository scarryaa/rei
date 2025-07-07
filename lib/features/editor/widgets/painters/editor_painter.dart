import 'package:flutter/material.dart';
import 'package:rei/bridge/rust/api/buffer.dart';
import 'package:rei/bridge/rust/api/cursor.dart';

class EditorPainter extends CustomPainter {
  EditorPainter({
    required this.textPainter,
    required this.buffer,
    required this.cursor,
  });

  final TextPainter textPainter;
  final Buffer buffer;
  final Cursor cursor;

  static final Color cursorColor = Colors.lightBlue;
  static const double cursorWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant EditorPainter oldDelegate) {
    return oldDelegate.buffer.version != buffer.version ||
        oldDelegate.textPainter != textPainter ||
        oldDelegate.cursor != cursor;
  }
}
