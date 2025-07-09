import 'dart:math';

import 'package:rei/bridge/rust/api/buffer.dart';
import 'package:rei/bridge/rust/api/cursor.dart';
import 'package:rei/bridge/rust/api/selection.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor.g.dart';

@riverpod
class Editor extends _$Editor {
  @override
  EditorState build() {
    return EditorState(
      buffer: Buffer(),
      cursor: Cursor.default_(),
      selection: Selection.default_(),
    );
  }

  void insert(String text) {
    if (!state.selection.isEmpty()) {
      deleteSelection();
    }

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
    if (!state.selection.isEmpty()) {
      deleteSelection();
      return;
    }

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
  void moveTo(Cursor cursor) {
    state = state.copyWith(cursor: cursor);
  }

  void moveLeft(bool extendSelection) {
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

    startSelection(cursor, extendSelection);
    state = state.copyWith(cursor: newCursor);
    updateSelection(newCursor, extendSelection);
  }

  void moveRight(bool extendSelection) {
    final cursor = state.cursor;
    Cursor newCursor = cursor;
    final lineCount = state.buffer.lineCountWithTrailingNewline() - 1;
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

    startSelection(cursor, extendSelection);
    state = state.copyWith(cursor: newCursor);
    updateSelection(newCursor, extendSelection);
  }

  void moveUp(bool extendSelection) {
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

    startSelection(cursor, extendSelection);
    state = state.copyWith(cursor: newCursor);
    updateSelection(newCursor, extendSelection);
  }

  void moveDown(bool extendSelection) {
    final cursor = state.cursor;
    Cursor newCursor = cursor;

    final lineCount = state.buffer.lineCountWithTrailingNewline() - 1;
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

    startSelection(cursor, extendSelection);
    state = state.copyWith(cursor: newCursor);
    updateSelection(newCursor, extendSelection);
  }

  void startSelection(Cursor cursor, bool extendSelection) {
    // Start a new selection.
    if (state.selection == Selection.default_() && extendSelection) {
      state = state.copyWith(
        selection: Selection(start: cursor, end: cursor),
      );
    }
  }

  void updateSelection(Cursor cursor, bool extendSelection) {
    Selection newSelection = state.selection;

    // Extend the selection if flag is set.
    if (extendSelection) {
      newSelection = Selection(start: newSelection.start, end: cursor);
      state = state.copyWith(selection: newSelection);
    } else {
      clearSelection();
    }
  }

  void clearSelection() {
    state = state.copyWith(selection: Selection.default_());
  }

  void removeRange(int startRow, int startColumn, int endRow, int endColumn) {
    final (newRow, newColumn) = state.buffer.removeRange(
      startRow: startRow,
      startColumn: startColumn,
      endRow: endRow,
      endColumn: endColumn,
    );
    final newCursor = Cursor(
      row: newRow,
      column: newColumn,
      stickyColumn: newColumn,
    );

    state = state.copyWith(buffer: state.buffer, cursor: newCursor);
  }

  void deleteSelection() {
    final normalized = state.selection.normalized();

    removeRange(
      normalized.start.row,
      normalized.start.column,
      normalized.end.row,
      normalized.end.column,
    );
    clearSelection();
  }

  void selectLine(int row) {
    final lineLength = state.buffer.lineLen(row: row);

    final startCursor = Cursor(row: row, column: 0, stickyColumn: 0);
    final endCursor = Cursor(
      row: row,
      column: lineLength,
      stickyColumn: lineLength,
    );

    final newSelection = Selection(start: startCursor, end: endCursor);

    state = state.copyWith(selection: newSelection);
  }

  void selectAll() {
    final lineCount = state.buffer.lineCountWithTrailingNewline() - 1;
    final lastLineLength = state.buffer.lineLen(row: lineCount);
    final endCursor = Cursor(
      row: lineCount,
      column: lastLineLength,
      stickyColumn: lastLineLength,
    );
    final newSelection = Selection(start: Cursor.default_(), end: endCursor);

    state = state.copyWith(selection: newSelection, cursor: endCursor);
  }

  String getTextInRange(
    int startRow,
    int startColumn,
    int endRow,
    int endColumn,
  ) {
    return state.buffer.textInRange(
      startRow: startRow,
      startColumn: startColumn,
      endRow: endRow,
      endColumn: endColumn,
    );
  }

  String getSelectedText() {
    final normalized = state.selection.normalized();

    return getTextInRange(
      normalized.start.row,
      normalized.start.column,
      normalized.end.row,
      normalized.end.column,
    );
  }
}
