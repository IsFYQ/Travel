import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/itinerary_item.dart';

/// P1-3.8：编辑/只读时间线（含拖拽排序）
class ItineraryTimeline extends StatelessWidget {
  final List<ItineraryItem> items;
  final bool isEditing;
  final int dayIndex;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int itemIndex, ItineraryItem item) onEditItem;
  final void Function(String itemId) onDeleteItem;

  const ItineraryTimeline({
    super.key,
    required this.items,
    required this.isEditing,
    required this.dayIndex,
    this.onReorder,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = sortItineraryItems(items);

    if (isEditing && onReorder != null) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: sorted.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final item = sorted[index];
          return ReorderableDragStartListener(
            key: ValueKey(item.id),
            index: index,
            child: _TimelineRow(
              item: item,
              dayIndex: dayIndex,
              itemIndex: index,
              isEditing: true,
              onEditItem: onEditItem,
              onDeleteItem: onDeleteItem,
            ),
          );
        },
      );
    }

    return Column(
      children: sorted.asMap().entries.map((e) {
        return _TimelineRow(
          item: e.value,
          dayIndex: dayIndex,
          itemIndex: e.key,
          isEditing: false,
          onEditItem: onEditItem,
          onDeleteItem: onDeleteItem,
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ItineraryItem item;
  final int dayIndex;
  final int itemIndex;
  final bool isEditing;
  final void Function(int itemIndex, ItineraryItem item) onEditItem;
  final void Function(String itemId) onDeleteItem;

  const _TimelineRow({
    required this.item,
    required this.dayIndex,
    required this.itemIndex,
    required this.isEditing,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing)
            const Padding(
              padding: EdgeInsets.only(right: 4, top: 2),
              child: Icon(Icons.drag_handle, size: 18, color: AppTheme.textTertiary),
            ),
          SizedBox(
            width: 42,
            child: Text(
              item.time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${item.emoji} ', style: const TextStyle(fontSize: 16)),
                    Expanded(
                      child: GestureDetector(
                        onTap: isEditing
                            ? () => onEditItem(itemIndex, item)
                            : null,
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isEditing
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary,
                            decoration:
                                isEditing ? TextDecoration.underline : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (item.cost > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '¥${item.cost.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    if (isEditing) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => onEditItem(itemIndex, item),
                        child: const Icon(Icons.edit_outlined,
                            size: 14, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onDeleteItem(item.id),
                        child: const Icon(Icons.close,
                            size: 16, color: AppTheme.textTertiary),
                      ),
                    ],
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(item.note!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            height: 1.5)),
                  ),
                if (!isEditing && item.quickTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.quickTags
                          .map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
