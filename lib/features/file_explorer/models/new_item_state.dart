import 'package:flutter/material.dart';

class NewItemState {
  final bool isMakingNewFile;
  final bool isMakingNewFolder;
  final TextEditingController textFieldController;
  final FocusNode textFieldFocusNode;
  final String newItemPath;
  final Function(String) startFileCreation;
  final Function(String) startFolderCreation;
  final Function(String?) createFile;
  final Function(String?) createFolder;
  final Function() cancelCreation;

  NewItemState({
    required this.isMakingNewFile,
    required this.isMakingNewFolder,
    required this.textFieldController,
    required this.newItemPath,
    required this.textFieldFocusNode,
    required this.startFileCreation,
    required this.startFolderCreation,
    required this.createFile,
    required this.createFolder,
    required this.cancelCreation,
  });
}
