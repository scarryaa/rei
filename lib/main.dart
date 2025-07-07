import 'package:flutter/material.dart';
import 'package:rei/features/editor/screens/editor_screen.dart';
import 'package:rei/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EditorScreen());
  }
}
