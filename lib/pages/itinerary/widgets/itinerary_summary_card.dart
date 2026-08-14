import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/theme.dart';
import '../../../models/itinerary.dart';

/// P1-3.8：行程总览卡片
class ItinerarySummaryCard extends StatelessWidget {
  final Itinerary itinerary;
  final int totalItems;

  const ItinerarySummaryCard({
    super.key,
    required this.itinerary,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 6),
              Text('行程总览',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryCell(number: itinerary.days.toString(), label: '总天数'),
              _SummaryCell(number: totalItems.toString(), label: '行程项'),
              _SummaryCell(
                  number: '¥${itinerary.totalBudget.toStringAsFixed(0)}',
                  label: '总预算'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String number;
  final String label;
  const _SummaryCell({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(number,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// P1-3.8：攻略操作按钮组
class ItineraryActionButtons extends StatelessWidget {
  final ItineraryStatus status;
  final VoidCallback onEnterExecute;
  final VoidCallback onConvertToDiary;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const ItineraryActionButtons({
    super.key,
    required this.status,
    required this.onEnterExecute,
    required this.onConvertToDiary,
    required this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _ActionButton(
            svgAsset: 'assets/icons/f10_execution_view.svg',
            label: '进入执行视图',
            color: AppTheme.accentMint,
            onTap: onEnterExecute,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            svgAsset: 'assets/icons/f12_guide_to_diary.svg',
            label: '一键转日记',
            color: AppTheme.primaryColor,
            onTap: onConvertToDiary,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.share_outlined,
            label: '分享攻略',
            color: AppTheme.primaryColor,
            onTap: onShare,
          ),
          if (status == ItineraryStatus.planning && onDelete != null) ...[
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.delete_outline,
              label: '删除攻略',
              color: Colors.red,
              onTap: onDelete!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(svgAsset!,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn))
            else if (icon != null)
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
