import 'package:intl/intl.dart';

/// P0-21: 集中管理中文日期格式
class DateFormatUtil {
  static const locale = 'zh_CN';

  static DateFormat monthDayWeekday({String? locale}) =>
      DateFormat('M月d日 EEE', locale ?? DateFormatUtil.locale);

  static DateFormat monthDayDotWeekday({String? locale}) =>
      DateFormat('M月d日 · EEE', locale ?? DateFormatUtil.locale);

  static DateFormat monthDayDot({String? locale}) =>
      DateFormat('M.d EEE', locale ?? DateFormatUtil.locale);

  static DateFormat monthDay({String? locale}) =>
      DateFormat('M月d日', locale ?? DateFormatUtil.locale);

  static DateFormat monthDayShort({String? locale}) =>
      DateFormat('M.d', locale ?? DateFormatUtil.locale);

  static DateFormat yearMonth({String? locale}) =>
      DateFormat('yyyy年M月', locale ?? DateFormatUtil.locale);

  static DateFormat yearMonthDay({String? locale}) =>
      DateFormat('yyyy/M/d', locale ?? DateFormatUtil.locale);
}
