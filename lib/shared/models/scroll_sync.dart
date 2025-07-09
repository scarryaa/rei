import 'package:freezed_annotation/freezed_annotation.dart';

part 'scroll_sync.freezed.dart';

@freezed
sealed class ScrollSyncState with _$ScrollSyncState {
  const factory ScrollSyncState({
    @Default(0.0) double offset,
    @Default(false) bool isScrolling,
    String? activeController,
  }) = _ScrollSyncState;
}
