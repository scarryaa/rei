import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/providers/editor.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/features/editor/tabs/widgets/tab_bar_widget.dart';
import 'package:rei/features/editor/widgets/editor_widget.dart';
import 'package:rei/features/file_explorer/widgets/file_explorer_widget.dart';
import 'package:rei/features/gutter/widgets/gutter_widget.dart';
import 'package:rei/shared/services/file_service.dart';

class EditorScreen extends HookConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabProvider);
    final tabNotifier = ref.read(tabProvider.notifier);

    useEffect(() {
      FileService.fileSelectedStream.listen((filePath) {
        bool tabsEmpty = tabs.isEmpty;
        final fileContents = FileService.readFile(filePath);

        // TODO: Move this logic to a dedicated service?
        final name = filePath.split(Platform.pathSeparator).last;
        final success = tabNotifier.addTab(name, filePath);

        // If success is false, it means there is already an open tab with the same path.
        if (success) {
          if (tabsEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final updatedNotifier = ref.read(
                editorProvider(filePath).notifier,
              );
              updatedNotifier.openFile(fileContents);
            });
          } else {
            final updatedNotifier = ref.read(editorProvider(filePath).notifier);
            updatedNotifier.openFile(fileContents);
          }
        }
      });

      return null;
    }, []);

    final textStyle = useMemoized(
      () => TextStyle(
        fontSize: 15.0,
        fontFamily: 'IBM Plex Mono',
        color: Colors.white,
      ),
    );

    final fontMetrics = useMemoized(() {
      final innerCharPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: 'W', style: textStyle),
      );
      innerCharPainter.layout();

      return FontMetrics(
        lineHeight: innerCharPainter.preferredLineHeight,
        charWidth: innerCharPainter.width,
      );
    }, [textStyle]);

    return Row(
      children: [
        FileExplorerWidget(),
        Expanded(
          child: Stack(
            children: [
              Visibility(
                visible: tabs.isNotEmpty,
                child: Column(
                  children: [
                    TabBarWidget(),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GutterWidget(
                            textStyle: textStyle,
                            fontMetrics: fontMetrics,
                          ),
                          Expanded(
                            child: EditorWidget(
                              textStyle: textStyle,
                              fontMetrics: fontMetrics,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: tabs.isEmpty,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8.0,
                        children: [
                          Icon(Icons.tab, size: 64.0, color: Color(0x50FFFFFF)),
                          TextButton(
                            onPressed: () => tabNotifier.addTab('Untitled', ''),
                            child: Text(
                              'Open a new tab',
                              style: textStyle.copyWith(
                                fontFamily: 'IBM Plex Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
