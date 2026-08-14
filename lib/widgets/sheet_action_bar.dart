import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 兼容层 → [UdsSheetActionBar]
class SheetActionBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final Color confirmColor;

  const SheetActionBar({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.confirmLabel = '保存评价',
    this.confirmColor = UdsColors.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    return UdsSheetActionBar(
      onCancel: onCancel,
      onConfirm: onConfirm,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    );
  }
}
