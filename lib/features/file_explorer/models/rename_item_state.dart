import 'package:flutter/material.dart';

class RenameItemState {
  final bool isRenaming;
  final TextEditingController textFieldController;
  final FocusNode textFieldFocusNode;
  final String currentItemPath;
  final (String, String) Function(String, String) renameItem;
  final Function(String, String) startRename;
  final Function() cancelRename;

  RenameItemState({
    required this.isRenaming,
    required this.textFieldController,
    required this.currentItemPath,
    required this.textFieldFocusNode,
    required this.renameItem,
    required this.startRename,
    required this.cancelRename,
  });
}
