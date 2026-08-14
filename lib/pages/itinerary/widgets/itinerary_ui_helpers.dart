import '../../../utils/date_format_util.dart';

/// P1-3.8：攻略详情页 UI 辅助函数
class ItineraryUiHelpers {
  ItineraryUiHelpers._();

  static String emojiForDestination(String destination) {
    if (destination.contains('重庆')) return '🏯';
    if (destination.contains('厦门')) return '🌊';
    if (destination.contains('川西')) return '🗻';
    if (destination.contains('桂林')) return '🏞️';
    if (destination.contains('北京')) return '🏛️';
    if (destination.contains('三亚')) return '🏖️';
    if (destination.contains('西安')) return '🏺';
    return '🗺️';
  }

  static String emojiForTripType(String type) {
    switch (type) {
      case '自然风景':
        return '🏞️';
      case '海岛度假':
        return '🏖️';
      case '人文古迹':
        return '🏛️';
      case '美食之旅':
        return '🌶️';
      case '城市漫步':
        return '🏙️';
      case '自驾游':
        return '🚗';
      default:
        return '🧳';
    }
  }

  static String formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '待定';
    final fmt = DateFormatUtil.monthDayShort();
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}
