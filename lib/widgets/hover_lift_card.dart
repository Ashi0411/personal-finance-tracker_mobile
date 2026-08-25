import 'package:flutter/material.dart';

class HoverLiftCard extends StatefulWidget {
  final Widget child;
  final double liftOffset;
  final double borderRadius;
  final Color? glowColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? baseShadow;

  const HoverLiftCard({
    super.key,
    required this.child,
    this.liftOffset = -4.0,
    this.borderRadius = 24.0,
    this.glowColor,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.border,
    this.baseShadow,
  });

  @override
  State<HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<HoverLiftCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = widget.glowColor ?? const Color(0xFF6366F1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        margin: widget.margin,
        transform: Matrix4.translationValues(0, _isHovered ? widget.liftOffset : 0, 0),
        decoration: BoxDecoration(
          color: widget.gradient != null
              ? null
              : (widget.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white)),
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ??
              (widget.gradient != null
                  ? null
                  : Border.all(
                      color: _isHovered
                          ? effectiveGlowColor.withValues(alpha: 0.5)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      width: _isHovered ? 1.4 : 1.0,
                    )),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: effectiveGlowColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : widget.baseShadow ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
