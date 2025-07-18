import 'package:flutter/material.dart';
import 'package:rei/features/file_explorer/widgets/file_explorer_widget.dart';

class EditableItemWidget extends StatelessWidget {
  const EditableItemWidget({
    super.key,
    required this.isDirectory,
    required this.depth,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onEditingComplete,
  });

  final bool isDirectory;
  final int depth;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmitted;
  final Function() onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.only(
          left:
              FileEntryWidget.leftPadding +
              (depth * FileEntryWidget.depthPadding),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white, fontSize: 14.0),
          focusNode: focusNode,
          cursorHeight: 14.0,
          decoration: InputDecoration(
            icon: Icon(
              size: FileEntryWidget.iconSize,
              isDirectory ? Icons.folder : Icons.insert_drive_file_rounded,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            enabledBorder: OutlineInputBorder(
              gapPadding: 0.0,
              borderSide: BorderSide(color: Colors.lightBlue),
            ),
            focusedBorder: OutlineInputBorder(
              gapPadding: 0.0,
              borderSide: BorderSide(color: Colors.lightBlue),
            ),
            border: OutlineInputBorder(
              gapPadding: 0.0,
              borderSide: BorderSide(color: Colors.lightBlue),
            ),
          ),
          maxLines: 1,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
        ),
      ),
    );
  }
}
