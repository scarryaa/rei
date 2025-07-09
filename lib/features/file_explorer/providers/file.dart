import 'package:file_picker/file_picker.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ignore: library_prefixes
import 'dart:io' as IO;

part 'file.g.dart';

@riverpod
class File extends _$File {
  @override
  FileEntry? build() {
    return null;
  }

  void setRoot(FileEntry root) {
    state = root;
  }

  void toggleExpansion(String path) {
    if (state == null) return;

    state = _toggleExpansionHelper(state!, path);
  }

  FileEntry _toggleExpansionHelper(FileEntry entry, String targetPath) {
    if (entry.path == targetPath) {
      if (entry.isDirectory) {
        if (!entry.isExpanded && entry.children.isEmpty) {
          // First time expanding - load children.
          final children = _loadChildren(entry, entry.path);

          return entry.copyWith(isExpanded: true, children: children);
        } else {
          // Just toggle it.
          return entry.copyWith(isExpanded: !entry.isExpanded);
        }
      }

      return entry;
    }

    final updatedChildren = entry.children.map((child) {
      return _toggleExpansionHelper(child, targetPath);
    }).toList();

    return entry.copyWith(children: updatedChildren);
  }

  List<FileEntry> _loadChildren(FileEntry? parent, String directoryPath) {
    try {
      final dir = IO.Directory(directoryPath);
      final files = dir.listSync();

      files.sort((a, b) {
        if (a is IO.Directory && b is IO.Directory) {
          return a.path
              .split(IO.Platform.pathSeparator)
              .last
              .toLowerCase()
              .compareTo(
                b.path.split(IO.Platform.pathSeparator).last.toLowerCase(),
              );
        }

        if (a is IO.Directory) {
          return -1;
        }

        if (b is IO.Directory) {
          return 1;
        }

        return a.path
            .split(IO.Platform.pathSeparator)
            .last
            .toLowerCase()
            .compareTo(
              b.path.split(IO.Platform.pathSeparator).last.toLowerCase(),
            );
      });

      return files.map((item) {
        final name = item.path.split(IO.Platform.pathSeparator).last;

        return FileEntry(
          path: item.path,
          parent: parent,
          name: name,
          isDirectory: item is IO.Directory,
          isHidden: name.startsWith('.') || (parent != null && parent.isHidden),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  FileEntry? _findFileByPath(String path) {
    if (state != null) {
      return _findFileHelper(state!, path);
    }

    return null;
  }

  FileEntry? _findFileHelper(FileEntry startingFile, String path) {
    if (path == startingFile.path) {
      return startingFile;
    }

    for (final child in startingFile.children) {
      if (child.path == path) {
        return child;
      }
      if (child.children.isNotEmpty && child.isDirectory) {
        final result = _findFileHelper(child, path);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  Future<void> selectDirectory() async {
    final rootDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a directory',
      initialDirectory: '',
    );

    if (rootDir != null) {
      final name = rootDir.split(IO.Platform.pathSeparator).last;
      FileEntry root = FileEntry(
        path: rootDir,
        name: name,
        parent: null,
        isHidden: name.startsWith('.'),
        isDirectory: true,
        isExpanded: true,
        children: [],
      );

      final children = _loadChildren(root, rootDir);
      root = root.copyWith(children: children);

      state = root;
    }
  }
}
