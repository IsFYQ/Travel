import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_spacing.dart';

/// Star rating with proper tap targets.
class UdsStarRating extends StatelessWidget {
  const UdsStarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
    this.activeColor = UdsColors.star,
    this.inactiveColor = UdsColors.border,
  });

  final double rating;
  final ValueChanged<double>? onChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = rating >= star;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onChanged == null
                ? null
                : () => onChanged!(
                      star.toDouble() == rating ? 0 : star.toDouble(),
                    ),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: UdsSpacing.minTap,
              height: UdsSpacing.minTap,
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: filled ? activeColor : inactiveColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
