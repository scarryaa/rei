import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/gutter/widgets/painters/gutter_painter.dart';

class GutterWidget extends HookConsumerWidget {
  const GutterWidget({
    super.key,
    required this.textStyle,
    required this.fontMetrics,
  });

  final TextStyle textStyle;
  final FontMetrics fontMetrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final padding = useMemoized(() {
      final verticalMultiplier = 5.0;
      final horizontalMultiplier = 8.0;

      final vertical = verticalMultiplier * fontMetrics.lineHeight;
      final horizontal = horizontalMultiplier * fontMetrics.charWidth;

      return (horizontal: horizontal, vertical: vertical);
    }, [fontMetrics]);

    final textPainter = useMemoized(() {
      String text = '';
      for (
        var i = 0;
        i < max(1, editorState.buffer.lineCountWithTrailingNewline());
        i++
      ) {
        text += '${i + 1}\n';
      }

      final innerTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(color: Color(0x50FFFFFF)),
        ),
        textAlign: TextAlign.end,
      );
      innerTextPainter.layout();

      return innerTextPainter;
    }, [editorState.buffer.version]);

    final size = useMemoized(() {
      final width = textPainter.width + padding.horizontal;
      final height =
          (editorState.buffer.lineCountWithTrailingNewline() *
              fontMetrics.lineHeight) +
          padding.vertical;

      return Size(width, height);
    }, [padding, fontMetrics, editorState.buffer.version]);

    return CustomPaint(
      willChange: true,
      size: size,
      painter: GutterPainter(textPainter: textPainter),
    );
  }
}
