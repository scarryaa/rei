import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/file_explorer/providers/file.dart';

class FileExplorerWidget extends HookConsumerWidget {
  const FileExplorerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileProvider);

    return Container(
      width: 250.0,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: const Color(0x10FFFFFF))),
      ),
      child: state == null ? _buildEmptyView() : Container(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        spacing: 8.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder, size: 64.0, color: Color(0x20FFFFFF)),
          TextButton(onPressed: () {}, child: Text('Select a directory')),
        ],
      ),
    );
  }
}
