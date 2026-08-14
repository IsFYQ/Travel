import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 兼容层 → [showUdsManagedSheet]
Future<T?> showManagedModalBottomSheet<T>({
  required BuildContext context,
  required List<TextEditingController> controllers,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  Color barrierColor = UdsColors.scrim,
  ShapeBorder? shape,
}) {
  return showUdsManagedSheet<T>(
    context: context,
    controllers: controllers,
    builder: builder,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
  );
}
