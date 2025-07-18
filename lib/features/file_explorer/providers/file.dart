import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:rei/features/file_explorer/models/file_explorer_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ignore: library_prefixes
import 'dart:io' as IO;

import 'package:shared_preferences/shared_preferences.dart';

part 'file.g.dart';

@riverpod
class File extends _$File {
  static const String _key = 'file_explorer_dir';

  @override
  FileExplorerState build() {
    init();
    return FileExplorerState(root: null);
  }

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final dir = prefs.getString(_key);

    if (dir != null) {
      await setRootAndLoadChildren(dir);
    }
  }

  void _deleteFolder(String path) {
    IO.Directory dir = IO.Directory(path);

    if (dir.existsSync()) {
      dir.deleteSync();
    }
  }

  void _deleteFile(String path) {
    IO.File file = IO.File(path);

    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  void deleteItem(String path) {
    if (IO.File(path).existsSync()) {
      _deleteFile(path);
      reloadChildren(p.dirname(path));
    } else {
      _deleteFolder(path);
      reloadChildren(p.dirname(path));
    }
  }

  void reloadChildren(String directoryPath) {
    if (state.root == null) return;

    final targetDirectory = _findFileByPath(directoryPath);
    if (targetDirectory == null || !targetDirectory.isDirectory) return;

    final expandedStates = _captureExpandedStates(targetDirectory);

    final newChildren = _loadChildren(targetDirectory, directoryPath);

    final childrenWithExpandedStates = _restoreExpandedStates(
      newChildren,
      expandedStates,
    );

    state = state.copyWith(
      root: _updateDirectoryChildren(
        state.root!,
        directoryPath,
        childrenWithExpandedStates,
      ),
    );
  }

  Map<String, bool> _captureExpandedStates(FileEntry entry) {
    final Map<String, bool> expandedStates = {};

    void captureRecursively(FileEntry currentEntry) {
      if (currentEntry.isDirectory) {
        expandedStates[currentEntry.path] = currentEntry.isExpanded;

        for (final child in currentEntry.children) {
          captureRecursively(child);
        }
      }
    }

    captureRecursively(entry);
    return expandedStates;
  }

  List<FileEntry> _restoreExpandedStates(
    List<FileEntry> entries,
    Map<String, bool> expandedStates,
  ) {
    return entries.map((entry) {
      if (entry.isDirectory) {
        final wasExpanded = expandedStates[entry.path] ?? false;

        if (wasExpanded) {
          final children = _loadChildren(entry, entry.path);
          final childrenWithStates = _restoreExpandedStates(
            children,
            expandedStates,
          );

          return entry.copyWith(isExpanded: true, children: childrenWithStates);
        } else {
          return entry.copyWith(isExpanded: false);
        }
      }

      return entry;
    }).toList();
  }

  FileEntry _updateDirectoryChildren(
    FileEntry entry,
    String targetPath,
    List<FileEntry> newChildren,
  ) {
    if (entry.path == targetPath) {
      return entry.copyWith(children: newChildren);
    }

    final updatedChildren = entry.children.map((child) {
      return _updateDirectoryChildren(child, targetPath, newChildren);
    }).toList();

    return entry.copyWith(children: updatedChildren);
  }

  String createNewFolder(String path, String folderName) {
    final dirPath = IO.Directory(path).existsSync() ? path : p.dirname(path);
    final finalPath = p.join(dirPath, folderName);
    final folder = IO.Directory(finalPath);

    folder.createSync();
    reloadChildren(state.root!.path == path ? path : p.dirname(path));

    return finalPath;
  }

  String createNewFile(String path, String fileName) {
    final dirPath = IO.Directory(path).existsSync() ? path : p.dirname(path);
    final finalPath = p.join(dirPath, fileName);
    final file = IO.File(finalPath);

    file.createSync();
    reloadChildren(state.root!.path == path ? path : p.dirname(path));

    return finalPath;
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
      print(e);
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
      await setRootAndLoadChildren(rootDir);
    }
  }

  Future<void> setRootAndLoadChildren(String rootDir) async {
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

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, rootDir);
  }

  void clearSelectedFile() {
    state = state.copyWith(selectedFilePath: null);
  }

  void selectFile(String path) {
    state = state.copyWith(selectedFilePath: path);
  }

  void moveToParentAndCollapse() {
    final currentSelectedFilePath = state.selectedFilePath;

    if (currentSelectedFilePath != null) {
      final currentSelectedFile = _findFileByPath(currentSelectedFilePath);

      if (currentSelectedFile != null) {
        final parent = findParent(currentSelectedFile, state.root!);

        if (parent != null) {
          toggleExpansion(parent.path);
          selectFile(parent.path);
        }
      }
    }
  }

  void collapseCurrentDirectoryOrMoveToAndCollapseParent() {
    final currentSelectedFilePath = state.selectedFilePath;

    if (currentSelectedFilePath != null) {
      final currentSelectedFile = _findFileByPath(currentSelectedFilePath);

      if (currentSelectedFile != null) {
        // Collapse the current file if it is a directory and expanded.
        if (currentSelectedFile.isDirectory && currentSelectedFile.isExpanded) {
          toggleExpansion(currentSelectedFile.path);
        } else {
          // Otherwise, move to the parent and collapse.
          moveToParentAndCollapse();
        }
      }
    }
  }

  void moveToFirstChildAndExpand() {
    final currentSelectedFilePath = state.selectedFilePath;

    if (currentSelectedFilePath != null) {
      final currentSelectedFile = _findFileByPath(currentSelectedFilePath);

      if (currentSelectedFile != null && currentSelectedFile.isDirectory) {
        if (currentSelectedFile.isExpanded) {
          // Move to first child if it exists.
          if (currentSelectedFile.children.isNotEmpty) {
            final firstChild = currentSelectedFile.children.first;
            state = state.copyWith(selectedFilePath: firstChild.path);
          } else {
            // Otherwise, move to the next file.
            selectNext();
          }
        } else {
          // Expand the directory.
          toggleExpansion(currentSelectedFile.path);
        }
      }
    }
  }

  void selectNext() {
    final currentSelectedFilePath = state.selectedFilePath;

    if (currentSelectedFilePath == null) {
      if (state.root != null) {
        state = state.copyWith(selectedFilePath: state.root!.path);
      }
    } else {
      final currentSelectedFile = _findFileByPath(currentSelectedFilePath);

      if (currentSelectedFile != null) {
        final nextFile = findNextInTree(currentSelectedFile);

        if (nextFile != null) {
          state = state.copyWith(selectedFilePath: nextFile.path);
        }
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
    final currentSelectedFilePath = state.selectedFilePath;

    if (currentSelectedFilePath == null) {
      if (state.root != null) {
        state = state.copyWith(selectedFilePath: state.root!.path);
      }
    } else {
      final currentSelectedFile = _findFileByPath(currentSelectedFilePath);

      if (currentSelectedFile != null) {
        final previousFile = findPreviousInTree(currentSelectedFile);

        if (previousFile != null) {
          state = state.copyWith(selectedFilePath: previousFile.path);
        }
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
