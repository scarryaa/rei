import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/file_explorer/hooks/item_rename_hook.dart';
import 'package:rei/features/file_explorer/hooks/new_item_hook.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:rei/features/file_explorer/models/file_explorer_state.dart';
import 'package:rei/features/file_explorer/models/new_item_state.dart';
import 'package:rei/features/file_explorer/providers/file.dart';
import 'package:rei/features/file_explorer/widgets/editable_item_widget.dart';
import 'package:rei/shared/services/file_service.dart';
import 'package:rei/shared/widgets/context_menu_widget.dart';

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
    FocusNode? focusedChild,
    File notifier,
  ) {
    focusNode.requestFocus();

    // If we are not creating a new file or renaming one, clear the selected file.
    if (focusedChild == null || focusedChild == focusNode) {
      notifier.clearSelectedFile();
    }
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    FocusNode? focusedChild,
    KeyEvent event,
    File notifier,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent || !node.hasFocus) {
      return KeyEventResult.ignored;
    }

    // Check if any text field is currently focused
    if (focusedChild != null && focusedChild != node) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        notifier.selectNext();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        notifier.selectPrevious();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        notifier.collapseCurrentDirectoryOrMoveToAndCollapseParent();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        notifier.moveToFirstChildAndExpand();
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileProvider);
    final notifier = ref.read(fileProvider.notifier);
    final verticalScrollController = useScrollController();
    final horizontalScrollController = useScrollController();
    final focusNode = useFocusNode();
    final newItemState = useNewItemCreation(notifier);

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
                newItemState,
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
    NewItemState newItemState,
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

        final focusedChild = FocusScope.of(context).focusedChild;

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
                    child: GestureDetector(
                      onTapDown: (details) {
                        focusNode.requestFocus();
                      },
                      child: Focus(
                        focusNode: focusNode,
                        onKeyEvent: (node, event) => _handleKeyEvent(
                          node,
                          focusedChild,
                          event,
                          notifier,
                        ),
                        child: SizedBox(
                          width: maxWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._buildFileTree(notifier, state, root, 0),
                              if (newItemState.isMakingNewFile)
                                EditableItemWidget(
                                  isDirectory: false,
                                  depth: 1,
                                  controller: newItemState.textFieldController,
                                  focusNode: newItemState.textFieldFocusNode,
                                  onSubmitted: (value) =>
                                      newItemState.createFile(value.trim()),
                                  onEditingComplete: () =>
                                      newItemState.createFile(
                                        newItemState.textFieldController.text
                                            .trim(),
                                      ),
                                ),
                              if (newItemState.isMakingNewFolder)
                                EditableItemWidget(
                                  isDirectory: true,
                                  depth: 1,
                                  controller: newItemState.textFieldController,
                                  focusNode: newItemState.textFieldFocusNode,
                                  onSubmitted: (value) =>
                                      newItemState.createFolder(value.trim()),
                                  onEditingComplete: () =>
                                      newItemState.createFolder(
                                        newItemState.textFieldController.text
                                            .trim(),
                                      ),
                                ),

                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapDown: (details) => _handleTapDown(
                                  details,
                                  focusNode,
                                  focusedChild,
                                  notifier,
                                ),
                                onSecondaryTapDown: (details) {
                                  ContextMenuWidget.show(
                                    context: context,
                                    position: details.globalPosition,
                                    items: [
                                      ContextMenuItem(
                                        title: 'New File',
                                        onTap: () async {
                                          newItemState.startFileCreation(
                                            root.path,
                                          );
                                        },
                                      ),
                                      ContextMenuItem(
                                        title: 'New Folder',
                                        onTap: () async {
                                          newItemState.startFolderCreation(
                                            root.path,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
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

  void _expandDirIfCollapsed() {
    if (!isExpanded && isDirectory) {
      notifier.toggleExpansion(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);
    final newItemState = useNewItemCreation(notifier);
    final renameItemState = useItemRename(notifier);

    return Column(
      children: [
        if (renameItemState.isRenaming)
          EditableItemWidget(
            isDirectory: isDirectory,
            depth: depth,
            controller: renameItemState.textFieldController,
            focusNode: renameItemState.textFieldFocusNode,
            onSubmitted: (value) =>
                renameItemState.renameItem(name, value.trim()),
            onEditingComplete: () => renameItemState.renameItem(
              name,
              renameItemState.textFieldController.text.trim(),
            ),
          )
        else
          MouseRegion(
            onEnter: (event) => isHovered.value = true,
            onExit: (event) => isHovered.value = false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (isDirectory) {
                  notifier.toggleExpansion(path);
                } else {
                  // Open in editor.
                  FileService.selectFile(path);
                }

                notifier.selectFile(path);
              },
              onSecondaryTapDown: (details) {
                notifier.selectFile(path);

                ContextMenuWidget.show(
                  context: context,
                  position: details.globalPosition,
                  items: [
                    ContextMenuItem(
                      title: 'New File',
                      onTap: () async {
                        _expandDirIfCollapsed();
                        newItemState.startFileCreation(path);
                      },
                    ),
                    ContextMenuItem(
                      title: 'New Folder',
                      onTap: () async {
                        _expandDirIfCollapsed();
                        newItemState.startFolderCreation(path);
                      },
                    ),
                    ContextMenuItem.divider,
                    ContextMenuItem(
                      title: 'Rename',
                      onTap: () {
                        final itemName = path
                            .split(Platform.pathSeparator)
                            .last;
                        renameItemState.startRename(path, itemName);
                      },
                    ),
                    ContextMenuItem(
                      title: 'Delete',
                      onTap: () async {
                        final showConfirmation =
                            !HardwareKeyboard.instance.isShiftPressed;
                        final fileName = path
                            .split(Platform.pathSeparator)
                            .last;

                        if (showConfirmation) {
                          final result = await _showDeleteConfirmation(
                            context,
                            fileName,
                          );

                          if (result) {
                            notifier.deleteItem(path);
                          }
                        } else {
                          notifier.deleteItem(path);
                        }
                      },
                    ),
                  ],
                );
              },
              child: Container(
                color: (colorOverride != null)
                    ? colorOverride
                    : isHovered.value
                    ? Colors.lightBlue.withValues(alpha: 0.3)
                    : null,
                padding: EdgeInsets.only(
                  left: leftPadding + (depth * depthPadding),
                ),
                child: Row(
                  spacing: spacing,
                  children: [
                    Icon(
                      isDirectory
                          ? Icons.folder
                          : Icons.insert_drive_file_rounded,
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
          ),
        if (newItemState.isMakingNewFile)
          EditableItemWidget(
            isDirectory: false,
            depth: depth + (isDirectory ? 1 : 0),
            controller: newItemState.textFieldController,
            focusNode: newItemState.textFieldFocusNode,
            onSubmitted: (value) => newItemState.createFile(value.trim()),
            onEditingComplete: () => newItemState.createFile(
              newItemState.textFieldController.text.trim(),
            ),
          ),
        if (newItemState.isMakingNewFolder)
          EditableItemWidget(
            isDirectory: true,
            depth: depth + (isDirectory ? 1 : 0),
            controller: newItemState.textFieldController,
            focusNode: newItemState.textFieldFocusNode,
            onSubmitted: (value) => newItemState.createFolder(value.trim()),
            onEditingComplete: () => newItemState.createFolder(
              newItemState.textFieldController.text.trim(),
            ),
          ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String fileName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Color(0x10FFFFFF), width: 1.0),
              ),
              backgroundColor: Colors.black,
              title: Text('Delete $fileName?'),
              content: Text(
                '(Hold shift to bypass this dialog)',
                style: TextStyle(color: Color(0x50FFFFFF)),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
