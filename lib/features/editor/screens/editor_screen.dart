import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/features/editor/tabs/widgets/tab_bar_widget.dart';
import 'package:rei/features/editor/widgets/editor_widget.dart';
import 'package:rei/features/file_explorer/widgets/file_explorer_widget.dart';
import 'package:rei/features/gutter/widgets/gutter_widget.dart';
import 'package:rei/shared/services/file_service.dart';
import 'package:rei/shared/widgets/title_bar_widget.dart';

class EditorScreen extends HookConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabProvider);
    final tabNotifier = ref.read(tabProvider.notifier);

    useEffect(() {
      FileService.fileSelectedStream.listen((filePath) {
        tabNotifier.openFileInTab(filePath);
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

    return Column(
      children: [
        TitleBarWidget(),
        Expanded(
          child: Row(
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
                      child: EmptyEditorState(
                        textStyle: textStyle,
                        onAddTab: () => tabNotifier.addTab('Untitled', ''),
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

class EmptyEditorState extends StatelessWidget {
  const EmptyEditorState({
    super.key,
    required this.textStyle,
    required this.onAddTab,
  });

  final TextStyle textStyle;
  final VoidCallback onAddTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tab, size: 64.0, color: Color(0x50FFFFFF)),
          TextButton(
            onPressed: onAddTab,
            child: Text(
              'Open a new tab',
              style: textStyle.copyWith(fontFamily: 'IBM Plex Sans'),
            ),
          ),
        ],
      ),
    );
  }
}
