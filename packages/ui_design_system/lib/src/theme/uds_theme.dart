import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_typography.dart';
import 'uds_theme_data.dart';

/// Builds Material [ThemeData] wired with [UdsThemeData] extension.
abstract final class UdsTheme {
  static ThemeData light() {
    final uds = UdsThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: UdsColors.primary,
        primary: UdsColors.primary,
        secondary: UdsColors.secondary,
        tertiary: UdsColors.tertiary,
        surface: UdsColors.surface,
        error: UdsColors.danger,
      ),
      scaffoldBackgroundColor: UdsColors.background,
      extensions: [uds],
      textTheme: UdsTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: UdsColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: UdsTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: UdsColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdsRadii.card),
          side: const BorderSide(color: UdsColors.border, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: UdsColors.surface,
        selectedColor: UdsColors.primarySoft,
        disabledColor: UdsColors.surfaceVariant,
        labelStyle: UdsTypography.labelMedium.copyWith(color: UdsColors.textPrimary),
        secondaryLabelStyle:
            UdsTypography.labelMedium.copyWith(color: UdsColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdsRadii.chip),
          side: const BorderSide(color: UdsColors.border, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: UdsColors.primary,
        foregroundColor: UdsColors.textOnPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdsRadii.fab),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: UdsColors.surface,
        selectedItemColor: UdsColors.primary,
        unselectedItemColor: UdsColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UdsColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.danger, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: UdsTypography.bodyMedium.copyWith(color: UdsColors.textTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: UdsColors.divider,
        thickness: 0.8,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UdsColors.primary,
          foregroundColor: UdsColors.textOnPrimary,
          elevation: 0,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UdsRadii.button),
          ),
          textStyle: UdsTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UdsColors.textSecondary,
          minimumSize: const Size(64, 44),
          side: const BorderSide(color: UdsColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UdsRadii.button),
          ),
          textStyle: UdsTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UdsColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: UdsTypography.labelLarge,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final uds = UdsThemeData.dark();
    final darkText = UdsTypography.textTheme.apply(
      bodyColor: UdsColors.darkTextPrimary,
      displayColor: UdsColors.darkTextPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: UdsColors.primary,
        brightness: Brightness.dark,
        primary: UdsColors.primaryLight,
        secondary: UdsColors.secondary,
        tertiary: UdsColors.tertiary,
        surface: UdsColors.darkSurface,
        error: UdsColors.danger,
      ),
      scaffoldBackgroundColor: UdsColors.darkBackground,
      extensions: [uds],
      textTheme: darkText,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: UdsColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: UdsTypography.titleLarge.copyWith(
          color: UdsColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: UdsColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdsRadii.card),
          side: const BorderSide(color: UdsColors.darkBorder, width: 0.8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: UdsColors.darkSurface,
        selectedItemColor: UdsColors.primaryLight,
        unselectedItemColor: UdsColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UdsColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.primaryLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: UdsColors.darkBorder,
        thickness: 0.8,
        space: 0,
      ),
    );
  }
}
