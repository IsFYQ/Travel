import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';

/// Runtime theme tokens accessible via `context.uds`.
@immutable
class UdsThemeData extends ThemeExtension<UdsThemeData> {
  const UdsThemeData({
    required this.primary,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderSoft,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.overlay,
    required this.radiusCard,
    required this.radiusButton,
    required this.radiusModal,
    required this.pagePadding,
  });

  final Color primary;
  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color borderSoft;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color warningSoft;
  final Color overlay;
  final double radiusCard;
  final double radiusButton;
  final double radiusModal;
  final double pagePadding;

  factory UdsThemeData.light() => const UdsThemeData(
        primary: UdsColors.primary,
        primarySoft: UdsColors.primarySoft,
        background: UdsColors.background,
        surface: UdsColors.surface,
        surfaceVariant: UdsColors.surfaceVariant,
        textPrimary: UdsColors.textPrimary,
        textSecondary: UdsColors.textSecondary,
        textTertiary: UdsColors.textTertiary,
        border: UdsColors.border,
        borderSoft: UdsColors.borderSoft,
        success: UdsColors.success,
        successSoft: UdsColors.successSoft,
        danger: UdsColors.danger,
        dangerSoft: UdsColors.dangerSoft,
        warning: UdsColors.warning,
        warningSoft: UdsColors.warningSoft,
        overlay: UdsColors.overlay,
        radiusCard: UdsRadii.card,
        radiusButton: UdsRadii.button,
        radiusModal: UdsRadii.modal,
        pagePadding: UdsSpacing.pagePadding,
      );

  factory UdsThemeData.dark() => const UdsThemeData(
        primary: UdsColors.primaryLight,
        primarySoft: Color(0xFF1A3A5C),
        background: UdsColors.darkBackground,
        surface: UdsColors.darkSurface,
        surfaceVariant: Color(0xFF2A2A2A),
        textPrimary: UdsColors.darkTextPrimary,
        textSecondary: UdsColors.darkTextSecondary,
        textTertiary: Color(0xFF6B7280),
        border: UdsColors.darkBorder,
        borderSoft: Color(0xFF2A2A2A),
        success: UdsColors.success,
        successSoft: Color(0xFF1B3D1F),
        danger: UdsColors.danger,
        dangerSoft: Color(0xFF3D1F1A),
        warning: UdsColors.warning,
        warningSoft: Color(0xFF3D2A1A),
        overlay: Color(0x99000000),
        radiusCard: UdsRadii.card,
        radiusButton: UdsRadii.button,
        radiusModal: UdsRadii.modal,
        pagePadding: UdsSpacing.pagePadding,
      );

  @override
  UdsThemeData copyWith({
    Color? primary,
    Color? primarySoft,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderSoft,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? dangerSoft,
    Color? warning,
    Color? warningSoft,
    Color? overlay,
    double? radiusCard,
    double? radiusButton,
    double? radiusModal,
    double? pagePadding,
  }) {
    return UdsThemeData(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      overlay: overlay ?? this.overlay,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusButton: radiusButton ?? this.radiusButton,
      radiusModal: radiusModal ?? this.radiusModal,
      pagePadding: pagePadding ?? this.pagePadding,
    );
  }

  @override
  UdsThemeData lerp(ThemeExtension<UdsThemeData>? other, double t) {
    if (other is! UdsThemeData) return this;
    return UdsThemeData(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t)!,
      radiusButton: lerpDouble(radiusButton, other.radiusButton, t)!,
      radiusModal: lerpDouble(radiusModal, other.radiusModal, t)!,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
    );
  }
}

extension UdsThemeContext on BuildContext {
  UdsThemeData get uds =>
      Theme.of(this).extension<UdsThemeData>() ?? UdsThemeData.light();
}
