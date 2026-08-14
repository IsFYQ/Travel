import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import 'uds_button.dart';

/// Cancel / confirm row for bottom sheets.
class UdsSheetActionBar extends StatelessWidget {
  const UdsSheetActionBar({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.confirmLabel = '保存',
    this.cancelLabel = '取消',
    this.confirmColor = UdsColors.primary,
    this.loading = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: UdsButton(
            label: cancelLabel,
            onPressed: loading ? null : onCancel,
            variant: UdsButtonVariant.outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: UdsButton(
            label: confirmLabel,
            onPressed: onConfirm,
            loading: loading,
            color: confirmColor,
          ),
        ),
      ],
    );
  }
}
