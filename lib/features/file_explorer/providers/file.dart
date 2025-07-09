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

  Future<void> selectDirectory() async {
    final rootDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a directory',
      initialDirectory: '',
    );

    if (rootDir != null) {
      final dir = IO.Directory(rootDir);
      final children = dir
          .listSync()
          .map(
            (item) => FileEntry(
              path: item.path,
              name: item.path.split(IO.Platform.pathSeparator).last,
              isDirectory: item is IO.Directory,
            ),
          )
          .toList();

      state = FileEntry(
        path: rootDir,
        name: rootDir.split(IO.Platform.pathSeparator).last,
        isDirectory: true,
        isExpanded: true,
        children: children,
      );
    }
  }
}
