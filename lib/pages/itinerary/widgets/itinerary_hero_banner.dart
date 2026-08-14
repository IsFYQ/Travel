import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/itinerary.dart';
import '../../../models/travel_record.dart' show kTripTypes;
import 'itinerary_ui_helpers.dart';

/// P1-3.8：攻略详情 Hero 横幅（只读）
class ItineraryHeroBanner extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryHeroBanner({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final dateRange =
        ItineraryUiHelpers.formatDateRange(itinerary.startDate, itinerary.endDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ItineraryUiHelpers.emojiForDestination(itinerary.destination),
              style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 6),
          Text(
            itinerary.destination,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _HeroChip(text: '📅 $dateRange'),
              _HeroChip(text: '👥 ${itinerary.people} 人'),
              if (itinerary.totalBudget > 0)
                _HeroChip(
                    text: '💰 预算 ¥${itinerary.totalBudget.toStringAsFixed(0)}'),
              if (itinerary.tripType.isNotEmpty)
                _HeroChip(
                  text:
                      '${ItineraryUiHelpers.emojiForTripType(itinerary.tripType)} ${itinerary.tripType}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// P1-3.8：编辑模式 Hero 横幅
class ItineraryEditableHeroBanner extends StatelessWidget {
  final TextEditingController destController;
  final TextEditingController budgetController;
  final DateTime? startDate;
  final DateTime? endDate;
  final int people;
  final ItineraryStatus status;
  final String tripType;
  final VoidCallback onPickDateRange;
  final ValueChanged<int> onPeopleChanged;
  final ValueChanged<ItineraryStatus> onStatusChanged;
  final ValueChanged<String> onTripTypeChanged;

  const ItineraryEditableHeroBanner({
    super.key,
    required this.destController,
    required this.budgetController,
    required this.startDate,
    required this.endDate,
    required this.people,
    required this.status,
    required this.tripType,
    required this.onPickDateRange,
    required this.onPeopleChanged,
    required this.onStatusChanged,
    required this.onTripTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateRange = ItineraryUiHelpers.formatDateRange(startDate, endDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ItineraryUiHelpers.emojiForDestination(destController.text),
                  style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: destController,
                  decoration: const InputDecoration(
                    labelText: '目的地',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onPickDateRange,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.inputBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    dateRange == '待定' ? '点击选择日期' : dateRange,
                    style: TextStyle(
                      fontSize: 14,
                      color: dateRange == '待定'
                          ? AppTheme.textTertiary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EditField(
                  label: '人数',
                  child: Row(
                    children: [
                      _CountBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (people > 1) onPeopleChanged(people - 1);
                          }),
                      const SizedBox(width: 8),
                      Text('$people 人',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(width: 8),
                      _CountBtn(
                          icon: Icons.add,
                          onTap: () => onPeopleChanged(people + 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: budgetController,
                  decoration: const InputDecoration(
                    labelText: '总预算（元）',
                    prefixText: '¥ ',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.inputBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ItineraryStatus>(
                value: status,
                isExpanded: true,
                icon: const Icon(Icons.expand_more,
                    size: 20, color: AppTheme.textSecondary),
                items: ItineraryStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label,
                              style: const TextStyle(
                                  fontSize: 14, color: AppTheme.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onStatusChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kTripTypes.map((type) {
              final isSelected = tripType == type;
              return GestureDetector(
                onTap: () => onTripTypeChanged(isSelected ? '' : type),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    '${ItineraryUiHelpers.emojiForTripType(type)} $type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final Widget child;
  const _EditField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CountBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textSecondary),
      ),
    );
  }
}
