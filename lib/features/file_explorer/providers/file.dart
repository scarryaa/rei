import 'package:file_picker/file_picker.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:rei/features/file_explorer/models/file_explorer_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ignore: library_prefixes
import 'dart:io' as IO;

part 'file.g.dart';

@riverpod
class File extends _$File {
  @override
  FileExplorerState build() {
    return FileExplorerState(root: null);
  }

  void setRoot(FileEntry root) {
    state = state.copyWith(root: root);
  }

  void toggleExpansion(String path) {
    if (state.root == null) return;

    state = state.copyWith(root: _toggleExpansionHelper(state.root!, path));
  }

  FileEntry? findParent(FileEntry target, FileEntry root) {
    if (root.children.contains(target)) {
      return root;
    }

    for (final child in root.children) {
      if (child.isDirectory) {
        final parent = findParent(target, child);
        if (parent != null) return parent;
      }
    }

    return null;
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
    if (state.root != null) {
      return _findFileHelper(state.root!, path);
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
        isHidden: name.startsWith('.'),
        isDirectory: true,
        isExpanded: true,
        children: [],
      );

      final children = _loadChildren(root, rootDir);
      root = root.copyWith(children: children);

      state = state.copyWith(root: root);
    }
  }

  void selectNext() {
    final currentSelectedFile = state.selectedFile;

    if (currentSelectedFile == null) {
      state = state.copyWith(selectedFile: state.root);
    } else {
      final nextFile = findNextInTree(currentSelectedFile);

      if (nextFile != null) {
        state = state.copyWith(selectedFile: nextFile);
      }
    }
  }

  FileEntry? findNextInTree(FileEntry currentFile) {
    // If the current file has children, is a directory, and is expanded,
    // go to first child.
    if (currentFile.children.isNotEmpty &&
        currentFile.isDirectory &&
        currentFile.isExpanded) {
      return currentFile.children.first;
    }

    // Otherwise, find the next sibling or the ancestor's sibling.
    FileEntry? node = currentFile;
    while (node != null) {
      final parent = findParent(node, state.root!);

      if (parent != null) {
        final currentIndex = parent.children.indexOf(node);

        if (currentIndex + 1 < parent.children.length) {
          return parent.children[currentIndex + 1];
        }
      }

      node = parent;
    }

    // End of tree.
    return null;
  }

  void selectPrevious() {
    final currentSelectedFile = state.selectedFile;

    if (currentSelectedFile == null) {
      state = state.copyWith(selectedFile: state.root);
    } else {
      final previousFile = findPreviousInTree(currentSelectedFile);

      if (previousFile != null) {
        state = state.copyWith(selectedFile: previousFile);
      }
    }
  }

  FileEntry? findPreviousInTree(FileEntry currentFile) {
    final parent = findParent(currentFile, state.root!);

    if (parent != null) {
      final currentIndex = parent.children.indexOf(currentFile);

      if (currentIndex != -1 && currentIndex > 0) {
        // Get the previous sibling.
        final previousSibling = parent.children[currentIndex - 1];

        // If it's a directory and expanded, find its last descendant.
        if (previousSibling.isDirectory && previousSibling.isExpanded) {
          return findLastDescendant(previousSibling);
        } else {
          // Otherwise, just return the previous sibling.
          return previousSibling;
        }
      } else {
        // No previous sibling, return the parent.
        return parent;
      }
    }

    // Start of tree.
    return null;
  }

  FileEntry findLastDescendant(FileEntry entry) {
    // If not expanded or no children, return the entry itself.
    if (!entry.isExpanded || entry.children.isEmpty) {
      return entry;
    }

    // Get the last child.
    final lastChild = entry.children.last;

    // If the last child is a directory and expanded, recurse.
    if (lastChild.isDirectory &&
        lastChild.isExpanded &&
        lastChild.children.isNotEmpty) {
      return findLastDescendant(lastChild);
    }

    // Otherwise return the last child.
    return lastChild;
  }
}
