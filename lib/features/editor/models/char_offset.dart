import 'package:freezed_annotation/freezed_annotation.dart';

part 'char_offset.freezed.dart';

@freezed
sealed class CharOffset with _$CharOffset {
  const factory CharOffset({@Default(0) int start, @Default(0) int end}) =
      _CharOffset;
}
