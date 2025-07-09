import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_entry.freezed.dart';

@freezed
sealed class FileEntry with _$FileEntry {
  const factory FileEntry({
    required String path,
    required bool isDirectory,
    @Default(false) bool isExpanded,
    @Default([]) List<FileEntry> children,
  }) = _FileEntry;
}
