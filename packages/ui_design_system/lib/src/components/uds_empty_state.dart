import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';
import 'uds_button.dart';

/// Empty / error placeholder filling remaining viewport.
class UdsEmptyState extends StatelessWidget {
  const UdsEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  factory UdsEmptyState.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) {
    return UdsEmptyState(
      key: key,
      message: message,
      icon: Icons.error_outline_rounded,
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UdsSpacing.xxl,
          vertical: compact ? UdsSpacing.xl : UdsSpacing.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 40 : 56, color: UdsColors.textTertiary),
            SizedBox(height: compact ? UdsSpacing.md : UdsSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: UdsTypography.bodyMedium.copyWith(
                color: UdsColors.textTertiary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: UdsSpacing.xl),
              UdsButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                variant: UdsButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
