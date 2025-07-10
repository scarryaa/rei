import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab.g.dart';

@riverpod
class Tab extends _$Tab {
  @override
  List<TabState> build() {
    return [];
  }

  void addTab(String name, String path) {
    final List<TabState> newTabs = state
        .map((tab) => tab.copyWith(isActive: false))
        .toList();
    newTabs.add(TabState(path: path, name: name, isActive: true));

    state = newTabs;
  }

  void markActive(String path) {
    final List<TabState> newTabs = state
        .map((tab) => tab.copyWith(isActive: path == tab.path))
        .toList();

    state = newTabs;
  }
}
