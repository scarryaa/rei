import 'package:freezed_annotation/freezed_annotation.dart';

part 'visible_lines.freezed.dart';

@freezed
sealed class VisibleLines with _$VisibleLines {
  const factory VisibleLines({@Default(0) int first, @Default(0) int last}) =
      _VisibleLines;
}
