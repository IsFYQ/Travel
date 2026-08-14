import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

/// Labeled text field with error support.
class UdsTextField extends StatelessWidget {
  const UdsTextField({
    super.key,
    this.label,
    this.optionalHint,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixText,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.errorText,
    this.obscureText = false,
    this.onChanged,
    this.enabled = true,
    this.fillColor,
  });

  final String? label;
  final String? optionalHint;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final String? errorText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      obscureText: obscureText,
      onChanged: onChanged,
      enabled: enabled,
      style: UdsTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        errorText: errorText,
        prefixStyle: UdsTypography.bodyLarge,
        filled: true,
        fillColor: fillColor ?? UdsColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdsRadii.input),
          borderSide: const BorderSide(color: UdsColors.danger),
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label!, style: UdsTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            )),
            if (optionalHint != null) ...[
              const SizedBox(width: UdsSpacing.xs),
              Text(optionalHint!, style: UdsTypography.labelMedium.copyWith(
                color: UdsColors.textTertiary,
              )),
            ],
          ],
        ),
        const SizedBox(height: UdsSpacing.sm),
        field,
      ],
    );
  }
}
