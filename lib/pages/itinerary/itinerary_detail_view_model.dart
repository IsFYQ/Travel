import '../../models/itinerary.dart';
import '../../models/itinerary_item.dart';
import '../../models/accommodation_info.dart';
import '../../utils/date_format_util.dart';

/// P1-2.5 / P1-3.8：攻略转日记流水账生成
class ItineraryDetailViewModel {
  /// 生成传给 AI 的结构化行程流水账
  static String buildItineraryDigest(Itinerary it) {
    final buffer = StringBuffer();
    final fmt = DateFormatUtil.monthDay();
    final skippedItems = <String>[];

    for (int i = 0; i < it.dayPlans.length; i++) {
      final day = it.dayPlans[i];
      final dateStr = day.date != null ? '（${fmt.format(day.date!)}）' : '';
      buffer.writeln('Day ${i + 1}$dateStr');

      double dayEst = 0;
      double dayActual = 0;

      for (final item in sortItineraryItems(day.items)) {
        if (item.status == ItemStatus.skipped) {
          skippedItems.add(_formatItem(item, skipped: true));
          continue;
        }
        dayEst += item.cost;
        if (item.status == ItemStatus.completed) {
          dayActual += item.actualCost > 0 ? item.actualCost : 0;
        }
        buffer.writeln(_formatItem(item));
      }

      if (day.accommodation != null) {
        buffer.writeln(_formatAccommodation(day.accommodation!));
        if (day.accommodation!.cost > 0) dayEst += day.accommodation!.cost;
        if (day.accommodation!.actualCost > 0) {
          dayActual += day.accommodation!.actualCost;
        }
      }

      buffer.writeln(
          '  [当日汇总] 预估 ¥${dayEst.toStringAsFixed(0)} / 实际 ¥${dayActual.toStringAsFixed(0)}');
      if (i < it.dayPlans.length - 1) buffer.writeln();
    }

    if (skippedItems.isNotEmpty) {
      buffer.writeln('\n【未成行】');
      for (final s in skippedItems) {
        buffer.writeln(s);
      }
    }

    return buffer.toString();
  }

  static String _formatItem(ItineraryItem item, {bool skipped = false}) {
    final timePart = item.time.isNotEmpty ? '${item.time} ' : '';
    final statusTag = skipped ? '（已跳过）' : item.status.label;
    final estPart = item.cost > 0 ? '预估¥${item.cost.toStringAsFixed(0)}' : '';
    final actPart =
        item.actualCost > 0 ? '实际¥${item.actualCost.toStringAsFixed(0)}' : '';
    final costPart =
        [if (estPart.isNotEmpty) estPart, if (actPart.isNotEmpty) actPart].join('，');
    final costStr = costPart.isNotEmpty ? ' [$costPart]' : '';
    final ratingPart = item.rating > 0 ? ' ${item.rating.toInt()}星' : '';
    final feelingPart =
        (item.feeling != null && item.feeling!.isNotEmpty) ? ' 感受: ${item.feeling}' : '';
    final tagsPart =
        item.quickTags.isNotEmpty ? ' 标签: ${item.quickTags.join('、')}' : '';
    return '  · $timePart${item.emoji}${item.title} [$statusTag]$costStr$ratingPart$feelingPart$tagsPart';
  }

  static String _formatAccommodation(AccommodationInfo acc) {
    final parts = <String>['  🏨 住宿: ${acc.displayText}'];
    if (acc.actualCost > 0) parts.add('实际¥${acc.actualCost.toStringAsFixed(0)}');
    if (acc.rating > 0) parts.add('${acc.rating.toInt()}星');
    if (acc.feeling != null && acc.feeling!.isNotEmpty) {
      parts.add('感受: ${acc.feeling}');
    }
    return parts.join(' | ');
  }

  /// 计算转日记用的总实际花费与加权评分
  static ({double totalActualCost, double avgRating}) computeDiaryMeta(Itinerary it) {
    double totalActualCost = 0;
    double ratingSum = 0;
    int ratingCount = 0;

    for (final day in it.dayPlans) {
      if (day.accommodation != null && day.accommodation!.actualCost > 0) {
        totalActualCost += day.accommodation!.actualCost;
      }
      if (day.accommodation != null && day.accommodation!.rating > 0) {
        ratingSum += day.accommodation!.rating;
        ratingCount++;
      }
      for (final item in day.items) {
        if (item.status == ItemStatus.completed) {
          totalActualCost += item.actualCost > 0 ? item.actualCost : 0;
        }
        if (item.rating > 0) {
          ratingSum += item.rating;
          ratingCount++;
        }
      }
    }

    return (
      totalActualCost: totalActualCost,
      avgRating: ratingCount > 0 ? (ratingSum / ratingCount).roundToDouble() : 0.0,
    );
  }
}
