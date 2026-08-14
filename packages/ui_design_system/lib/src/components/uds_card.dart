import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_elevation.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';

enum UdsCardVariant { elevated, filled, outlined }

/// Surface card with consistent radius / padding.
class UdsCard extends StatelessWidget {
  const UdsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.variant = UdsCardVariant.outlined,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final UdsCardVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ??
        switch (variant) {
          UdsCardVariant.filled => UdsColors.surfaceVariant,
          _ => UdsColors.surface,
        };
    final border = variant == UdsCardVariant.outlined
        ? Border.all(color: UdsColors.border, width: 0.8)
        : null;
    final shadows =
        variant == UdsCardVariant.elevated ? UdsElevation.soft : UdsElevation.none;

    final content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(UdsSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(UdsRadii.card),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UdsRadii.card),
        child: content,
      ),
    );
  }
}
