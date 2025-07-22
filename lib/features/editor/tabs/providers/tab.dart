import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:rei/shared/services/file_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab.g.dart';

final activeTabProvider = Provider<TabState?>((ref) {
  final tabs = ref.watch(tabProvider);
  return tabs.isNotEmpty
      ? tabs.firstWhere((tab) => tab.isActive == true)
      : null;
});

@riverpod
class Tab extends _$Tab {
  static String defaultTabPrefix = 'rei_tmp';

  @override
  List<TabState> build() {
    return [];
  }

  // TODO: Show confirmation for dirty tabs for closing methods.
  void closeAllTabs() {
    state = [];
  }

  void closeCleanTabs() {
    final newState = List<TabState>.from(state);
    final activeIndex = newState.indexWhere(
      (tab) => tab.isActive && !tab.isDirty,
    );
    final activeTabWasClosed = activeIndex != -1;

    newState.removeWhere((tab) => !tab.isDirty);

    if (activeTabWasClosed && newState.isNotEmpty) {
      newState[newState.length - 1] = newState[newState.length - 1].copyWith(
        isActive: true,
      );
    }

    state = newState;
  }

  void closeLeftTabs(String path) {
    final targetIndex = state.indexWhere((tab) => tab.path == path);
    if (targetIndex <= 0) return;

    final newState = List<TabState>.from(state);
    final activeIndex = newState.indexWhere((tab) => tab.isActive);
    final closedTabWasActive = activeIndex >= 0 && activeIndex < targetIndex;
    newState.removeRange(0, targetIndex);

    if (closedTabWasActive) {
      newState[0] = newState[0].copyWith(isActive: true);
    }

    state = newState;
  }

  void closeRightTabs(String path) {
    final targetIndex = state.indexWhere((tab) => tab.path == path);
    final length = state.length;
    if (targetIndex == -1 || targetIndex == length - 1) return;

    final newState = List<TabState>.from(state);
    final activeIndex = newState.indexWhere((tab) => tab.isActive);
    final closedTabWasActive = activeIndex > targetIndex;
    newState.removeRange(targetIndex + 1, length);

    if (closedTabWasActive) {
      newState[newState.length - 1] = newState[newState.length - 1].copyWith(
        isActive: true,
      );
    }

    state = newState;
  }

  void closeOtherTabs(String path) {
    final newState = List<TabState>.from(state);
    newState.removeWhere((tab) => tab.path != path);

    state = newState;
  }

  void updatePath(String oldPath, String newPath) {
    state = state.map((tab) {
      if (tab.path == oldPath) {
        final newName = newPath.split(Platform.pathSeparator).last;

        return tab.copyWith(path: newPath, name: newName);
      } else {
        return tab;
      }
    }).toList();
  }

  void updateOriginalContent(String path, String content) {
    state = state.map((tab) {
      if (tab.path == path) {
        return tab.copyWith(originalContent: content, isDirty: false);
      }

      return tab;
    }).toList();
  }

  void updateScrollOffset(String path, Offset offset) {
    state = state.map((tab) {
      if (tab.path == path) {
        return tab.copyWith(scrollOffset: offset);
      }

      return tab;
    }).toList();
  }

  void updateTabState({
    required String path,
    required EditorState editorState,
  }) {
    final tabIndex = state.indexWhere((tab) => tab.path == path);

    if (tabIndex != -1) {
      state = state.map((tab) {
        if (tab.path == path) {
          return tab.copyWith(
            savedState: editorState,
            isDirty: _checkDirty(tab, editorState.buffer.toString()),
          );
        }

        return tab;
      }).toList();
    }
  }

  bool _checkDirty(TabState tab, String content) {
    if (tab.originalContent == content) {
      return false;
    }

    return true;
  }

  void updateTabPathsByDir(String oldPath, String newPath) {
    final newTabs = state.map((tab) {
      if (tab.path.startsWith(oldPath)) {
        final updatedPath = newPath + tab.path.substring(oldPath.length);
        final updatedName = updatedPath.split(Platform.pathSeparator).last;

        final fileContents = tab.originalContent;

        final updatedNotifier = ref.read(editorProvider(updatedPath).notifier);
        updatedNotifier.openFile(
          fileContents,
          tab.savedState?.cursor,
          tab.savedState?.selection,
        );
        updateOriginalContent(updatedPath, fileContents);

        return tab.copyWith(
          path: updatedPath,
          name: updatedName,
          originalContent: fileContents,
        );
      }

      return tab;
    }).toList();

    state = newTabs;
  }

  bool addTab(String name, String path) {
    final List<TabState> newTabs = state
        .map((tab) => tab.copyWith(isActive: false))
        .toList();

    final String adjustedPath = path.isEmpty
        ? defaultTabPrefix + DateTime.now().toString()
        : path;

    final existingTabIndex = state.indexWhere(
      (tab) => tab.path == adjustedPath,
    );
    if (existingTabIndex == -1) {
      newTabs.add(TabState(path: adjustedPath, name: name, isActive: true));

      state = newTabs;
      return true;
    } else {
      // Tab already exists, just activate it.
      final existingTabPath = state[existingTabIndex].path;
      final List<TabState> newTabs = state
          .map((tab) => tab.copyWith(isActive: tab.path == existingTabPath))
          .toList();

      state = newTabs;
    }

    return false;
  }

  void openFileInTab(String path) {
    final tabsEmpty = state.isEmpty;
    final name = path.split(Platform.pathSeparator).last;
    final success = addTab(name, path);

    // If success is false, it means there is already an open tab with the same path.
    if (success) {
      final fileContents = FileService.readFile(path);

      if (tabsEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final updatedNotifier = ref.read(editorProvider(path).notifier);
          updatedNotifier.openFile(fileContents, null, null);
          updateOriginalContent(path, fileContents);
        });
      } else {
        final updatedNotifier = ref.read(editorProvider(path).notifier);
        updatedNotifier.openFile(fileContents, null, null);
        updateOriginalContent(path, fileContents);
      }
    }
  }

  void removeTab(String path) {
    final currentIndex = state.indexWhere((tab) => tab.path == path);
    final wasActiveTab = state.any((tab) => tab.path == path && tab.isActive);

    if (currentIndex == -1) return;

    final List<TabState> updatedTabs = state
        .where((tab) => tab.path != path)
        .toList();

    if (updatedTabs.isNotEmpty) {
      String newActiveTabPath;

      if (wasActiveTab) {
        if (currentIndex < updatedTabs.length) {
          newActiveTabPath = updatedTabs[currentIndex].path;
        } else if (currentIndex > 0) {
          newActiveTabPath = updatedTabs[currentIndex - 1].path;
        } else {
          newActiveTabPath = updatedTabs[0].path;
        }
      } else {
        final activeTab = updatedTabs.firstWhere(
          (tab) => state.any(
            (original) => original.path == tab.path && original.isActive,
          ),
          orElse: () => updatedTabs[0],
        );
        newActiveTabPath = activeTab.path;
      }

      final List<TabState> newTabs = updatedTabs
          .map((tab) => tab.copyWith(isActive: tab.path == newActiveTabPath))
          .toList();

      state = newTabs;
    } else {
      state = [];
    }
  }

  void markActive(String path) {
    final tabIndex = state.indexWhere((tab) => tab.path == path);

    if (tabIndex != -1) {
      final List<TabState> newTabs = state
          .map((tab) => tab.copyWith(isActive: path == tab.path))
          .toList();

      state = newTabs;
    }
  }
}
