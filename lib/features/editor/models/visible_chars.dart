import 'package:freezed_annotation/freezed_annotation.dart';

part 'visible_chars.freezed.dart';

@freezed
sealed class VisibleChars with _$VisibleChars {
  const factory VisibleChars({@Default(0) int first, @Default(0) int last}) =
      _VisibleChars;
}
