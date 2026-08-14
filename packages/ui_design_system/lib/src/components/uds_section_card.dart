import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

/// Settings / profile section with title + white card body.
class UdsSectionCard extends StatelessWidget {
  const UdsSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.margin,
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ??
          const EdgeInsets.symmetric(horizontal: UdsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: UdsSpacing.xs,
              bottom: UdsSpacing.sm,
            ),
            child: Text(
              title,
              style: UdsTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: UdsColors.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: UdsColors.surface,
              borderRadius: BorderRadius.circular(UdsRadii.card),
              border: Border.all(color: UdsColors.border, width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
