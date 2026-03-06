import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// TV-optimized focusable widget with visual focus indicator
class TVFocusWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onFocusGained;
  final VoidCallback? onFocusLost;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final Color? focusColor;
  final double focusBorderWidth;
  final bool showFocusScale;
  final double scaleOnFocus;
  final bool canRequestFocus;

  const TVFocusWidget({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocusGained,
    this.onFocusLost,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius,
    this.focusColor,
    this.focusBorderWidth = 3.0,
    this.showFocusScale = true,
    this.scaleOnFocus = 1.05,
    this.canRequestFocus = true,
  });

  @override
  State<TVFocusWidget> createState() => _TVFocusWidgetState();
}

class _TVFocusWidgetState extends State<TVFocusWidget>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnFocus,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        _animController.forward();
        widget.onFocusGained?.call();
      } else {
        _animController.reverse();
        widget.onFocusLost?.call();
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? AppTheme.focusedBorder;
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(12.0);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.canRequestFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onSelect?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.showFocusScale ? _scaleAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _isFocused
                        ? focusColor
                        : Colors.transparent,
                    width: widget.focusBorderWidth,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: focusColor
                                .withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV Button with focus states
class TVButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool autofocus;
  final bool isSelected;
  final double? width;
  final FocusNode? focusNode;

  const TVButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.autofocus = false,
    this.isSelected = false,
    this.width,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusWidget(
      autofocus: autofocus,
      focusNode: focusNode,
      onSelect: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.onBackground,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
