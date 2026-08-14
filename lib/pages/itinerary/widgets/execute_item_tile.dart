import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../../models/itinerary_item.dart';

/// 执行视图单个行程项
class ExecuteItemTile extends StatelessWidget {
  final ItineraryItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const ExecuteItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ItemStatus.completed;
    final isSkipped = item.status == ItemStatus.skipped;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UdsRadii.card),
        child: Container(
          margin: const EdgeInsets.only(bottom: UdsSpacing.md),
          padding: const EdgeInsets.all(UdsSpacing.md),
          decoration: BoxDecoration(
            color: isDone
                ? UdsColors.successSoft
                : isSkipped
                    ? UdsColors.surfaceVariant
                    : UdsColors.surface,
            borderRadius: BorderRadius.circular(UdsRadii.card),
            border: Border.all(
              color: isDone ? const Color(0xFFC8E6C9) : UdsColors.borderSoft,
            ),
          ),
          child: Opacity(
            opacity: isSkipped ? 0.5 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    item.time,
                    style: UdsTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDone
                          ? UdsColors.success
                          : UdsColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: UdsSpacing.md),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFC8E6C9)
                        : UdsColors.background,
                    borderRadius: BorderRadius.circular(UdsRadii.sm),
                  ),
                  child: Center(
                    child: Text(item.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: UdsTypography.titleMedium.copyWith(
                                fontSize: 14,
                                color: isSkipped
                                    ? UdsColors.textTertiary
                                    : UdsColors.textPrimary,
                                decoration: isSkipped
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.cost > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? UdsColors.success
                                        .withValues(alpha: 0.12)
                                    : UdsColors.background,
                                borderRadius:
                                    BorderRadius.circular(UdsRadii.xs),
                              ),
                              child: Text(
                                '¥${item.cost.toStringAsFixed(0)}',
                                style: UdsTypography.labelSmall.copyWith(
                                  fontSize: 12,
                                  color: isDone
                                      ? UdsColors.success
                                      : UdsColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (item.rating > 0) ...[
                        const SizedBox(height: 2),
                        UdsStarRating(
                          rating: item.rating.toDouble(),
                          size: 16,
                        ),
                      ],
                      if (item.quickTags.isNotEmpty) ...[
                        const SizedBox(height: UdsSpacing.xs),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: item.quickTags
                              .map(
                                (t) => UdsChip(
                                  label: t,
                                  selected: true,
                                  variant: UdsChipVariant.tag,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: UdsSpacing.xs),
                        Text(
                          item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UdsTypography.labelSmall.copyWith(
                            fontSize: 12,
                            color: UdsColors.textSecondary,
                          ),
                        ),
                      ],
                      if (item.feeling != null &&
                          item.feeling!.isNotEmpty) ...[
                        const SizedBox(height: UdsSpacing.xs),
                        Text(
                          item.feeling!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UdsTypography.labelSmall.copyWith(
                            fontSize: 12,
                            color: UdsColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleStatus,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: UdsSpacing.minTap,
                      height: UdsSpacing.minTap,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? UdsColors.success
                                : isSkipped
                                    ? UdsColors.textTertiary
                                    : UdsColors.surface,
                            border: Border.all(
                              color: isDone
                                  ? UdsColors.success
                                  : isSkipped
                                      ? UdsColors.textTertiary
                                      : UdsColors.border,
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : isSkipped
                                  ? const Icon(Icons.remove,
                                      size: 14, color: Colors.white)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
