import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart' hide Tab;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/bridge/rust/api/cursor.dart';
import 'package:rei/features/editor/models/char_offset.dart';
import 'package:rei/features/editor/models/editor_padding.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/models/visible_chars.dart';
import 'package:rei/features/editor/models/visible_lines.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/features/editor/widgets/painters/editor_painter.dart';
import 'package:rei/shared/providers/scroll_sync.dart';
import 'package:rei/shared/services/file_service.dart';

class EditorWidget extends HookConsumerWidget {
  const EditorWidget({
    super.key,
    required this.textStyle,
    required this.fontMetrics,
  });

  final TextStyle textStyle;
  final FontMetrics fontMetrics;

  void _handleSave(
    EditorState state,
    Editor notifier,
    TabState activeTab,
    Tab tabNotifier,
  ) {
    final content = state.buffer.toString();

    FileService.writeFile(activeTab.path, content);
    tabNotifier.updateOriginalContent(activeTab.path, content);
  }

  Future<void> _handleSaveAs(
    EditorState state,
    Editor notifier,
    TabState activeTab,
    Tab tabNotifier,
  ) async {
    final content = state.buffer.toString();

    final newPath = await FileService.writeFileAs(activeTab.path, content);

    if (newPath != null) {
      tabNotifier.updateOriginalContent(activeTab.path, content);
      tabNotifier.updatePath(activeTab.path, newPath);
    }
  }

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

      final lineCount = max(0, state.buffer.lineCountWithTrailingNewline() - 1);
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
    FocusNode focusNode,
    EditorState state,
    Editor notifier,
    FontMetrics metrics,
  ) {
    focusNode.requestFocus();

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

  bool _handleShortcuts(
    KeyEvent event,
    EditorState state,
    Editor notifier,
    ValueNotifier<bool> shouldAutoScroll,
    TabState activeTab,
    Tab tabNotifier,
  ) {
    bool isSuperPressed;
    if (Platform.isMacOS) {
      isSuperPressed = HardwareKeyboard.instance.isMetaPressed;
    } else {
      isSuperPressed = HardwareKeyboard.instance.isControlPressed;
    }
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    bool handled = false;

    switch (event.logicalKey) {
      // Select All
      case LogicalKeyboardKey.keyA:
        if (isSuperPressed) {
          notifier.selectAll();
          shouldAutoScroll.value = false;
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

      case LogicalKeyboardKey.keyS:
        if (isSuperPressed) {
          if (isShiftPressed) {
            _handleSaveAs(state, notifier, activeTab, tabNotifier);
            handled = true;
          } else {
            _handleSave(state, notifier, activeTab, tabNotifier);
            handled = true;
          }
        }
    }

    return handled;
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    EditorState state,
    Editor notifier,
    ValueNotifier<bool> shouldAutoScroll,
    TabState activeTab,
    Tab tabNotifier,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Handle shortcuts
    if (_handleShortcuts(
      event,
      state,
      notifier,
      shouldAutoScroll,
      activeTab,
      tabNotifier,
    )) {
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
    final state = ref.watch(activeEditorProvider);
    final activeTab = ref.watch(activeTabProvider);
    final notifier = ref.read(editorProvider(activeTab?.path ?? '').notifier);
    final tabNotifier = ref.read(tabProvider.notifier);

    final verticalScrollController = useScrollController(
      keys: [activeTab!.path],
    );
    final horizontalScrollController = useScrollController(
      keys: [activeTab.path],
    );

    final scrollSyncState = ref.watch(scrollSyncProvider);
    final scrollSyncNotifier = ref.read(scrollSyncProvider.notifier);

    final verticalOffset = useState(0.0);
    final horizontalOffset = useState(0.0);
    final isDragging = useState(false);
    final shouldAutoScroll = useState(true);
    final viewportHeight = useState(0.0);
    final viewportWidth = useState(0.0);
    final GlobalKey painterKey = GlobalKey();

    final scrollSync = useMemoized(
      () => verticalScrollController.createSync('editor', scrollSyncNotifier),
      [verticalScrollController, scrollSyncNotifier],
    );

    useListenable(verticalScrollController);
    useListenable(horizontalScrollController);

    useEffect(() {
      scrollSync.startListening();
      return () => scrollSync.stopListening();
    }, [scrollSync]);

    useEffect(() {
      if (scrollSyncState.activeController != null &&
          scrollSyncState.activeController != 'editor' &&
          scrollSyncState.isScrolling) {
        scrollSync.syncTo(scrollSyncState.offset);
      }

      return null;
    }, [scrollSyncState.offset, scrollSyncState.activeController]);

    final padding = useMemoized(() {
      final verticalMultiplier = 5.0;
      final horizontalMultiplier = 8.0;

      final vertical = verticalMultiplier * fontMetrics.lineHeight;
      final horizontal = horizontalMultiplier * fontMetrics.charWidth;

      return EditorPadding(horizontal: horizontal, vertical: vertical);
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
      if (!shouldAutoScroll.value) {
        shouldAutoScroll.value = true;
        return null;
      }

      if (!verticalScrollController.hasClients ||
          !verticalScrollController.position.hasViewportDimension ||
          !horizontalScrollController.hasClients ||
          !horizontalScrollController.position.hasViewportDimension) {
        return null;
      }

      void updateVerticalOffset(double newOffset) {
        if (verticalOffset.value != newOffset) {
          verticalOffset.value = newOffset;

          Future.microtask(() {
            final currentPath = activeTab.path;

            ref
                .read(tabProvider.notifier)
                .updateScrollOffset(
                  currentPath,
                  Offset(horizontalOffset.value, newOffset),
                );
          });
        }
      }

      void updateHorizontalOffset(double newOffset) {
        if (horizontalOffset.value != newOffset) {
          horizontalOffset.value = newOffset;

          Future.microtask(() {
            final currentPath = activeTab.path;

            ref
                .read(tabProvider.notifier)
                .updateScrollOffset(
                  currentPath,
                  Offset(newOffset, verticalOffset.value),
                );
          });
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

      scrollSyncNotifier.startScrolling('editor');

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
    }, [state.cursor, state.selection]);

    useEffect(() {
      bool restored = false;

      void maybeRestoreScroll() {
        if (!restored &&
            verticalScrollController.hasClients &&
            horizontalScrollController.hasClients) {
          verticalOffset.value = activeTab.scrollOffset.dy;
          horizontalOffset.value = activeTab.scrollOffset.dx;

          verticalScrollController.jumpTo(activeTab.scrollOffset.dy);
          horizontalScrollController.jumpTo(activeTab.scrollOffset.dx);

          // Hacky way to force the gutter to update.
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          verticalScrollController.notifyListeners();
          restored = true;
        }
      }

      Future.microtask(() {
        maybeRestoreScroll();
      });

      return () {
        verticalScrollController.removeListener(maybeRestoreScroll);
        horizontalScrollController.removeListener(maybeRestoreScroll);
      };
    }, [activeTab.path]);

    useEffect(
      () {
        void updateVerticalOffset() {
          Future.microtask(() {
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

              final currentPath = activeTab.path;

              ref
                  .read(tabProvider.notifier)
                  .updateScrollOffset(
                    currentPath,
                    Offset(horizontalOffset.value, newOffset),
                  );
            }
          });
        }

        void updateHorizontalOffset() {
          Future.microtask(() {
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

              final currentPath = activeTab.path;

              ref
                  .read(tabProvider.notifier)
                  .updateScrollOffset(
                    currentPath,
                    Offset(newOffset, verticalOffset.value),
                  );
            }
          });
        }

        void verticalScrollListener() => updateVerticalOffset();
        void horizontalScrollListener() => updateHorizontalOffset();

        verticalScrollController.addListener(verticalScrollListener);
        updateVerticalOffset();
        horizontalScrollController.addListener(horizontalScrollListener);
        updateHorizontalOffset();

        return () {
          verticalScrollController.removeListener(verticalScrollListener);
          horizontalScrollController.removeListener(horizontalScrollListener);
        };
      },
      [
        state.buffer.version,
        state.cursor,
        verticalOffset.value,
        horizontalOffset.value,
      ],
    );

    final visibleLines = useMemoized(
      () {
        if (!verticalScrollController.hasClients ||
            !verticalScrollController.position.hasViewportDimension) {
          final firstVisibleLine = 0;
          final lastVisibleLine = max(
            0,
            min(
              ((viewportHeight.value) / fontMetrics.lineHeight).ceil(),
              state.buffer.lineCount(),
            ),
          );

          return VisibleLines(first: firstVisibleLine, last: lastVisibleLine);
        }

        final scrollViewportHeight =
            verticalScrollController.position.viewportDimension;
        double verticalOffset;
        if (verticalScrollController.offset + scrollViewportHeight >
            size.height) {
          verticalOffset = size.height - scrollViewportHeight;
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
            ((verticalOffset + scrollViewportHeight) / fontMetrics.lineHeight)
                .ceil(),
            state.buffer.lineCount(),
          ),
        );

        return VisibleLines(first: firstVisibleLine, last: lastVisibleLine);
      },
      [
        state.buffer.version,
        state.cursor,
        verticalOffset.value,
        horizontalOffset.value,
        activeTab.path,
        size,
      ],
    );

    final charOffset = useMemoized(() {
      if (!verticalScrollController.hasClients ||
          !verticalScrollController.position.hasViewportDimension) {
        if (state.buffer.lineCountWithTrailingNewline() - 1 <= 0) {
          return CharOffset(start: 0, end: 0);
        } else {
          if (visibleLines.first == 0 && visibleLines.last == 0) {
            return CharOffset(start: 0, end: 0);
          }

          final firstChar = state.buffer.byteOfLine(row: visibleLines.first);
          final lastChar =
              state.buffer.byteOfLine(row: visibleLines.last - 1) +
              state.buffer.lineLen(row: visibleLines.last - 1) +
              1;

          return CharOffset(start: firstChar, end: lastChar);
        }
      }

      final firstChar = state.buffer.byteOfLine(row: visibleLines.first);
      final lastChar =
          state.buffer.byteOfLine(row: visibleLines.last - 1) +
          state.buffer.lineLen(row: visibleLines.last - 1) +
          1;

      return CharOffset(start: firstChar, end: lastChar);
    }, [visibleLines, state.buffer.version]);

    final visibleChars = useMemoized(
      () {
        if (!horizontalScrollController.hasClients ||
            !horizontalScrollController.position.hasViewportDimension) {
          final horizontalOffset = 0;

          final firstChar = max(
            0,
            (horizontalOffset / fontMetrics.charWidth).floor(),
          );
          final lastChar =
              ((horizontalOffset + viewportWidth.value) / fontMetrics.charWidth)
                  .ceil();

          return VisibleChars(first: firstChar, last: lastChar);
        }

        final scrollControllerViewportWidth =
            horizontalScrollController.position.viewportDimension;
        final horizontalOffset = horizontalScrollController.offset;

        final firstChar = max(
          0,
          (horizontalOffset / fontMetrics.charWidth).floor(),
        );
        final lastChar =
            ((horizontalOffset + scrollControllerViewportWidth) /
                    fontMetrics.charWidth)
                .ceil();

        return VisibleChars(first: firstChar, last: lastChar);
      },
      [
        visibleLines,
        state.buffer.version,
        state.cursor,
        activeTab.path,
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
    }, [state.buffer.version, visibleLines, visibleChars, activeTab.path]);

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          viewportWidth.value = constraints.maxWidth;
          viewportHeight.value = constraints.maxHeight;
        });

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
                    onKeyEvent: (node, event) => _handleKeyEvent(
                      node,
                      event,
                      state,
                      notifier,
                      shouldAutoScroll,
                      activeTab,
                      tabNotifier,
                    ),
                    child: GestureDetector(
                      onTapDown: (details) => _handleTapDown(
                        details,
                        painterKey,
                        focusNode,
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
                            lastVisibleLine: visibleLines.last,
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
