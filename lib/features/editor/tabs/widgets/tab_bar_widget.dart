import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/features/editor/tabs/widgets/tab_widget.dart';
import 'package:rei/shared/widgets/interactive_button_widget.dart';

class TabBarWidget extends HookConsumerWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabProvider);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 40.0,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x10FFFFFF), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: tabs.map((tab) => TabWidget(state: tab)).toList(),
              ),
            ),
            NewTabButton(),
          ],
        ),
      ),
    );
  }
}

class NewTabButton extends HookConsumerWidget {
  const NewTabButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabNotifier = ref.read(tabProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x10FFFFFF), width: 1.0)),
      ),
      padding: EdgeInsetsDirectional.all(8.0),
      child: InteractiveButtonWidget(
        child: Icon(Icons.add_rounded, size: 15.0),
        onTapDown: () => tabNotifier.addTab('Untitled', ''),
      ),
    );
  }
}
