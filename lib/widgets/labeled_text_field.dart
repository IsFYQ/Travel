import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 兼容层 → [UdsTextField]
class LabeledTextField extends StatelessWidget {
  final String label;
  final String? optionalHint;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final String? errorText;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.optionalHint,
    this.hintText,
    this.keyboardType,
    this.prefixText,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return UdsTextField(
      label: label,
      optionalHint: optionalHint,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      prefixText: prefixText,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      errorText: errorText,
    );
  }
}
