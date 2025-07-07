import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/bridge/rust/frb_generated.dart';
import 'package:rei/features/editor/screens/editor_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(ProviderScope(child: const ReiApp()));
}

class ReiApp extends StatelessWidget {
  const ReiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EditorScreen(), debugShowCheckedModeBanner: false);
  }
}
