import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rei/features/file_explorer/models/rename_item_state.dart';
import 'package:rei/features/file_explorer/providers/file.dart';
import 'package:path/path.dart' as p;

RenameItemState useItemRename(String oldName, File notifier) {
  final isRenaming = useState(false);
  final currentItemPath = useState('');
  final textFieldFocusNode = useFocusNode();
  final textFieldController = useTextEditingController();

  void startRename(String itemPath, String currentName) {
    isRenaming.value = true;
    currentItemPath.value = p.dirname(itemPath);
    textFieldController.text = currentName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldFocusNode.requestFocus();
      textFieldController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: currentName.length,
      );
    });
  }

  void cancelRename() {
    isRenaming.value = false;
    textFieldController.clear();
    currentItemPath.value = '';
  }

  (String, String) renameItem(String oldName, String? newName) {
    String oldPath = '', finalPath = '';
    if (newName != null &&
        newName.isNotEmpty &&
        currentItemPath.value.isNotEmpty) {
      (oldPath, finalPath) = notifier.renameItem(
        currentItemPath.value,
        oldName,
        newName,
      );
      notifier.selectFile(finalPath);
    }

    cancelRename();

    return (oldPath, finalPath);
  }

  useEffect(() {
    void focusListener() {
      if (!textFieldFocusNode.hasFocus && isRenaming.value) {
        renameItem(oldName, textFieldController.text.trim());
      }
    }

    textFieldFocusNode.addListener(focusListener);

    return () => textFieldFocusNode.removeListener(focusListener);
  }, [textFieldFocusNode]);

  return RenameItemState(
    isRenaming: isRenaming.value,
    textFieldController: textFieldController,
    cancelRename: cancelRename,
    renameItem: renameItem,
    startRename: startRename,
    textFieldFocusNode: textFieldFocusNode,
    currentItemPath: currentItemPath.value,
  );
}
