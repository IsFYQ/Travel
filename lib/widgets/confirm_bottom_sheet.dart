import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 通用底部抽屉式确认弹窗
///
/// 用于替代 showDialog + AlertDialog，统一为从底部滑入的抽屉式设计。
/// 遵循 App 规范：barrierColor = Colors.black54，圆角 = radiusModal(20)，
/// 禁止 backgroundColor: Colors.transparent。
Future<bool?> showConfirmBottomSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmText,
  String cancelText = '取消',
  Color confirmColor = AppTheme.danger,
  Color? confirmBgColor,
  Widget? icon,
  List<Widget>? extraContent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽手柄
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // 图标
            if (icon != null) ...[
              icon,
              const SizedBox(height: 16),
            ],
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 描述
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            // 额外内容（如勾选项列表）
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              ...extraContent,
            ],
            const SizedBox(height: 24),
            // 按钮区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textSecondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Text(cancelText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmBgColor ?? confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                            side: BorderSide(color: confirmColor),
                          ),
                        ),
                        child: Text(confirmText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 删除确认底部抽屉
Future<bool?> showDeleteConfirmBottomSheet({
  required BuildContext context,
  required String title,
  required String description,
  String confirmText = '删除',
}) {
  return showConfirmBottomSheet(
    context: context,
    title: title,
    description: description,
    confirmText: confirmText,
    confirmColor: AppTheme.danger,
    icon: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.dangerSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.warning_amber_rounded, size: 28, color: AppTheme.danger),
    ),
  );
}

/// 通用输入框底部抽屉
///
/// 用于替代 showDialog + AlertDialog(TextField) 的输入类弹窗。
Future<String?> showInputBottomSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required String hint,
  required TextEditingController controller,
  IconData icon = Icons.edit,
  Color iconBgColor = AppTheme.primarySoft,
  Color iconColor = AppTheme.primaryColor,
  String confirmText = '保存',
}) {
  return showModalBottomSheet<String>(
    context: context,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom;
      final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom + viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽手柄
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
            ),
            const SizedBox(height: 20),
            // 按钮区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textSecondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: const Text('取消',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                          ),
                        ),
                        child: Text(confirmText,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
