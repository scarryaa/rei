import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
import 'package:rei/shared/widgets/context_menu_widget.dart';
import 'package:rei/shared/widgets/interactive_button_widget.dart';

class TabWidget extends HookConsumerWidget {
  const TabWidget({super.key, required this.state});

  final TabState state;

  static const double outerPading = 10.0;
  static const double spacing = 8.0;
  static const double maxHeight = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);
    final notifier = ref.read(tabProvider.notifier);

    return Listener(
      onPointerDown: (event) async {
        if (event.buttons == kMiddleMouseButton) {
          if (state.isDirty) {
            final confirmed = await _showCloseConfirmation(
              context,
              isMultiple: false,
            );
            if (!confirmed) return;
          }
          notifier.removeTab(state.path);
        }
      },
      child: GestureDetector(
        onTapDown: (details) => notifier.markActive(state.path),
        onSecondaryTapDown: (details) => ContextMenuWidget.show(
          context: context,
          position: details.globalPosition,
          items: [
            ContextMenuItem(
              title: 'Close',
              onTap: () async {
                if (state.isDirty) {
                  final confirmed = await _showCloseConfirmation(
                    context,
                    isMultiple: false,
                  );

                  if (!confirmed) return;
                }

                notifier.removeTab(state.path);
              },
            ),
            ContextMenuItem(
              title: 'Close others',
              onTap: () async {
                final allTabs = ref.read(tabProvider);
                final affectedTabs = allTabs.where(
                  (tab) => tab.path != state.path,
                );
                final hasDirty = affectedTabs.any((tab) => tab.isDirty);

                if (hasDirty) {
                  final confirmed = await _showCloseConfirmation(
                    context,
                    isMultiple: true,
                  );

                  if (!confirmed) return;
                }

                notifier.closeOtherTabs(state.path);
              },
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              title: 'Close left',
              onTap: () async {
                final allTabs = ref.read(tabProvider);
                final targetIndex = allTabs.indexWhere(
                  (tab) => tab.path == state.path,
                );

                if (targetIndex <= 0) return;

                final affectedTabs = allTabs.sublist(0, targetIndex);
                final hasDirty = affectedTabs.any((tab) => tab.isDirty);

                if (hasDirty) {
                  final confirmed = await _showCloseConfirmation(
                    context,
                    isMultiple: true,
                  );

                  if (!confirmed) return;
                }

                notifier.closeLeftTabs(state.path);
              },
            ),
            ContextMenuItem(
              title: 'Close right',
              onTap: () async {
                final allTabs = ref.read(tabProvider);
                final targetIndex = allTabs.indexWhere(
                  (tab) => tab.path == state.path,
                );

                if (targetIndex == -1 || targetIndex == allTabs.length - 1) {
                  return;
                }

                final affectedTabs = allTabs.sublist(targetIndex + 1);
                final hasDirty = affectedTabs.any((tab) => tab.isDirty);

                if (hasDirty) {
                  final confirmed = await _showCloseConfirmation(
                    context,
                    isMultiple: true,
                  );

                  if (!confirmed) return;
                }

                notifier.closeRightTabs(state.path);
              },
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              title: 'Close clean',
              onTap: () => notifier.closeCleanTabs(),
            ),
            ContextMenuItem(
              title: 'Close all',
              onTap: () async {
                final allTabs = ref.read(tabProvider);
                final hasDirty = allTabs.any((tab) => tab.isDirty);
                if (hasDirty) {
                  final confirmed = await _showCloseConfirmation(
                    context,
                    isMultiple: true,
                  );
                  if (!confirmed) return;
                }
                notifier.closeAllTabs();
              },
            ),
          ],
        ),
        child: MouseRegion(
          onEnter: (event) => isHovered.value = true,
          onExit: (event) => isHovered.value = false,
          child: Container(
            padding: EdgeInsetsDirectional.symmetric(horizontal: outerPading),
            decoration: BoxDecoration(
              color: state.isActive
                  ? Color(0x10FFFFFF)
                  : isHovered.value
                  ? Color(0x07FFFFFF)
                  : Colors.transparent,
              border: Border(
                right: BorderSide(color: Color(0x10FFFFFF), width: 1.0),
              ),
            ),
            height: maxHeight,
            child: Row(
              spacing: spacing,
              children: [
                _buildDirtyIndicator(),
                Text(
                  state.name,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontFamily: 'IBM Plex Sans',
                    color: Colors.white,
                  ),
                ),
                _buildCloseButton(
                  context,
                  isHovered.value,
                  () => notifier.removeTab(state.path),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirtyIndicator() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state.isDirty ? Colors.lightBlue : Colors.transparent,
      ),
      width: 8.0,
      height: 8.0,
    );
  }

  Widget _buildCloseButton(
    BuildContext context,
    bool isTabHovered,
    void Function() onClose,
  ) {
    return InteractiveButtonWidget(
      onTapDown: () async {
        if (state.isDirty) {
          final confirmed = await _showCloseConfirmation(
            context,
            isMultiple: false,
          );
          if (!confirmed) return;
        }
        onClose();
      },
      child: Icon(
        Icons.close_rounded,
        size: 13.0,
        color: isTabHovered ? Colors.white : Colors.transparent,
      ),
    );
  }

  Future<bool> _showCloseConfirmation(
    BuildContext context, {
    required bool isMultiple,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Color(0x10FFFFFF), width: 1.0),
              ),
              backgroundColor: Colors.black,
              title: Text(isMultiple ? 'Close Tabs?' : 'Close Tab?'),
              content: Text(
                isMultiple
                    ? 'Some tabs have unsaved changes. Are you sure you want to close them?'
                    : 'This tab has unsaved changes. Are you sure you want to close it?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
