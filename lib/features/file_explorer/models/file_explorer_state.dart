import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rei/features/file_explorer/models/file_entry.dart';

part 'file_explorer_state.freezed.dart';

@freezed
sealed class FileExplorerState with _$FileExplorerState {
  const factory FileExplorerState({
    required FileEntry? root,
    @Default(null) FileEntry? selectedFile,
  }) = _FileExplorerState;
}
