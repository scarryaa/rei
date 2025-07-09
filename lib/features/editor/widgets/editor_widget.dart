import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/bridge/rust/api/cursor.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';

class EditorWidget extends HookConsumerWidget {
  const EditorWidget({
    super.key,
    required this.textStyle,
    required this.fontMetrics,
  });

  final TextStyle textStyle;
  final FontMetrics fontMetrics;

  Cursor _offsetToCursorPosition(
    Offset offset,
    GlobalKey painterKey,
    EditorState state,
    FontMetrics metrics,
  ) {
    final renderBox =
        painterKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final globalPosition = renderBox.globalToLocal(offset);
      final newRow = (globalPosition.dy / metrics.lineHeight).floor();
      final newColumn = (globalPosition.dx / metrics.charWidth).round();

      final lineCount = max(0, state.buffer.lineCount() - 1);
      final clampedRow = min(max(0, newRow), lineCount);
      final targetLineLength = state.buffer.lineLen(row: clampedRow);
      final clampedColumn = min(max(0, newColumn), targetLineLength);

      return Cursor(
        row: clampedRow,
        column: clampedColumn,
        stickyColumn: clampedColumn,
      );
    }

    return state.cursor;
  }

  void _handleTapDown(
    TapDownDetails details,
    GlobalKey painterKey,
    EditorState state,
    Editor notifier,
    FontMetrics metrics,
  ) {
    final newCursor = _offsetToCursorPosition(
      details.globalPosition,
      painterKey,
      state,
      metrics,
    );

    notifier.clearSelection();
    notifier.moveTo(newCursor);
  }

  void _handlePanStart(
    DragStartDetails details,
    GlobalKey painterKey,
    EditorState state,
    Editor notifier,
    FontMetrics metrics,
    ValueNotifier<bool> isDragging,
  ) {
    isDragging.value = true;

    final newCursor = _offsetToCursorPosition(
      details.globalPosition,
      painterKey,
      state,
      metrics,
    );

    notifier.clearSelection();
    notifier.startSelection(newCursor, true);
    notifier.moveTo(newCursor);
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    GlobalKey painterKey,
    EditorState state,
    Editor notifier,
    FontMetrics metrics,
    ValueNotifier<bool> isDragging,
  ) {
    if (isDragging.value) {
      final newCursor = _offsetToCursorPosition(
        details.globalPosition,
        painterKey,
        state,
        metrics,
      );

      notifier.updateSelection(newCursor, true);
      notifier.moveTo(newCursor);
    }
  }

  void _handlePanEnd(
    DragEndDetails details,
    GlobalKey painterKey,
    EditorState state,
    Editor notifier,
    FontMetrics metrics,
    ValueNotifier<bool> isDragging,
  ) {
    isDragging.value = false;
  }

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
    final verticalOffset = useState(0.0);
    final horizontalOffset = useState(0.0);
    final isDragging = useState(false);
    final GlobalKey painterKey = GlobalKey();

    useListenable(verticalScrollController);
    useListenable(horizontalScrollController);

    final padding = useMemoized(() {
      final verticalMultiplier = 5.0;
      final horizontalMultiplier = 8.0;

      final vertical = verticalMultiplier * fontMetrics.lineHeight;
      final horizontal = horizontalMultiplier * fontMetrics.charWidth;

      return (horizontal: horizontal, vertical: vertical);
    }, [fontMetrics]);

    final size = useMemoized(() {
      final lineCount = state.buffer.lineCountWithTrailingNewline();
      final maxLineLength = state.buffer.maxLineLength();
      final height = lineCount * fontMetrics.lineHeight;
      final width = maxLineLength * fontMetrics.charWidth;

      return Size(width + padding.horizontal, height + padding.vertical);
    }, [state.buffer.version, fontMetrics, padding]);

    // Scroll-to-cursor
    useEffect(() {
      if (!verticalScrollController.hasClients ||
          !verticalScrollController.position.hasViewportDimension ||
          !horizontalScrollController.hasClients ||
          !horizontalScrollController.position.hasViewportDimension) {
        return null;
      }

      void updateVerticalOffset(double newOffset) {
        if (verticalOffset.value != newOffset) {
          verticalOffset.value = newOffset;
        }
      }

      void updateHorizontalOffset(double newOffset) {
        if (horizontalOffset.value != newOffset) {
          horizontalOffset.value = newOffset;
        }
      }

      final cursorX = state.cursor.column * fontMetrics.charWidth;
      final cursorY = state.cursor.row * fontMetrics.lineHeight;

      final verticalScrollOffset = verticalScrollController.offset;
      final horizontalScrollOffset = horizontalScrollController.offset;
      final viewportHeight =
          verticalScrollController.position.viewportDimension;
      final viewportWidth =
          horizontalScrollController.position.viewportDimension;

      // Vertical scroll
      if (cursorY - padding.vertical < verticalScrollOffset) {
        final double newOffset = min(
          max(0, cursorY - padding.vertical),
          size.height - viewportHeight,
        );

        updateVerticalOffset(newOffset);
        verticalScrollController.jumpTo(newOffset);
      } else if (cursorY >
          verticalScrollOffset +
              viewportHeight -
              padding.vertical -
              fontMetrics.lineHeight) {
        final double newOffset = min(
          cursorY + padding.vertical + fontMetrics.lineHeight - viewportHeight,
          size.height - viewportHeight,
        );

        updateVerticalOffset(newOffset);
        verticalScrollController.jumpTo(newOffset);
      }

      // Horizontal scroll
      if (cursorX - padding.horizontal < horizontalScrollOffset) {
        final double newOffset = min(
          max(0, cursorX - padding.horizontal),
          size.width - viewportWidth,
        );

        updateHorizontalOffset(newOffset);
        horizontalScrollController.jumpTo(newOffset);
      } else if (cursorX >
          horizontalScrollOffset + viewportWidth - padding.horizontal) {
        final double newOffset = min(
          max(0, cursorX + padding.horizontal - viewportWidth),
          size.width - viewportWidth,
        );

        updateHorizontalOffset(newOffset);
        horizontalScrollController.jumpTo(newOffset);
      }

      return null;
    }, [state.cursor]);

    useEffect(() {
      void updateVerticalOffset() {
        if (!verticalScrollController.hasClients ||
            !verticalScrollController.position.hasContentDimensions) {
          return;
        }

        final newOffset = min(
          verticalScrollController.offset,
          verticalScrollController.position.maxScrollExtent,
        );

        if (verticalOffset.value != newOffset) {
          verticalOffset.value = newOffset;
        }
      }

      void updateHorizontalOffset() {
        if (!horizontalScrollController.hasClients ||
            !horizontalScrollController.position.hasContentDimensions) {
          return;
        }

        final newOffset = min(
          horizontalScrollController.offset,
          horizontalScrollController.position.maxScrollExtent,
        );

        if (horizontalOffset.value != newOffset) {
          horizontalOffset.value = newOffset;
        }
      }

      void verticalScrollListener() {
        updateVerticalOffset();
      }

      void horizontalScrollListener() {
        updateHorizontalOffset();
      }

      verticalScrollController.addListener(verticalScrollListener);
      updateVerticalOffset();

      horizontalScrollController.addListener(horizontalScrollListener);
      updateHorizontalOffset();

      return () {
        verticalScrollController.removeListener(verticalScrollListener);
        horizontalScrollController.removeListener(horizontalScrollListener);
      };
    }, [state.buffer.version, state.cursor]);

    final visibleLines = useMemoized(() {
      if (!verticalScrollController.hasClients ||
          !verticalScrollController.position.hasViewportDimension) {
        return (first: 0, last: 0);
      }

      final viewportHeight =
          verticalScrollController.position.viewportDimension;
      double verticalOffset;
      if (verticalScrollController.offset + viewportHeight > size.height) {
        verticalOffset = size.height - viewportHeight;
      } else {
        verticalOffset = verticalScrollController.offset;
      }

      final firstVisibleLine = max(
        0,
        min(
          ((verticalOffset) / fontMetrics.lineHeight).floor(),
          state.buffer.lineCount() - 1,
        ),
      );
      final lastVisibleLine = max(
        0,
        min(
          ((verticalOffset + viewportHeight) / fontMetrics.lineHeight).ceil(),
          state.buffer.lineCount(),
        ),
      );

      return (first: firstVisibleLine, last: lastVisibleLine);
    }, [state.buffer.version, state.cursor, verticalOffset.value, size]);

    final charOffset = useMemoized(() {
      if (!verticalScrollController.hasClients ||
          !verticalScrollController.position.hasViewportDimension ||
          state.buffer.lineCount() == 0) {
        return (start: 0, end: 0);
      }

      final firstChar = state.buffer.byteOfLine(row: visibleLines.first);
      final lastChar =
          state.buffer.byteOfLine(row: visibleLines.last - 1) +
          state.buffer.lineLen(row: visibleLines.last - 1) +
          1;

      return (start: firstChar, end: lastChar);
    }, [visibleLines, state.buffer.version]);

    final visibleChars = useMemoized(
      () {
        if (!horizontalScrollController.hasClients ||
            !horizontalScrollController.position.hasViewportDimension) {
          return (first: 0, last: 0);
        }

        final viewportWidth =
            horizontalScrollController.position.viewportDimension;
        final horizontalOffset = horizontalScrollController.offset;

        final firstChar = max(
          0,
          (horizontalOffset / fontMetrics.charWidth).floor(),
        );
        final lastChar =
            ((horizontalOffset + viewportWidth) / fontMetrics.charWidth).ceil();

        return (first: firstChar, last: lastChar);
      },
      [
        visibleLines,
        state.buffer.version,
        state.cursor,
        horizontalOffset.value,
      ],
    );

    final textPainter = useMemoized(() {
      final innerTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: state.buffer.textInRangeCharOffset(
            startRow: visibleLines.first,
            endRow: visibleLines.last,
            startCharOffset: visibleChars.first,
            endCharOffset: visibleChars.last,
          ),
          style: textStyle,
        ),
      );
      innerTextPainter.layout();

      return innerTextPainter;
    }, [state.buffer.version, visibleLines, visibleChars]);

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
                    child: GestureDetector(
                      onTapDown: (details) => _handleTapDown(
                        details,
                        painterKey,
                        state,
                        notifier,
                        fontMetrics,
                      ),
                      onPanStart: (details) => _handlePanStart(
                        details,
                        painterKey,
                        state,
                        notifier,
                        fontMetrics,
                        isDragging,
                      ),
                      onPanUpdate: (details) => _handlePanUpdate(
                        details,
                        painterKey,
                        state,
                        notifier,
                        fontMetrics,
                        isDragging,
                      ),
                      onPanEnd: (details) => _handlePanEnd(
                        details,
                        painterKey,
                        state,
                        notifier,
                        fontMetrics,
                        isDragging,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.text,
                        child: CustomPaint(
                          key: painterKey,
                          size: newSize,
                          willChange: true,
                          isComplex: true,
                          painter: EditorPainter(
                            textPainter: textPainter,
                            buffer: state.buffer,
                            cursor: state.cursor,
                            selection: state.selection,
                            fontMetrics: fontMetrics,
                            firstVisibleLine: visibleLines.first,
                            startCharOffset: charOffset.start,
                            endCharOffset: charOffset.end,
                            firstVisibleChar: visibleChars.first,
                          ),
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
