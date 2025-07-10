import 'dart:async';
import 'dart:io';

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
}
