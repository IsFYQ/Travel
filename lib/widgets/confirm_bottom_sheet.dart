import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 兼容层：转发到 ui_design_system 确认弹层
Future<bool?> showConfirmBottomSheet({
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
  return showUdsConfirmSheet(
    context: context,
    title: title,
    description: description,
    confirmText: confirmText,
    cancelText: cancelText,
    confirmColor: confirmColor,
    confirmBgColor: confirmBgColor,
    icon: icon,
    extraContent: extraContent,
  );
}

Future<bool?> showDeleteConfirmBottomSheet({
  required BuildContext context,
  required String title,
  required String description,
  String confirmText = '删除',
}) {
  return showUdsDeleteConfirmSheet(
    context: context,
    title: title,
    description: description,
    confirmText: confirmText,
  );
}

Future<String?> showInputBottomSheet({
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
  return showUdsInputSheet(
    context: context,
    title: title,
    subtitle: subtitle,
    hint: hint,
    controller: controller,
    icon: icon,
    iconBgColor: iconBgColor,
    iconColor: iconColor,
    confirmText: confirmText,
  );
}
