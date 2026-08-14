import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

enum UdsButtonVariant { filled, tonal, outlined, text, danger }

/// Unified button with press feedback and 44pt min height.
class UdsButton extends StatelessWidget {
  const UdsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = UdsButtonVariant.filled,
    this.expand = true,
    this.loading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final UdsButtonVariant variant;
  final bool expand;
  final bool loading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: UdsSpacing.sm),
              ],
              Text(label, style: UdsTypography.labelLarge.copyWith(
                color: _fg(variant, color),
              )),
            ],
          );

    final button = switch (variant) {
      UdsButtonVariant.filled || UdsButtonVariant.danger => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ??
                (variant == UdsButtonVariant.danger
                    ? UdsColors.danger
                    : UdsColors.primary),
            foregroundColor: UdsColors.textOnPrimary,
            disabledBackgroundColor: UdsColors.border,
            elevation: 0,
            minimumSize: const Size(64, UdsSpacing.minTap),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UdsRadii.button),
            ),
          ),
          child: child,
        ),
      UdsButtonVariant.tonal => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? UdsColors.primarySoft,
            foregroundColor: UdsColors.primary,
            elevation: 0,
            minimumSize: const Size(64, UdsSpacing.minTap),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UdsRadii.button),
            ),
          ),
          child: child,
        ),
      UdsButtonVariant.outlined => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? UdsColors.textSecondary,
            side: BorderSide(color: color ?? UdsColors.border),
            minimumSize: const Size(64, UdsSpacing.minTap),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UdsRadii.button),
            ),
          ),
          child: child,
        ),
      UdsButtonVariant.text => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: color ?? UdsColors.primary,
            minimumSize: const Size(64, UdsSpacing.minTap),
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Color _fg(UdsButtonVariant v, Color? override) {
    if (override != null &&
        (v == UdsButtonVariant.outlined || v == UdsButtonVariant.text || v == UdsButtonVariant.tonal)) {
      return override;
    }
    return switch (v) {
      UdsButtonVariant.filled || UdsButtonVariant.danger => UdsColors.textOnPrimary,
      UdsButtonVariant.tonal => UdsColors.primary,
      UdsButtonVariant.outlined => UdsColors.textSecondary,
      UdsButtonVariant.text => UdsColors.primary,
    };
  }
}
