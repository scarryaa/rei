import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rei/features/file_explorer/models/new_item_state.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

NewItemState useNewItemCreation(File notifier) {
  final isMakingNewFile = useState(false);
  final isMakingNewFolder = useState(false);
  final textFieldFocusNode = useFocusNode();
  final textFieldController = useTextEditingController();

  void startFileCreation() {
    isMakingNewFile.value = true;
    isMakingNewFolder.value = false;
    textFieldController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldFocusNode.requestFocus();
    });
  }

  void startFolderCreation() {
    isMakingNewFolder.value = true;
    isMakingNewFile.value = false;
    textFieldController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldFocusNode.requestFocus();
    });
  }

  void cancelCreation() {
    isMakingNewFile.value = false;
    isMakingNewFolder.value = false;
    textFieldController.clear();
  }

  void createFile(String path, String? fileName) {
    if (fileName != null && fileName.isNotEmpty) {
      final finalPath = notifier.createNewFile(path, fileName);
      notifier.selectFile(finalPath);
    }

    cancelCreation();
  }

  void createFolder(String path, String? folderName) {
    if (folderName != null && folderName.isNotEmpty) {
      final finalPath = notifier.createNewFolder(path, folderName);
      notifier.selectFile(finalPath);
    }

    cancelCreation();
  }

  return NewItemState(
    isMakingNewFile: isMakingNewFile.value,
    isMakingNewFolder: isMakingNewFolder.value,
    textFieldController: textFieldController,
    textFieldFocusNode: textFieldFocusNode,
    startFileCreation: startFileCreation,
    startFolderCreation: startFolderCreation,
    createFile: createFile,
    createFolder: createFolder,
    cancelCreation: cancelCreation,
  );
}
