import 'package:flutter/material.dart';

/// 应用主题配置 - 清新旅游风格
class AppTheme {
  // ===== 色彩系统 =====
  static const Color primaryColor = Color(0xFF2196F3); // 海洋蓝
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryLighter = Color(0xFF64B5F6);
  static const Color accentCoral = Color(0xFFFF7043); // 珊瑚橙
  static const Color accentMint = Color(0xFF4CAF50); // 薄荷绿
  static const Color backgroundColor = Color(0xFFF8FAFC); // 浅蓝灰
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF111827); // 深色主文字
  static const Color textSecondary = Color(0xFF6B7280); // 次要文字
  static const Color textTertiary = Color(0xFF9CA3AF); // 辅助/占位文字
  static const Color primaryHover = Color(0xFF1976D2); // 主色深（按压态）
  static const Color primarySoft = Color(0xFFE3F2FD); // 主色浅底
  static const Color primarySoftBorder = Color(0xFFBBDEFB); // 主色浅边框
  static const Color danger = Color(0xFFE64A19); // 危险色
  static const Color dangerSoft = Color(0xFFFBE9E7); // 危险色浅底
  static const Color success = Color(0xFF4CAF50); // 成功色
  static const Color successSoft = Color(0xFFE8F5E9); // 成功色浅底
  static const Color warning = Color(0xFFEA580C); // 警告色
  static const Color warningSoft = Color(0xFFFFF7ED); // 警告色浅底
  static const Color dividerColor = Color(0xFFE5E7EB); // 分割线
  static const Color inputBgColor = Color(0xFFF3F4F6); // 输入框背景
  static const Color borderColor = Color(0xFFE5E7EB); // 通用边框
  static const Color borderSoft = Color(0xFFF3F4F6); // 柔和边框
  static const Color overlayColor = Color(0x73111827); // 弹窗遮罩

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

  /// 获取标签颜色 [背景色, 文字色]
  static List<Color> getTagColors(String tag) {
    return tagColors[tag] ?? [const Color(0xFFE3F2FD), const Color(0xFF2196F3)];
  }

  /// 封面渐变色
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

  // ===== 设置项图标背景色 =====
  static const Map<String, Color> settingsIconBg = {
    'api': Color(0xFFE3F2FD),
    'knowledge': Color(0xFFE8F5E9),
    'backup': Color(0xFFE3F2FD),
    'ima': Color(0xFFFCE4EC),
    'about': Color(0xFFF3F4F6),
  };

  // ===== 圆角规范 =====
  static const double radiusCard = 16.0;
  static const double radiusChip = 20.0;
  static const double radiusInput = 8.0;
  static const double radiusBtn = 8.0;
  static const double radiusModal = 20.0;
  static const double radiusSmall = 6.0;
  static const double radiusFab = 26.0;

  /// 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentCoral,
        tertiary: accentMint,
        surface: Colors.white,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.12),
        disabledColor: Colors.grey.shade50,
        labelStyle: const TextStyle(fontSize: 13, color: textPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 13, color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
          side: const BorderSide(color: borderColor, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFab),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: borderColor, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: borderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.8,
        space: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: textPrimary, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
        labelSmall: TextStyle(fontSize: 11, color: textTertiary),
      ),
    );
  }
}
