import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rei/bridge/rust/api/buffer.dart';
import 'package:rei/bridge/rust/api/cursor.dart';

part 'state.freezed.dart';

@freezed
sealed class EditorState with _$EditorState {
  const factory EditorState({required Buffer buffer, required Cursor cursor}) =
      _EditorState;
}
