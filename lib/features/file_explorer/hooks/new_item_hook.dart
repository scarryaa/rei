import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rei/features/file_explorer/models/new_item_state.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

NewItemState useNewItemCreation(File notifier) {
  final isMakingNewFile = useState(false);
  final isMakingNewFolder = useState(false);
  final newItemPath = useState('');
  final textFieldFocusNode = useFocusNode();
  final textFieldController = useTextEditingController();

  void startFileCreation(String path) {
    isMakingNewFile.value = true;
    isMakingNewFolder.value = false;
    textFieldController.clear();
    newItemPath.value = path;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldFocusNode.requestFocus();
    });
  }

  void startFolderCreation(String path) {
    isMakingNewFolder.value = true;
    isMakingNewFile.value = false;
    textFieldController.clear();
    newItemPath.value = path;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldFocusNode.requestFocus();
    });
  }

  void cancelCreation() {
    isMakingNewFile.value = false;
    isMakingNewFolder.value = false;
    textFieldController.clear();
    newItemPath.value = '';
  }

  void createFile(String? fileName) {
    if (fileName != null &&
        fileName.isNotEmpty &&
        newItemPath.value.isNotEmpty) {
      final finalPath = notifier.createNewFile(newItemPath.value, fileName);
      notifier.selectFile(finalPath);
    }

    cancelCreation();
  }

  void createFolder(String? folderName) {
    if (folderName != null &&
        folderName.isNotEmpty &&
        newItemPath.value.isNotEmpty) {
      final finalPath = notifier.createNewFolder(newItemPath.value, folderName);
      notifier.selectFile(finalPath);
    }

    cancelCreation();
  }

  useEffect(() {
    void focusListener() {
      if (!textFieldFocusNode.hasFocus) {
        if (isMakingNewFolder.value) {
          createFolder(textFieldController.text.trim());
        } else if (isMakingNewFile.value) {
          createFile(textFieldController.text.trim());
        }
      }
    }

    textFieldFocusNode.addListener(focusListener);

    return () => textFieldFocusNode.removeListener(focusListener);
  }, [textFieldFocusNode]);

  return NewItemState(
    isMakingNewFile: isMakingNewFile.value,
    isMakingNewFolder: isMakingNewFolder.value,
    textFieldController: textFieldController,
    textFieldFocusNode: textFieldFocusNode,
    newItemPath: newItemPath.value,
    startFileCreation: startFileCreation,
    startFolderCreation: startFolderCreation,
    createFile: createFile,
    createFolder: createFolder,
    cancelCreation: cancelCreation,
  );
}
