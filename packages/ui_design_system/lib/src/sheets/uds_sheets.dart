import 'package:flutter/material.dart';
import '../components/uds_sheet_action_bar.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_radii.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';

Widget _sheetHandle() => Container(
      margin: const EdgeInsets.only(top: UdsSpacing.md),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: UdsColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );

/// Confirm bottom sheet — replaces AlertDialog for destructive/confirm flows.
Future<bool?> showUdsConfirmSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmText,
  String cancelText = '取消',
  Color confirmColor = UdsColors.danger,
  Color? confirmBgColor,
  Widget? icon,
  List<Widget>? extraContent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    barrierColor: UdsColors.scrim,
    isScrollControlled: true,
    backgroundColor: UdsColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(UdsRadii.modal)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: UdsSpacing.xl),
            if (icon != null) ...[
              icon,
              const SizedBox(height: UdsSpacing.lg),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UdsSpacing.xxl),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: UdsTypography.titleMedium.copyWith(fontSize: 17),
              ),
            ),
            const SizedBox(height: UdsSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UdsSpacing.xxl),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: UdsTypography.bodyMedium.copyWith(height: 1.6),
              ),
            ),
            if (extraContent != null) ...[
              const SizedBox(height: UdsSpacing.lg),
              ...extraContent,
            ],
            const SizedBox(height: UdsSpacing.xxl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UdsSpacing.xxl,
                0,
                UdsSpacing.xxl,
                UdsSpacing.xxl,
              ),
              child: UdsSheetActionBar(
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () => Navigator.pop(ctx, true),
                cancelLabel: cancelText,
                confirmLabel: confirmText,
                confirmColor: confirmBgColor ?? confirmColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool?> showUdsDeleteConfirmSheet({
  required BuildContext context,
  required String title,
  required String description,
  String confirmText = '删除',
}) {
  return showUdsConfirmSheet(
    context: context,
    title: title,
    description: description,
    confirmText: confirmText,
    confirmColor: UdsColors.danger,
    icon: Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: UdsColors.dangerSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        size: 28,
        color: UdsColors.danger,
      ),
    ),
  );
}

Future<String?> showUdsInputSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required String hint,
  required TextEditingController controller,
  IconData icon = Icons.edit,
  Color iconBgColor = UdsColors.primarySoft,
  Color iconColor = UdsColors.primary,
  String confirmText = '保存',
}) {
  return showModalBottomSheet<String>(
    context: context,
    barrierColor: UdsColors.scrim,
    isScrollControlled: true,
    backgroundColor: UdsColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(UdsRadii.modal)),
    ),
    builder: (ctx) => _UdsInputSheetBody(
      title: title,
      subtitle: subtitle,
      hint: hint,
      controller: controller,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      confirmText: confirmText,
    ),
  );
}

Future<void> _popInputSheet(BuildContext ctx, [String? value]) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 100));
  if (!ctx.mounted) return;
  Navigator.pop(ctx, value);
}

class _UdsInputSheetBody extends StatelessWidget {
  const _UdsInputSheetBody({
    required this.title,
    this.subtitle,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.confirmText,
  });

  final String title;
  final String? subtitle;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: UdsSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UdsSpacing.xxl),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(UdsRadii.md),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: UdsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: UdsTypography.titleMedium.copyWith(fontSize: 17),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: UdsTypography.labelMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UdsSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UdsSpacing.xxl),
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: UdsColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UdsRadii.input),
                  borderSide: const BorderSide(color: UdsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UdsRadii.input),
                  borderSide:
                      const BorderSide(color: UdsColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
              onSubmitted: (v) => _popInputSheet(context, v.trim()),
            ),
          ),
          const SizedBox(height: UdsSpacing.xl),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              UdsSpacing.xxl,
              0,
              UdsSpacing.xxl,
              UdsSpacing.xxl,
            ),
            child: UdsSheetActionBar(
              onCancel: () => _popInputSheet(context),
              onConfirm: () =>
                  _popInputSheet(context, controller.text.trim()),
              confirmLabel: confirmText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Managed bottom sheet that disposes controllers after close.
Future<T?> showUdsManagedSheet<T>({
  required BuildContext context,
  required List<TextEditingController> controllers,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
}) async {
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? UdsColors.surface,
      barrierColor: UdsColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(UdsRadii.modal)),
      ),
      builder: builder,
    );
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }
}
