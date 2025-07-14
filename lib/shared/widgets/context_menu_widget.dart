import 'package:flutter/material.dart';

class ContextMenuWidget extends StatelessWidget {
  final List<ContextMenuItem> items;
  final VoidCallback? onDismiss;

  const ContextMenuWidget({super.key, required this.items, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Color(0x10FFFFFF), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map((item) {
              if (item.isDivider) {
                return Container(
                  height: 1.0,
                  margin: EdgeInsets.symmetric(vertical: 4.0),
                  color: Color(0xFF404040),
                );
              }

              return _ContextMenuButton(
                item: item,
                onTap: () {
                  onDismiss?.call();
                  item.onTap?.call();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: ContextMenuWidget(
              items: items,
              onDismiss: () => entry.remove(),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }
}

class _ContextMenuButton extends StatefulWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;

  const _ContextMenuButton({required this.item, required this.onTap});

  @override
  State<StatefulWidget> createState() => _ContextMenuButtonState();
}

class _ContextMenuButtonState extends State<_ContextMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.enabled ? widget.onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _isHovered && widget.item.enabled
                ? Color(0x05FFFFFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 15.0,
                  color: widget.item.enabled ? Colors.white70 : Colors.white30,
                ),
                SizedBox(width: 12.0),
              ],
              Expanded(
                child: Text(
                  widget.item.title,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: widget.item.enabled ? Colors.white : Colors.white54,
                    fontFamily: 'IBM Plex Sans',
                  ),
                ),
              ),
              if (widget.item.shortcut != null) ...[
                SizedBox(width: 24.0),
                Text(
                  widget.item.shortcut!,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: widget.item.enabled
                        ? Colors.white54
                        : Colors.white30,
                    fontFamily: 'IBM Plex Sans',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ContextMenuItem {
  final String title;
  final IconData? icon;
  final String? shortcut;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDivider;

  const ContextMenuItem({
    required this.title,
    this.icon,
    this.shortcut,
    this.onTap,
    this.enabled = true,
    this.isDivider = false,
  });

  static const ContextMenuItem divider = ContextMenuItem(
    title: '',
    isDivider: true,
  );
}
