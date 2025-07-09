import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/gutter/widgets/painters/gutter_painter.dart';

class GutterWidget extends HookConsumerWidget {
  const GutterWidget({super.key, required this.textStyle});

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);

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
      );
      innerTextPainter.layout();

      return innerTextPainter;
    }, [editorState.buffer.version]);

    return CustomPaint(
      willChange: true,
      size: Size(70, 1000),
      painter: GutterPainter(textPainter: textPainter),
    );
  }
}
