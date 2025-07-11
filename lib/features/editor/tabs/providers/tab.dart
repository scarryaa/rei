import 'package:rei/features/editor/models/state.dart';
import 'package:rei/features/editor/tabs/models/tab_state.dart';
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

  void updateTabState({
    required String path,
    required EditorState editorState,
  }) {
    final tabIndex = state.indexWhere((tab) => tab.path == path);

    if (tabIndex != -1) {
      state = state.map((tab) {
        if (tab.path == path) {
          return tab.copyWith(savedState: editorState);
        }

        return tab;
      }).toList();
    }
  }

  void addTab(String name, String path) {
    final List<TabState> newTabs = state
        .map((tab) => tab.copyWith(isActive: false))
        .toList();

    final String adjustedPath = path.isEmpty
        ? defaultTabPrefix + DateTime.now().toString()
        : path;

    newTabs.add(TabState(path: adjustedPath, name: name, isActive: true));

    state = newTabs;
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
