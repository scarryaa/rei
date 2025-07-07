import 'package:flutter/material.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends StatelessWidget {
  const EditorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: EditorPainter());
  }
}
