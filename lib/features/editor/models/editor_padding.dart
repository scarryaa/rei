import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_padding.freezed.dart';

@freezed
sealed class EditorPadding with _$EditorPadding {
  const factory EditorPadding({
    @Default(0.0) double horizontal,
    @Default(0.0) double vertical,
  }) = _EditorPadding;
}
