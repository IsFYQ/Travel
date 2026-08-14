import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

/// Settings list row with icon, title, subtitle, chevron.
class UdsSettingsTile extends StatelessWidget {
  const UdsSettingsTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconBg,
    this.enabled = true,
    this.showChevron = true,
    this.comingSoon = false,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final Color? iconBg;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = (enabled && !comingSoon) ? onTap : () {
      if (comingSoon) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('功能开发中...')),
        );
      }
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UdsSpacing.lg,
            vertical: UdsSpacing.md,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg ?? UdsColors.primarySoft,
                    borderRadius: BorderRadius.circular(UdsRadii.md),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: UdsSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: UdsTypography.titleMedium.copyWith(
                              color: enabled
                                  ? UdsColors.textPrimary
                                  : UdsColors.textTertiary,
                            ),
                          ),
                        ),
                        if (comingSoon) ...[
                          const SizedBox(width: UdsSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: UdsColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(UdsRadii.xs),
                            ),
                            child: Text(
                              '即将推出',
                              style: UdsTypography.labelSmall.copyWith(
                                color: UdsColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UdsTypography.labelSmall.copyWith(
                          color: UdsColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron && !comingSoon)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: UdsColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
