import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:file_picker/file_picker.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';

class FileService {
  static final _fileSelectedController = StreamController<String>.broadcast();
  static Stream<String> get fileSelectedStream =>
      _fileSelectedController.stream;

  static void selectFile(String path) {
    _fileSelectedController.add(path);
  }

  static String readFile(String path) {
    File file = File(path);

    final content = file.readAsStringSync();
    return content;
  }

  static void writeFile(String path, String content) {
    if (path.startsWith(Tab.defaultTabPrefix)) {
      writeFileAs(path, content);
    } else {
      File file = File(path);

      file.writeAsStringSync(content);
    }
  }

  static Future<String?> writeFileAs(String path, String content) async {
    bool isTemporaryFile = path.startsWith(Tab.defaultTabPrefix);
    String? initialDirectory = isTemporaryFile ? null : p.dirname(path);

    final newPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save as...',
      fileName: isTemporaryFile ? '' : path.split(Platform.pathSeparator).last,
      initialDirectory: initialDirectory,
    );

    if (newPath != null && newPath.isNotEmpty) {
      File file = File(newPath);
      file.writeAsStringSync(content);

      return newPath;
    }

    return null;
  }
}
