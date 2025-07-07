import 'dart:math';

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

  void removeChar() {
    final cursor = state.cursor;

    if (cursor.row == 0 && cursor.column == 0) return;

    final (newRow, newColumn) = state.buffer.removeChar(
      row: cursor.row,
      column: cursor.column,
    );
    final newCursor = Cursor(
      row: newRow,
      column: newColumn,
      stickyColumn: newColumn,
    );

    state = state.copyWith(buffer: state.buffer, cursor: newCursor);
  }

  // TODO: For movement methods, consider chars instead of +1 and -1.
  void moveLeft() {
    final cursor = state.cursor;
    Cursor newCursor = cursor;

    if (cursor.row == 0 && cursor.column == 0) return;

    if (cursor.row > 0 && cursor.column == 0) {
      // Move to end of previous line.
      final previousLineLength = state.buffer.lineLen(row: cursor.row - 1);
      newCursor = Cursor(
        row: cursor.row - 1,
        column: previousLineLength,
        stickyColumn: previousLineLength,
      );
    } else if (cursor.column > 0) {
      // Move back a character.
      newCursor = Cursor(
        row: cursor.row,
        column: cursor.column - 1,
        stickyColumn: cursor.column - 1,
      );
    }

    state = state.copyWith(cursor: newCursor);
  }

  void moveRight() {
    final cursor = state.cursor;
    Cursor newCursor = cursor;
    final lineCount = state.buffer.lineCount() - 1;
    final lastLineLength = state.buffer.lineLen(row: lineCount);

    if (cursor.row == lineCount && cursor.column == lastLineLength) return;

    final lineLength = state.buffer.lineLen(row: cursor.row);
    if (cursor.row < lineCount && cursor.column == lineLength) {
      // Move to start of the next line.
      newCursor = Cursor(row: cursor.row + 1, column: 0, stickyColumn: 0);
    } else if (cursor.column < lineLength) {
      // Move forward a character.
      newCursor = Cursor(
        row: cursor.row,
        column: cursor.column + 1,
        stickyColumn: cursor.column + 1,
      );
    }

    state = state.copyWith(cursor: newCursor);
  }

  void moveUp() {
    final cursor = state.cursor;
    Cursor newCursor = cursor;

    if (cursor.row == 0) {
      // Move to the start of the document.
      newCursor = Cursor.default_();
    } else if (cursor.row > 0) {
      // Move up a line.
      final previousLineLength = state.buffer.lineLen(row: cursor.row - 1);
      final newColumn = min(previousLineLength, cursor.stickyColumn);
      newCursor = Cursor(
        row: cursor.row - 1,
        column: newColumn,
        stickyColumn: cursor.stickyColumn,
      );
    }

    state = state.copyWith(cursor: newCursor);
  }

  void moveDown() {
    final cursor = state.cursor;
    Cursor newCursor = cursor;

    final lineCount = state.buffer.lineCount() - 1;
    if (cursor.row == lineCount) {
      // Move to the end of the document.
      final lastLineLength = state.buffer.lineLen(row: lineCount);
      newCursor = Cursor(
        row: lineCount,
        column: lastLineLength,
        stickyColumn: lastLineLength,
      );
    } else if (cursor.row < lineCount) {
      // Move down a line.
      final nextLineLength = state.buffer.lineLen(row: cursor.row + 1);
      final newColumn = min(nextLineLength, cursor.stickyColumn);
      newCursor = Cursor(
        row: cursor.row + 1,
        column: newColumn,
        stickyColumn: cursor.stickyColumn,
      );
    }

    state = state.copyWith(cursor: newCursor);
  }
}
