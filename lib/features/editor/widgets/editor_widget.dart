import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends HookConsumerWidget {
  const EditorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
