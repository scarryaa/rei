import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab.g.dart';

@riverpod
class Tab extends _$Tab {
  static String defaultTabPrefix = 'rei_tmp';

  @override
  List<TabState> build() {
    return [];
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

  void markActive(String path) {
    final List<TabState> newTabs = state
        .map((tab) => tab.copyWith(isActive: path == tab.path))
        .toList();

    state = newTabs;
  }
}
