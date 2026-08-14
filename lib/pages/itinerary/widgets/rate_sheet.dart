import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/accommodation_info.dart';
import '../../../models/itinerary_item.dart';
import '../../../widgets/disposable_sheet.dart';
import '../../../widgets/labeled_text_field.dart';
import '../../../widgets/sheet_action_bar.dart';
import '../../../widgets/star_rating.dart';

/// P1-3.8：快评弹窗保存结果
class RateSheetResult {
  final double rating;
  final String feeling;
  final double actualCost;
  final ItemStatus? status;
  final List<String> quickTags;

  const RateSheetResult({
    required this.rating,
    required this.feeling,
    required this.actualCost,
    this.status,
    this.quickTags = const [],
  });
}

/// P1-3.8：行程项快评
Future<void> showItemRateSheet({
  required BuildContext context,
  required ItineraryItem item,
  required int dayNumber,
  required Future<void> Function(RateSheetResult result) onSave,
}) {
  return _showRateSheet(
    context: context,
    title: '轻量快评 · 3 秒搞定',
    saveColor: AppTheme.accentMint,
    estimatedCost: item.cost,
    initialRating: item.rating,
    initialFeeling: item.feeling ?? '',
    initialActualCost: item.actualCost,
    initialStatus: item.status,
    initialQuickTags: item.quickTags,
    showQuickTags: true,
    showStatus: true,
    infoHeader: _ItemRateHeader(item: item, dayNumber: dayNumber),
    onSave: onSave,
  );
}

/// P1-3.8：住宿快评
Future<void> showAccommodationRateSheet({
  required BuildContext context,
  required AccommodationInfo accommodation,
  required Future<void> Function(RateSheetResult result) onSave,
}) {
  final initialActualCost =
      accommodation.actualCost > 0 ? accommodation.actualCost : accommodation.cost;
  return _showRateSheet(
    context: context,
    title: '住宿快评',
    saveColor: const Color(0xFFFB923C),
    estimatedCost: accommodation.cost,
    initialRating: accommodation.rating,
    initialFeeling: accommodation.feeling ?? '',
    initialActualCost: initialActualCost,
    showQuickTags: false,
    showStatus: false,
    infoHeader: _AccommodationRateHeader(accommodation: accommodation),
    onSave: onSave,
  );
}

Future<void> _showRateSheet({
  required BuildContext context,
  required String title,
  required Color saveColor,
  required double estimatedCost,
  required double initialRating,
  required String initialFeeling,
  required double initialActualCost,
  required bool showQuickTags,
  required bool showStatus,
  required Widget infoHeader,
  required Future<void> Function(RateSheetResult result) onSave,
  ItemStatus? initialStatus,
  List<String> initialQuickTags = const [],
}) {
  double tempRating = initialRating;
  String tempFeeling = initialFeeling;
  double tempActualCost = initialActualCost;
  ItemStatus tempStatus = initialStatus ?? ItemStatus.pending;
  final feelingController = TextEditingController(text: tempFeeling);
  final costController = TextEditingController(
    text: tempActualCost > 0 ? tempActualCost.toStringAsFixed(0) : '',
  );
  final selectedTags = <String>{...initialQuickTags};

  return showManagedModalBottomSheet(
    context: context,
    controllers: [feelingController, costController],
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  24 + MediaQuery.of(ctx).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      infoHeader,
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('⭐ 快速评分',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                          const Spacer(),
                          if (tempRating > 0)
                            Text(
                              '${tempRating.toInt()} 星',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFFB300)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      StarRating(
                        rating: tempRating,
                        size: 34,
                        onChanged: (v) =>
                            setSheetState(() => tempRating = v),
                      ),
                      if (showQuickTags) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: QuickRateTags.all.map((tag) {
                            final isOn = selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (isOn) {
                                    selectedTags.remove(tag);
                                  } else {
                                    selectedTags.add(tag);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? const Color(0xFFE3F2FD)
                                      : AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isOn
                                        ? const Color(0xFFBBDEFB)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(tag,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isOn
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('💰 实际花费',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                          if (showQuickTags) ...[
                            const SizedBox(width: 4),
                            const Text('可选',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textTertiary)),
                          ],
                          const Spacer(),
                          Text('预估 ¥${estimatedCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          prefixText: '¥ ',
                          prefixStyle: const TextStyle(
                              fontSize: 15, color: AppTheme.textPrimary),
                          hintText: '填写实际花费',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: '📝 一句话备注',
                        optionalHint: '可选',
                        controller: feelingController,
                        hintText: showQuickTags
                            ? '比如：景区大巴很方便，电梯省时..'
                            : '比如：房间很干净，早餐不错..',
                        maxLength: 50,
                        minLines: showQuickTags ? 2 : 1,
                        maxLines: showQuickTags ? 3 : 2,
                      ),
                      if (showStatus) ...[
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Text('🔄 状态',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatusOption(
                              emoji: '✅',
                              label: '已完成',
                              value: ItemStatus.completed,
                              current: tempStatus,
                              onChanged: (v) =>
                                  setSheetState(() => tempStatus = v),
                            ),
                            const SizedBox(width: 8),
                            _StatusOption(
                              emoji: '⏭️',
                              label: '跳过',
                              value: ItemStatus.skipped,
                              current: tempStatus,
                              onChanged: (v) =>
                                  setSheetState(() => tempStatus = v),
                            ),
                            const SizedBox(width: 8),
                            _StatusOption(
                              emoji: '⏸',
                              label: '稍后',
                              value: ItemStatus.pending,
                              current: tempStatus,
                              onChanged: (v) =>
                                  setSheetState(() => tempStatus = v),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      SheetActionBar(
                        confirmColor: saveColor,
                        onCancel: () => Navigator.pop(ctx),
                        onConfirm: () async {
                          final costText = costController.text.trim();
                          final actualCost = costText.isNotEmpty
                              ? (double.tryParse(costText) ?? 0)
                              : 0.0;
                          await onSave(RateSheetResult(
                            rating: tempRating,
                            feeling: feelingController.text,
                            actualCost: actualCost,
                            status: showStatus ? tempStatus : null,
                            quickTags: selectedTags.toList(),
                          ));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _ItemRateHeader extends StatelessWidget {
  final ItineraryItem item;
  final int dayNumber;

  const _ItemRateHeader({required this.item, required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                if (item.note != null && item.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.note!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textTertiary)),
                  ),
                Text(
                  '${item.time} · ¥${item.cost.toStringAsFixed(0)} · Day $dayNumber',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccommodationRateHeader extends StatelessWidget {
  final AccommodationInfo accommodation;

  const _AccommodationRateHeader({required this.accommodation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFB923C),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
                child: Text('🛖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name.isNotEmpty
                      ? accommodation.name
                      : '住宿',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                if (accommodation.type.isNotEmpty ||
                    accommodation.area.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (accommodation.type.isNotEmpty) accommodation.type,
                        if (accommodation.area.isNotEmpty) accommodation.area,
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ),
                if (accommodation.cost > 0)
                  Text('预估 ¥${accommodation.cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String emoji;
  final String label;
  final ItemStatus value;
  final ItemStatus current;
  final ValueChanged<ItemStatus> onChanged;

  const _StatusOption({
    required this.emoji,
    required this.label,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
