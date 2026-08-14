import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

enum UdsStatusTone { info, success, warning, danger }

/// Inline status / connection / sync banner.
class UdsStatusBanner extends StatelessWidget {
  const UdsStatusBanner({
    super.key,
    required this.message,
    this.tone = UdsStatusTone.info,
    this.trailing,
    this.icon,
  });

  final String message;
  final UdsStatusTone tone;
  final Widget? trailing;
  final IconData? icon;

  Color get _bg => switch (tone) {
        UdsStatusTone.info => UdsColors.primarySoft,
        UdsStatusTone.success => UdsColors.successSoft,
        UdsStatusTone.warning => UdsColors.warningSoft,
        UdsStatusTone.danger => UdsColors.dangerSoft,
      };

  Color get _fg => switch (tone) {
        UdsStatusTone.info => UdsColors.primary,
        UdsStatusTone.success => UdsColors.success,
        UdsStatusTone.warning => UdsColors.warning,
        UdsStatusTone.danger => UdsColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UdsSpacing.md),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(UdsRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ??
                switch (tone) {
                  UdsStatusTone.info => Icons.info_outline_rounded,
                  UdsStatusTone.success => Icons.check_circle_outline_rounded,
                  UdsStatusTone.warning => Icons.warning_amber_rounded,
                  UdsStatusTone.danger => Icons.error_outline_rounded,
                },
            size: 20,
            color: _fg,
          ),
          const SizedBox(width: UdsSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: UdsTypography.bodyMedium.copyWith(color: _fg, height: 1.4),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: UdsSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
