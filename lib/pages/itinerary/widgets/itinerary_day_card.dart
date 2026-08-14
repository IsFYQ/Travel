import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/accommodation_info.dart';
import '../../../models/itinerary.dart';
import '../../../utils/date_format_util.dart';

/// P1-3.8：攻略详情日卡片
class ItineraryDayCard extends StatelessWidget {
  final DayPlan dayPlan;
  final int dayIndex;
  final String dayTitle;
  final bool isOngoingDay;
  final bool isEditing;
  final bool hideActions;
  final Widget timeline;
  final double dayBudget;
  final VoidCallback? onAddItem;
  final void Function(AccommodationInfo acc)? onEditAccommodation;
  final VoidCallback? onAddAccommodation;

  const ItineraryDayCard({
    super.key,
    required this.dayPlan,
    required this.dayIndex,
    required this.dayTitle,
    required this.isOngoingDay,
    required this.isEditing,
    required this.timeline,
    required this.dayBudget,
    this.hideActions = false,
    this.onAddItem,
    this.onEditAccommodation,
    this.onAddAccommodation,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = dayPlan.date != null
        ? DateFormatUtil.monthDayDotWeekday().format(dayPlan.date!)
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'D${dayPlan.dayNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayTitle,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textTertiary)),
                    ],
                  ),
                ),
                if (isOngoingDay)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('进行中',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentMint)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          timeline,
          if (!hideActions && onAddItem != null) ...[
            const SizedBox(height: 0),
            _AddItemButton(onTap: onAddItem!),
          ],
          if (dayPlan.accommodation != null) ...[
            const SizedBox(height: 8),
            _AccommodationTile(
              accommodation: dayPlan.accommodation!,
              isEditing: isEditing,
              onTap: onEditAccommodation == null
                  ? null
                  : () => onEditAccommodation!(dayPlan.accommodation!),
            ),
          ] else if (isEditing && !hideActions && onAddAccommodation != null) ...[
            const SizedBox(height: 8),
            _AddAccommodationButton(onTap: onAddAccommodation!),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('共${dayPlan.items.length} 项行程',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text.rich(
                  TextSpan(
                    text: '当日预算 ',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    children: [
                      TextSpan(
                        text: '¥${dayBudget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentCoral,
                        ),
                      ),
                    ],
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

class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddItemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: AppTheme.textTertiary),
            SizedBox(width: 5),
            Text('添加行程项',
                style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _AccommodationTile extends StatelessWidget {
  final AccommodationInfo accommodation;
  final bool isEditing;
  final VoidCallback? onTap;

  const _AccommodationTile({
    required this.accommodation,
    required this.isEditing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditing ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFB923C),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text('🛏️', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '住宿· ${accommodation.displayText}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
            if (isEditing)
              const Icon(Icons.edit, size: 16, color: Color(0xFF9A3412)),
          ],
        ),
      ),
    );
  }
}

class _AddAccommodationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAccommodationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFED7AA)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFFFBF5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFFFB923C)),
            SizedBox(width: 5),
            Text('添加住宿',
                style: TextStyle(fontSize: 13, color: Color(0xFFFB923C))),
          ],
        ),
      ),
    );
  }
}
