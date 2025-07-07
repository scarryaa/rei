import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends HookConsumerWidget {
  const EditorWidget({super.key});

  void _handlePaste(EditorState state, Editor notifier) async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && text.isNotEmpty) {
      notifier.insert(text);
    }
  }

  bool _handleShortcuts(KeyEvent event, EditorState state, Editor notifier) {
    bool isSuperPressed;
    if (Platform.isMacOS) {
      isSuperPressed = HardwareKeyboard.instance.isMetaPressed;
    } else {
      isSuperPressed = HardwareKeyboard.instance.isControlPressed;
    }
    bool handled = false;

    switch (event.logicalKey) {
      // Select All
      case LogicalKeyboardKey.keyA:
        if (isSuperPressed) {
          notifier.selectAll();
          handled = true;
        }

      // Cut
      case LogicalKeyboardKey.keyX:
        if (isSuperPressed) {
          final text = notifier.getSelectedText();
          if (text.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: text));
          }
          notifier.deleteSelection();
          handled = true;
        }

      // Copy
      case LogicalKeyboardKey.keyC:
        if (isSuperPressed) {
          final text = notifier.getSelectedText();
          if (text.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: text));
          }
          handled = true;
        }

      // Paste
      case LogicalKeyboardKey.keyV:
        if (isSuperPressed) {
          _handlePaste(state, notifier);
          handled = true;
        }
    }

    return handled;
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    EditorState state,
    Editor notifier,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Handle shortcuts
    if (_handleShortcuts(event, state, notifier)) {
      return KeyEventResult.handled;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
        notifier.insert('\n');

      case LogicalKeyboardKey.backspace:
        notifier.removeChar();

      case LogicalKeyboardKey.escape:
        notifier.clearSelection();

      // Arrow Keys
      case LogicalKeyboardKey.arrowLeft:
        notifier.moveLeft(isShiftPressed);
      case LogicalKeyboardKey.arrowRight:
        notifier.moveRight(isShiftPressed);
      case LogicalKeyboardKey.arrowUp:
        notifier.moveUp(isShiftPressed);
      case LogicalKeyboardKey.arrowDown:
        notifier.moveDown(isShiftPressed);

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
    final verticalScrollController = useScrollController();
    final horizontalScrollController = useScrollController();

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

    final fontMetrics = useMemoized(() {
      final innerCharPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: 'W', style: textStyle),
      );
      innerCharPainter.layout();

      return FontMetrics(
        lineHeight: innerCharPainter.preferredLineHeight,
        charWidth: innerCharPainter.width,
      );
    }, [textStyle]);

    final padding = useMemoized(() {
      final verticalMultiplier = 5.0;
      final horizontalMultiplier = 8.0;

      final vertical = verticalMultiplier * fontMetrics.lineHeight;
      final horizontal = horizontalMultiplier * fontMetrics.charWidth;

      return (horizontal: horizontal, vertical: vertical);
    }, [fontMetrics]);

    final size = useMemoized(() {
      final lineCount = state.buffer.lineCount();
      final maxLineLength = state.buffer.maxLineLength();
      final height = lineCount * fontMetrics.lineHeight;
      final width = maxLineLength * fontMetrics.charWidth;

      return Size(width + padding.horizontal, height + padding.vertical);
    }, [state.buffer.version, fontMetrics, padding]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = max(size.width, constraints.maxWidth);
        final height = max(size.height, constraints.maxHeight);
        Size newSize = Size(width, height);

        return Scrollbar(
          controller: verticalScrollController,
          child: Scrollbar(
            controller: horizontalScrollController,
            notificationPredicate: (notification) => notification.depth == 1,
            child: ScrollConfiguration(
              behavior: ScrollBehavior().copyWith(
                scrollbars: false,
                overscroll: false,
                physics: ClampingScrollPhysics(),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: verticalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: horizontalScrollController,
                  child: Focus(
                    autofocus: true,
                    focusNode: focusNode,
                    onKeyEvent: (node, event) =>
                        _handleKeyEvent(node, event, state, notifier),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.text,
                      child: CustomPaint(
                        size: newSize,
                        willChange: true,
                        isComplex: true,
                        painter: EditorPainter(
                          textPainter: textPainter,
                          buffer: state.buffer,
                          cursor: state.cursor,
                          selection: state.selection,
                          fontMetrics: fontMetrics,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
