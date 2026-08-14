import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

enum UdsChipVariant { filter, choice, tag }

/// Unified chip / filter / tag with ink feedback.
class UdsChip extends StatelessWidget {
  const UdsChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.variant = UdsChipVariant.filter,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final UdsChipVariant variant;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (variant == UdsChipVariant.filter
            ? UdsColors.primary
            : UdsColors.primarySoft)
        : UdsColors.surfaceVariant;
    final fg = selected
        ? (variant == UdsChipVariant.filter
            ? UdsColors.textOnPrimary
            : UdsColors.primary)
        : UdsColors.textSecondary;
    final border = selected && variant != UdsChipVariant.filter
        ? UdsColors.primarySoftBorder
        : Colors.transparent;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(UdsRadii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UdsRadii.chip),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(
            horizontal: UdsSpacing.md,
            vertical: UdsSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UdsRadii.chip),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: UdsSpacing.xs),
              ],
              Text(
                label,
                style: UdsTypography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
