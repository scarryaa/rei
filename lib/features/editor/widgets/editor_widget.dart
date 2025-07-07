import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends HookConsumerWidget {
  const EditorWidget({super.key});

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    EditorState state,
    Editor notifier,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
        notifier.insert('\n');

      case LogicalKeyboardKey.backspace:
        notifier.removeChar();

      default:
        if (event.character != null) {
          notifier.insert(event.character!);
        }
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final state = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    final textStyle = useMemoized(
      () => TextStyle(
        fontSize: 15.0,
        fontFamily: 'IBM Plex Mono',
        color: Colors.white,
      ),
    );

    final textPainter = useMemoized(() {
      final innerTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: state.buffer.toString(), style: textStyle),
      );
      innerTextPainter.layout();

      return innerTextPainter;
    }, [state.buffer.version]);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) =>
          _handleKeyEvent(node, event, state, notifier),
      child: CustomPaint(
        willChange: true,
        isComplex: true,
        painter: EditorPainter(
          textPainter: textPainter,
          buffer: state.buffer,
          cursor: state.cursor,
        ),
      ),
    );
  }
}
