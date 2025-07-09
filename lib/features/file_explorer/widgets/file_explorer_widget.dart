import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

class FileExplorerWidget extends HookConsumerWidget {
  const FileExplorerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileProvider);
    final notifier = ref.read(fileProvider.notifier);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 250.0,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: const Color(0x10FFFFFF))),
        ),
        child: state == null
            ? _buildEmptyView(notifier)
            : _buildDirectoryView(notifier, state),
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

  List<Widget> _buildFileTree(File notifier, FileEntry entry, int depth) {
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
      ),
    );

    if (entry.isDirectory && entry.isExpanded) {
      for (FileEntry child in entry.children) {
        widgets.addAll(_buildFileTree(notifier, child, depth + 1));
      }
    }

    return widgets;
  }

  Widget _buildDirectoryView(File notifier, FileEntry state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildFileTree(notifier, state, 0),
    );
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
    this.depth = 0,
  });

  final String name;
  final String path;
  final bool isExpanded;
  final bool isDirectory;
  final bool isHidden;
  final File notifier;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (event) => isHovered.value = true,
      onExit: (event) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (details) {
          notifier.toggleExpansion(path);
        },
        child: Container(
          color: isHovered.value
              ? Colors.lightBlue.withValues(alpha: 0.3)
              : null,
          padding: EdgeInsets.only(left: 8.0 + (depth * 16.0)),
          child: Row(
            spacing: 8.0,
            children: [
              Icon(
                isDirectory ? Icons.folder : Icons.insert_drive_file_rounded,
                size: 15.0,
                color: isHidden ? Color(0x70FFFFFF) : Color(0xBBFFFFFF),
              ),
              Text(
                name,
                style: TextStyle(
                  color: isHidden ? Color(0x65FFFFFF) : Color(0xAAFFFFFF),
                  fontSize: 15.0,
                  fontFamily: 'IBM Plex Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
