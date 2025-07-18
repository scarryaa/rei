import 'package:flutter/material.dart';

class NewItemState {
  final bool isMakingNewFile;
  final bool isMakingNewFolder;
  final TextEditingController textFieldController;
  final FocusNode textFieldFocusNode;
  final Function() startFileCreation;
  final Function() startFolderCreation;
  final Function(String, String?) createFile;
  final Function(String, String?) createFolder;
  final Function() cancelCreation;

  NewItemState({
    required this.isMakingNewFile,
    required this.isMakingNewFolder,
    required this.textFieldController,
    required this.textFieldFocusNode,
    required this.startFileCreation,
    required this.startFolderCreation,
    required this.createFile,
    required this.createFolder,
    required this.cancelCreation,
  });
}
