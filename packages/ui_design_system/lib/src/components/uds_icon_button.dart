import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_spacing.dart';

/// Icon button with 44pt hit target and ink feedback.
class UdsIconButton extends StatelessWidget {
  const UdsIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 22,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: backgroundColor ?? Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: UdsSpacing.minTap,
          height: UdsSpacing.minTap,
          child: Icon(icon, size: size, color: color ?? UdsColors.textPrimary),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}
