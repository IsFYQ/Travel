import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_spacing.dart';
import '../tokens/uds_typography.dart';
import 'uds_icon_button.dart';

enum UdsPageHeaderAlign { left, center }

/// Unified page header for MainShell tabs and sub-pages.
class UdsPageHeader extends StatelessWidget {
  const UdsPageHeader({
    super.key,
    required this.title,
    this.align = UdsPageHeaderAlign.left,
    this.leading,
    this.actions,
    this.onBack,
  });

  final String title;
  final UdsPageHeaderAlign align;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final back = onBack != null
        ? UdsIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 18,
            onPressed: onBack,
            tooltip: '返回',
          )
        : leading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        UdsSpacing.pagePadding,
        top + UdsSpacing.xl,
        UdsSpacing.pagePadding,
        UdsSpacing.md,
      ),
      child: SizedBox(
        height: UdsSpacing.minTap,
        child: Row(
          children: [
            if (back != null) back,
            if (align == UdsPageHeaderAlign.center) ...[
              if (back == null) const SizedBox(width: UdsSpacing.minTap),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: UdsTypography.titleLarge,
                ),
              ),
              ...(actions ?? [const SizedBox(width: UdsSpacing.minTap)]),
            ] else ...[
              if (back != null) const SizedBox(width: UdsSpacing.sm),
              Expanded(
                child: Text(title, style: UdsTypography.titleLarge),
              ),
              if (actions != null) ...actions!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact sub-page app bar (settings-style).
class UdsSettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UdsSettingsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: UdsTypography.titleLarge),
      leading: onBack != null
          ? UdsIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 18,
              onPressed: onBack ?? () => Navigator.maybePop(context),
              tooltip: '返回',
            )
          : null,
      actions: actions,
      backgroundColor: UdsColors.surface,
      foregroundColor: UdsColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }
}
