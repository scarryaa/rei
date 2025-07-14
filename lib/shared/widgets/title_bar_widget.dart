import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

class TitleBarWidget extends HookConsumerWidget {
  const TitleBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileExplorerState = ref.watch(fileProvider);
    final fileNotifier = ref.read(fileProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x10FFFFFF), width: 1.0),
        ),
      ),
      height: 30.0,
      child: MoveWindow(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: Platform.isMacOS ? 80.0 : 8.0),
            TextButton(
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0.0, 0.0)),
                foregroundColor: WidgetStatePropertyAll(Color((0xAAFFFFFF))),
              ),
              onPressed: () => fileNotifier.selectDirectory(),
              child: Text(
                fileExplorerState.root?.path
                        .split(Platform.pathSeparator)
                        .last ??
                    'Select a directory',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
