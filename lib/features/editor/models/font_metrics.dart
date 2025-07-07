import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart' as meta;

part 'font_metrics.freezed.dart';

@freezed
@meta.immutable
sealed class FontMetrics with _$FontMetrics {
  const factory FontMetrics({
    required double lineHeight,
    required double charWidth,
  }) = _FontMetrics;
}
