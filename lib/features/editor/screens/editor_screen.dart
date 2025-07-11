import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/models/font_metrics.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/features/editor/tabs/widgets/tab_bar_widget.dart';
import 'package:rei/features/editor/widgets/editor_widget.dart';
import 'package:rei/features/file_explorer/widgets/file_explorer_widget.dart';
import 'package:rei/features/gutter/widgets/gutter_widget.dart';

class EditorScreen extends HookConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabProvider);
    final tabNotifier = ref.read(tabProvider.notifier);

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
          child: tabs.isNotEmpty
              ? Column(
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
                )
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.0,
                  children: [
                    Icon(Icons.tab, size: 64.0, color: Color(0x50FFFFFF)),
                    TextButton(
                      onPressed: () => tabNotifier.addTab('Untitled', ''),
                      child: Text(
                        'Open a new tab',
                        style: textStyle.copyWith(fontFamily: 'IBM Plex Sans'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
