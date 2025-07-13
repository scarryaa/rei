import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rei/features/editor/models/state.dart';

part 'tab_state.freezed.dart';

@freezed
sealed class TabState with _$TabState {
  const factory TabState({
    required String path,
    required String name,
    @Default('') String originalContent,
    @Default(false) bool isActive,
    @Default(false) bool isDirty,
    @Default(null) EditorState? savedState,
    @Default(Offset.zero) Offset scrollOffset,
  }) = _TabState;
}
