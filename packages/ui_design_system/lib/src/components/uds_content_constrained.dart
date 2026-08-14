import 'package:flutter/material.dart';
import '../tokens/uds_spacing.dart';

/// Caps content width on tablets / landscape; keeps phone full-bleed.
class UdsContentConstrained extends StatelessWidget {
  const UdsContentConstrained({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Safe horizontal page inset that respects [UdsSpacing.pagePadding].
EdgeInsets udsPageInsets(BuildContext context, {double? top, double? bottom}) {
  final media = MediaQuery.of(context);
  return EdgeInsets.fromLTRB(
    UdsSpacing.pagePadding + media.padding.left,
    top ?? 0,
    UdsSpacing.pagePadding + media.padding.right,
    bottom ?? 0,
  );
}
