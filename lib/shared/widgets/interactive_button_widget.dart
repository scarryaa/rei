import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InteractiveButtonWidget extends HookConsumerWidget {
  const InteractiveButtonWidget({
    super.key,
    this.child,
    this.onTapDown,
    this.onTapUp,
    this.onHoverEnter,
    this.onHoverExit,
    this.innerPadding = 4.0,
  });

  final Function()? onTapDown;
  final Function()? onTapUp;
  final Function()? onHoverEnter;
  final Function()? onHoverExit;
  final Widget? child;
  final double innerPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPressed = useState(false);
    final isHovered = useState(false);

    return Center(
      child: MouseRegion(
        onEnter: (event) {
          isHovered.value = true;
          onHoverEnter?.call();
        },
        onExit: (event) {
          isHovered.value = false;
          onHoverExit?.call();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            isPressed.value = true;
            onTapDown?.call();
          },
          onTapUp: (details) {
            isPressed.value = false;
            onTapUp?.call();
          },
          onTapCancel: () {
            isPressed.value = false;
          },
          child: Container(
            padding: EdgeInsetsDirectional.all(innerPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: isPressed.value
                  ? Color(0x25FFFFFF)
                  : isHovered.value
                  ? Color(0x30FFFFFF)
                  : Colors.transparent,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
