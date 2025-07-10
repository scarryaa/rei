import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:rei/features/file_explorer/models/file_explorer_state.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

class FileExplorerWidget extends HookConsumerWidget {
  const FileExplorerWidget({super.key});

  static const textStyle = TextStyle(
    fontSize: 15.0,
    fontFamily: 'IBM Plex Sans',
    letterSpacing: 0,
    wordSpacing: 0,
    height: 1.4,
  );

  void _handleTapDown(
    TapDownDetails details,
    FocusNode focusNode,
    File notifier,
  ) {
    focusNode.requestFocus();
    notifier.clearSelectedFile();
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    File notifier,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        notifier.selectNext();
      case LogicalKeyboardKey.arrowUp:
        notifier.selectPrevious();
      case LogicalKeyboardKey.arrowLeft:
        notifier.collapseCurrentDirectoryOrMoveToAndCollapseParent();
      case LogicalKeyboardKey.arrowRight:
        notifier.moveToFirstChildAndExpand();
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileProvider);
    final notifier = ref.read(fileProvider.notifier);
    final verticalScrollController = useScrollController();
    final horizontalScrollController = useScrollController();
    final focusNode = useFocusNode();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 250.0,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: const Color(0x10FFFFFF))),
        ),
        child: state.root == null
            ? _buildEmptyView(notifier)
            : _buildDirectoryView(
                verticalScrollController,
                horizontalScrollController,
                focusNode,
                notifier,
                state,
                state.root!,
              ),
      ),
    );
  }

  Widget _buildEmptyView(File notifier) {
    return Center(
      child: Column(
        spacing: 8.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder, size: 64.0, color: Color(0x20FFFFFF)),
          TextButton(
            onPressed: () async {
              await notifier.selectDirectory();
            },
            child: Text('Select a directory'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFileTree(
    File notifier,
    FileExplorerState state,
    FileEntry entry,
    int depth,
  ) {
    List<Widget> widgets = [];

    widgets.add(
      FileEntryWidget(
        isExpanded: entry.isExpanded,
        path: entry.path,
        name: entry.name,
        isDirectory: entry.isDirectory,
        isHidden: entry.isHidden,
        notifier: notifier,
        depth: depth,
        colorOverride: state.selectedFilePath == entry.path
            ? Colors.lightBlue.withValues(alpha: 0.5)
            : null,
      ),
    );

    if (entry.isDirectory && entry.isExpanded) {
      for (FileEntry child in entry.children) {
        widgets.addAll(_buildFileTree(notifier, state, child, depth + 1));
      }
    }

    return widgets;
  }

  Widget _buildDirectoryView(
    ScrollController verticalScrollController,
    ScrollController horizontalScrollController,
    FocusNode focusNode,
    File notifier,
    FileExplorerState state,
    FileEntry root,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Size size = _calculateMaxSize(
          root,
          constraints.maxWidth,
          constraints.maxHeight,
        );
        double maxWidth = size.width;

        maxWidth += maxWidth > constraints.maxWidth
            ? FileEntryWidget.depthPadding
            : 0.0;

        return SizedBox(
          width: constraints.maxWidth,
          child: Scrollbar(
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
                  controller: verticalScrollController,
                  child: SingleChildScrollView(
                    controller: horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Focus(
                      focusNode: focusNode,
                      onKeyEvent: (node, event) =>
                          _handleKeyEvent(node, event, notifier),
                      child: SizedBox(
                        width: maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildFileTree(notifier, state, root, 0),
                            GestureDetector(
                              onTapDown: (details) =>
                                  _handleTapDown(details, focusNode, notifier),
                              child: Container(
                                color: Colors.transparent,
                                width: maxWidth,
                                height: size.height > constraints.maxHeight
                                    ? FileEntryWidget.depthPadding * 5
                                    : constraints.maxHeight - size.height,
                              ),
                            ),
                          ],
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

  Size _calculateMaxSize(FileEntry entry, double minWidth, double minHeight) {
    double maxWidth = minWidth;
    int totalFiles = 0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void calculateDimensions(FileEntry entry, int depth) {
      textPainter
        ..text = TextSpan(text: entry.name, style: textStyle)
        ..layout();

      double width =
          FileEntryWidget.leftPadding +
          (depth * FileEntryWidget.depthPadding) +
          FileEntryWidget.iconSize +
          FileEntryWidget.spacing +
          textPainter.width;
      maxWidth = max(maxWidth, width);

      totalFiles++;

      if (entry.isDirectory && entry.isExpanded) {
        for (FileEntry child in entry.children) {
          calculateDimensions(child, depth + 1);
        }
      }
    }

    calculateDimensions(entry, 0);

    double lineHeight = textPainter.height;
    double maxHeight = lineHeight * totalFiles;

    return Size(maxWidth, maxHeight);
  }
}

class FileEntryWidget extends HookConsumerWidget {
  const FileEntryWidget({
    super.key,
    required this.name,
    required this.path,
    required this.isExpanded,
    required this.isDirectory,
    required this.isHidden,
    required this.notifier,
    this.colorOverride,
    this.depth = 0,
  });

  static const double depthPadding = 16.0;
  static const double spacing = 8.0;
  static const double leftPadding = 8.0;
  static const double iconSize = 15.0;

  final String name;
  final String path;
  final bool isExpanded;
  final bool isDirectory;
  final bool isHidden;
  final File notifier;
  final int depth;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (event) => isHovered.value = true,
      onExit: (event) => isHovered.value = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (isDirectory) {
            notifier.toggleExpansion(path);
          } else {
            // Open in editor
          }

          notifier.selectFile(path);
        },
        child: Container(
          color: (colorOverride != null)
              ? colorOverride
              : isHovered.value
              ? Colors.lightBlue.withValues(alpha: 0.3)
              : null,
          padding: EdgeInsets.only(left: leftPadding + (depth * depthPadding)),
          child: Row(
            spacing: spacing,
            children: [
              Icon(
                isDirectory ? Icons.folder : Icons.insert_drive_file_rounded,
                size: iconSize,
                color: isHidden ? Color(0x70FFFFFF) : Color(0xBBFFFFFF),
              ),
              Text(
                name,
                style: FileExplorerWidget.textStyle.copyWith(
                  color: isHidden ? Color(0x65FFFFFF) : Color(0xAAFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
