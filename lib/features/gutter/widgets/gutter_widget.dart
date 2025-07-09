import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/gutter/widgets/painters/gutter_painter.dart';
import 'package:rei/shared/providers/scroll_sync.dart';

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
    final verticalScrollController = useScrollController();
    final editorState = ref.watch(editorProvider);
    final textPainterWidth = useState(0.0);
    final verticalOffset = useState(0.0);

    final scrollSyncState = ref.watch(scrollSyncProvider);
    final scrollSyncNotifier = ref.read(scrollSyncProvider.notifier);

    final scrollSync = useMemoized(
      () => verticalScrollController.createSync('gutter', scrollSyncNotifier),
      [verticalScrollController, scrollSyncNotifier],
    );

    useListenable(verticalScrollController);

    useEffect(() {
      scrollSync.startListening();
      return () => scrollSync.stopListening();
    }, [scrollSync]);

    useEffect(() {
      if (scrollSyncState.activeController != null &&
          scrollSyncState.activeController != 'gutter' &&
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

      return (horizontal: horizontal, vertical: vertical);
    }, [fontMetrics]);

    final size = useMemoized(
      () {
        final width =
            editorState.buffer
                    .lineCountWithTrailingNewline()
                    .toString()
                    .length *
                fontMetrics.charWidth +
            padding.horizontal;
        final height =
            (editorState.buffer.lineCountWithTrailingNewline() *
                fontMetrics.lineHeight) +
            padding.vertical;

        return Size(width, height);
      },
      [
        padding,
        fontMetrics,
        editorState.buffer.version,
        textPainterWidth.value,
      ],
    );

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

      void verticalScrollListener() {
        updateVerticalOffset();
      }

      verticalScrollController.addListener(verticalScrollListener);
      updateVerticalOffset();

      return () {
        verticalScrollController.removeListener(verticalScrollListener);
      };
    }, [editorState.buffer.version, editorState.cursor]);

    final visibleLines = useMemoized(
      () {
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
            editorState.buffer.lineCount() - 1,
          ),
        );
        final lastVisibleLine = max(
          0,
          min(
            ((verticalOffset + viewportHeight) / fontMetrics.lineHeight).ceil(),
            editorState.buffer.lineCountWithTrailingNewline(),
          ),
        );

        return (first: firstVisibleLine, last: lastVisibleLine);
      },
      [
        editorState.buffer.version,
        editorState.cursor,
        verticalOffset.value,
        size,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = max(size.height, constraints.maxHeight);
        Size newSize = Size(size.width, height);

        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            overscroll: false,
            scrollbars: false,
            physics: ClampingScrollPhysics(),
          ),
          child: SingleChildScrollView(
            controller: verticalScrollController,
            child: CustomPaint(
              willChange: true,
              size: newSize,
              painter: GutterPainter(
                visibleLines: visibleLines,
                fontMetrics: fontMetrics,
                state: editorState,
                textStyle: textStyle,
              ),
            ),
          ),
        );
      },
    );
  }
}
