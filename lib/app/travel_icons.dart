import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 旅行搭子自定义图标工具类
/// 所有图标均为 SVG 矢量格式，通过 flutter_svg 渲染
class TravelIcons {
  TravelIcons._();

  static const String _basePath = 'assets/icons';

  /// 通用 SVG 图标加载器
  static Widget svg(
    String filename, {
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.asset(
      '$_basePath/$filename',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  // ========== 底部导航栏 ==========
  static Widget timelineSelected({double size = 24}) =>
      svg('timeline_selected.svg', size: size);
  static Widget timelineUnselected({double size = 24}) =>
      svg('timeline_unselected.svg', size: size);
  static Widget mapSelected({double size = 24}) =>
      svg('map_selected.svg', size: size);
  static Widget mapUnselected({double size = 24}) =>
      svg('map_unselected.svg', size: size);
  static Widget chatSelected({double size = 24}) =>
      svg('chat_selected.svg', size: size);
  static Widget chatUnselected({double size = 24}) =>
      svg('chat_unselected.svg', size: size);
  static Widget personSelected({double size = 24}) =>
      svg('person_selected.svg', size: size);
  static Widget personUnselected({double size = 24}) =>
      svg('person_unselected.svg', size: size);

  // ========== 空状态引导 ==========
  static Widget emptyTravel({double size = 80}) =>
      svg('empty_travel.svg', size: size);
  static Widget emptyChat({double size = 80}) =>
      svg('empty_chat.svg', size: size);
  static Widget emptyGuide({double size = 80}) =>
      svg('empty_guide.svg', size: size);

  // ========== 首页功能 ==========
  static Widget addDiary({double size = 24, Color? color}) =>
      svg('f01_add_diary.svg', size: size, color: color);
  static Widget cityCount({double size = 24, Color? color}) =>
      svg('f02_city_count.svg', size: size, color: color);
  static Widget tripCount({double size = 24, Color? color}) =>
      svg('f03_trip_count.svg', size: size, color: color);
  static Widget travelDays({double size = 24, Color? color}) =>
      svg('f04_travel_days.svg', size: size, color: color);
  static Widget totalCost({double size = 24, Color? color}) =>
      svg('f05_total_cost.svg', size: size, color: color);
  static Widget search({double size = 24, Color? color}) =>
      svg('f06_search.svg', size: size, color: color);

  // ========== AI 对话 ==========
  static Widget aiAvatar({double size = 24}) =>
      svg('f07_ai_avatar.svg', size: size);
  static Widget send({double size = 24, Color? color}) =>
      svg('f08_send.svg', size: size, color: color);
  static Widget newChat({double size = 24, Color? color}) =>
      svg('f09_new_chat.svg', size: size, color: color);

  // ========== 攻略详情 ==========
  static Widget executionView({double size = 24, Color? color}) =>
      svg('f10_execution_view.svg', size: size, color: color);
  static Widget editMode({double size = 24, Color? color}) =>
      svg('f11_edit_mode.svg', size: size, color: color);
  static Widget guideToDiary({double size = 24, Color? color}) =>
      svg('f12_guide_to_diary.svg', size: size, color: color);
  static Widget tripDone({double size = 24, Color? color}) =>
      svg('f13_trip_done.svg', size: size, color: color);
  static Widget tripPending({double size = 24, Color? color}) =>
      svg('f14_trip_pending.svg', size: size, color: color);
  static Widget skipItem({double size = 24, Color? color}) =>
      svg('f15_skip_item.svg', size: size, color: color);

  // ========== 日记编辑器 ==========
  static Widget camera({double size = 24, Color? color}) =>
      svg('f16_camera.svg', size: size, color: color);
  static Widget imagePicker({double size = 24, Color? color}) =>
      svg('f17_image_picker.svg', size: size, color: color);

  // ========== 通用交互 ==========
  static Widget clearSearch({double size = 24, Color? color}) =>
      svg('a01_clear_search.svg', size: size, color: color);
  static Widget imagePlaceholder({double size = 24, Color? color}) =>
      svg('a02_image_placeholder.svg', size: size, color: color);
  static Widget suggestion({double size = 24, Color? color}) =>
      svg('a03_suggestion.svg', size: size, color: color);
  static Widget starFilled({double size = 24, Color? color}) =>
      svg('a04_star_filled.svg', size: size, color: color);
  static Widget starEmpty({double size = 24, Color? color}) =>
      svg('a05_star_empty.svg', size: size, color: color);
  static Widget addNote({double size = 24, Color? color}) =>
      svg('a06_add_note.svg', size: size, color: color);
  static Widget datePicker({double size = 24, Color? color}) =>
      svg('a07_date_picker.svg', size: size, color: color);
  static Widget decreasePeople({double size = 24, Color? color}) =>
      svg('a08_decrease_people.svg', size: size, color: color);
  static Widget increasePeople({double size = 24, Color? color}) =>
      svg('a09_increase_people.svg', size: size, color: color);
  static Widget expand({double size = 24, Color? color}) =>
      svg('a10_expand.svg', size: size, color: color);
  static Widget collapse({double size = 24, Color? color}) =>
      svg('a11_collapse.svg', size: size, color: color);
  static Widget deleteImage({double size = 24, Color? color}) =>
      svg('a12_delete_image.svg', size: size, color: color);
  static Widget setCover({double size = 24, Color? color}) =>
      svg('a13_set_cover.svg', size: size, color: color);
  static Widget arrowRight({double size = 24, Color? color}) =>
      svg('a23_arrow_right.svg', size: size, color: color);

  // ========== 设置与系统 ==========
  static Widget apiKey({double size = 24, Color? color}) =>
      svg('a14_api_key.svg', size: size, color: color);
  static Widget eyeToggle({double size = 24, Color? color, bool visible = true}) =>
      svg('a15_eye_toggle.svg', size: size, color: color);
  static Widget save({double size = 24, Color? color}) =>
      svg('a16_save.svg', size: size, color: color);
  static Widget testConnection({double size = 24, Color? color}) =>
      svg('a17_test_connection.svg', size: size, color: color);
  static Widget connectionOk({double size = 24, Color? color}) =>
      svg('a18_connection_ok.svg', size: size, color: color);
  static Widget knowledgeBase({double size = 24, Color? color}) =>
      svg('a19_knowledge_base.svg', size: size, color: color);
  static Widget backup({double size = 24, Color? color}) =>
      svg('a20_backup.svg', size: size, color: color);
  static Widget imaSync({double size = 24, Color? color}) =>
      svg('a21_ima_sync.svg', size: size, color: color);
  static Widget about({double size = 24, Color? color}) =>
      svg('a22_about.svg', size: size, color: color);
  static Widget folder({double size = 24, Color? color}) =>
      svg('a25_folder.svg', size: size, color: color);
  static Widget cloudDownload({double size = 24, Color? color}) =>
      svg('a26_cloud_download.svg', size: size, color: color);

  // ========== 攻略元数据 ==========
  static Widget guideDate({double size = 24, Color? color}) =>
      svg('a27_guide_date.svg', size: size, color: color);
  static Widget guidePeople({double size = 24, Color? color}) =>
      svg('a28_guide_people.svg', size: size, color: color);
  static Widget guideBudget({double size = 24, Color? color}) =>
      svg('a29_guide_budget.svg', size: size, color: color);
}
