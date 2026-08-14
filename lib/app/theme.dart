import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 应用主题 — 桥接到 ui_design_system，保留静态常量以兼容存量页面引用。
///
/// 新代码请优先使用 `UdsColors` / `context.uds` / UDS 组件。
class AppTheme {
  // ===== 色彩系统（别名 → UDS） =====
  static const Color primaryColor = UdsColors.primary;
  static const Color primaryLight = UdsColors.primaryLight;
  static const Color primaryLighter = UdsColors.primaryLighter;
  static const Color accentCoral = UdsColors.secondary;
  static const Color accentMint = UdsColors.tertiary;
  static const Color backgroundColor = UdsColors.background;
  static const Color cardColor = UdsColors.surface;
  static const Color textPrimary = UdsColors.textPrimary;
  static const Color textSecondary = UdsColors.textSecondary;
  static const Color textTertiary = UdsColors.textTertiary;
  static const Color primaryHover = UdsColors.primaryHover;
  static const Color primarySoft = UdsColors.primarySoft;
  static const Color primarySoftBorder = UdsColors.primarySoftBorder;
  static const Color danger = UdsColors.danger;
  static const Color dangerSoft = UdsColors.dangerSoft;
  static const Color success = UdsColors.success;
  static const Color successSoft = UdsColors.successSoft;
  static const Color warning = UdsColors.warning;
  static const Color warningSoft = UdsColors.warningSoft;
  static const Color dividerColor = UdsColors.divider;
  static const Color inputBgColor = UdsColors.inputBg;
  static const Color borderColor = UdsColors.border;
  static const Color borderSoft = UdsColors.borderSoft;
  static const Color overlayColor = UdsColors.overlay;

  // ===== 标签配色方案 =====
  static const Map<String, List<Color>> tagColors = {
    '自然风景': [Color(0xFFE8F5E9), Color(0xFF4CAF50)],
    '海岛度假': [Color(0xFFE3F2FD), Color(0xFF2196F3)],
    '人文古迹': [Color(0xFFFBE9E7), Color(0xFFE64A19)],
    '美食之旅': [Color(0xFFFFF3E0), Color(0xFFE65100)],
    '城市漫步': [Color(0xFFFCE4EC), Color(0xFFD81B60)],
    '自驾游': [Color(0xFFEDE7F6), Color(0xFF7E57C2)],
    '自然风光': [Color(0xFFE8F5E9), Color(0xFF4CAF50)],
    '历史人文': [Color(0xFFFBE9E7), Color(0xFFE64A19)],
  };

  static List<Color> getTagColors(String tag) {
    return tagColors[tag] ??
        [const Color(0xFFE3F2FD), const Color(0xFF2196F3)];
  }

  static const Map<String, List<Color>> coverGradients = {
    '自然风景': [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    '海岛度假': [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    '人文古迹': [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    '美食之旅': [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    '城市漫步': [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    '自驾游': [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    '自然风光': [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    '历史人文': [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
  };

  static List<Color> getCoverGradient(String tag) {
    return coverGradients[tag] ??
        [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
  }

  static const Map<String, Color> settingsIconBg = {
    'api': Color(0xFFE3F2FD),
    'knowledge': Color(0xFFE8F5E9),
    'backup': Color(0xFFE3F2FD),
    'ima': Color(0xFFFCE4EC),
    'about': Color(0xFFF3F4F6),
    'prompt': Color(0xFFE0F2F1),
  };

  // ===== 圆角（别名 → UDS） =====
  static const double radiusCard = UdsRadii.card;
  static const double radiusChip = UdsRadii.chip;
  static const double radiusInput = UdsRadii.input;
  static const double radiusBtn = UdsRadii.button;
  static const double radiusModal = UdsRadii.modal;
  static const double radiusSmall = UdsRadii.small;
  static const double radiusFab = UdsRadii.fab;

  static ThemeData get lightTheme => UdsTheme.light();
  static ThemeData get darkTheme => UdsTheme.dark();
}
