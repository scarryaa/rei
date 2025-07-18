import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/bridge/rust/frb_generated.dart';
import 'package:rei/features/editor/screens/editor_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(ProviderScope(child: const ReiApp()));

  doWhenWindowReady(() {
    const initialSize = Size(800, 600);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class ReiApp extends StatelessWidget {
  const ReiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditorScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'IBM Plex Sans',
        ),
        scrollbarTheme: ScrollbarThemeData(
          radius: Radius.zero,
          mainAxisMargin: 0.0,
          crossAxisMargin: 0.0,
          thumbColor: WidgetStatePropertyAll<Color>(Color(0x50FFFFFF)),
          thickness: WidgetStatePropertyAll<double>(12.0),
        ),
      ),
    );
  }
}
