import 'package:rei/bridge/rust/api/buffer.dart';
import 'package:rei/bridge/rust/api/cursor.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor.g.dart';

@riverpod
class Editor extends _$Editor {
  @override
  EditorState build() {
    return EditorState(buffer: Buffer(), cursor: Cursor.default_());
  }

  void insert(String text) {
    final cursor = state.cursor;
    final (newRow, newColumn) = state.buffer.insert(
      row: cursor.row,
      column: cursor.column,
      text: text,
    );
    final newCursor = Cursor(
      row: newRow,
      column: newColumn,
      stickyColumn: newColumn,
    );

    state = state.copyWith(buffer: state.buffer, cursor: newCursor);
  }
}
