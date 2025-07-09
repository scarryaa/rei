import 'package:flutter/material.dart';
import 'package:rei/shared/models/scroll_sync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_sync.g.dart';

@riverpod
class ScrollSync extends _$ScrollSync {
  @override
  ScrollSyncState build() {
    return const ScrollSyncState();
  }

  void updateScrollPosition(double offset, String controllerId) {
    Future.microtask(() {
      state = state.copyWith(
        offset: offset,
        isScrolling: true,
        activeController: controllerId,
      );
    });
  }

  void startScrolling(String controllerId) {
    Future.microtask(() {
      state = state.copyWith(isScrolling: true, activeController: controllerId);
    });
  }
}

class ScrollControllerSync {
  final ScrollController controller;
  final String controllerId;
  final ScrollSync notifier;
  bool _isUpdating = false;

  ScrollControllerSync({
    required this.controller,
    required this.controllerId,
    required this.notifier,
  });

  void startListening() {
    controller.addListener(_onScroll);
  }

  void stopListening() {
    controller.removeListener(_onScroll);
  }

  void _onScroll() {
    if (!_isUpdating && controller.hasClients) {
      notifier.updateScrollPosition(controller.offset, controllerId);
    }
  }

  void syncTo(double offset) {
    if (controller.hasClients && !_isUpdating) {
      _isUpdating = true;

      final clampedOffset = offset.clamp(
        0.0,
        controller.position.maxScrollExtent,
      );

      if ((controller.offset - clampedOffset).abs() > 0.1) {
        controller.jumpTo(clampedOffset);
      }

      _isUpdating = false;
    }
  }
}

extension ScrollControllerSyncExtension on ScrollController {
  ScrollControllerSync createSync(String id, ScrollSync notifier) {
    return ScrollControllerSync(
      controller: this,
      controllerId: id,
      notifier: notifier,
    );
  }
}
