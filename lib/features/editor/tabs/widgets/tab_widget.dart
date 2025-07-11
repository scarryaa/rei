import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rei/features/editor/tabs/models/tab_state.dart';
import 'package:rei/features/editor/tabs/providers/tab.dart';
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
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) {
          notifier.removeTab(state.path);
        }
      },
      child: GestureDetector(
        onTapDown: (details) => notifier.markActive(state.path),
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

  Widget _buildCloseButton(bool isTabHovered, void Function() onClose) {
    return InteractiveButtonWidget(
      onTapDown: () => onClose(),
      child: Icon(
        Icons.close_rounded,
        size: 13.0,
        color: isTabHovered ? Colors.white : Colors.transparent,
      ),
    );
  }
}
