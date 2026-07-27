import 'package:flutter/material.dart';

/// P0-15: 弹窗关闭后自动释放 TextEditingController
Future<T?> showManagedModalBottomSheet<T>({
  required BuildContext context,
  required List<TextEditingController> controllers,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  Color barrierColor = Colors.black54,
  ShapeBorder? shape,
}) async {
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      shape: shape,
      builder: builder,
    );
  } finally {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
