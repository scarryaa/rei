import 'package:flutter/material.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends StatelessWidget {
  const EditorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'Hello world',
        style: TextStyle(
          fontSize: 15.0,
          fontFamily: 'IBM Plex Mono',
          color: Colors.white,
        ),
      ),
    );
    textPainter.layout();

    return CustomPaint(painter: EditorPainter(textPainter: textPainter));
  }
}
