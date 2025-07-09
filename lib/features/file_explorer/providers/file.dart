import 'package:rei/features/file_explorer/models/file_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
}
