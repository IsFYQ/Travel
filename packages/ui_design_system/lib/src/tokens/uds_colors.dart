import 'package:flutter/material.dart';

/// Semantic color tokens — 清新海洋蓝旅游调性
abstract final class UdsColors {
  // Brand
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryLighter = Color(0xFF64B5F6);
  static const Color primaryHover = Color(0xFF1976D2);
  static const Color primarySoft = Color(0xFFE3F2FD);
  static const Color primarySoftBorder = Color(0xFFBBDEFB);

  static const Color secondary = Color(0xFFFF7043);
  static const Color tertiary = Color(0xFF4CAF50);

  // Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color inputBg = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSoft = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFE64A19);
  static const Color dangerSoft = Color(0xFFFBE9E7);
  static const Color warning = Color(0xFFEA580C);
  static const Color warningSoft = Color(0xFFFFF7ED);
  static const Color warningAccent = Color(0xFFFB923C);
  static const Color warningAccentDark = Color(0xFF9A3412);
  static const Color warningBorder = Color(0xFFFED7AA);
  static const Color star = Color(0xFFFFB300);

  // Overlay
  static const Color overlay = Color(0x73111827);
  static const Color scrim = Color(0x8A000000);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0x1AFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
}
