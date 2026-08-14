import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';

/// 兼容层 → [UdsStarRating]
class StarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
    this.activeColor = UdsColors.star,
    this.inactiveColor = UdsColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return UdsStarRating(
      rating: rating,
      onChanged: onChanged,
      size: size,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }
}

/// 兼容层 → [UdsTagSelector]
class TagSelector extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const TagSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return UdsTagSelector(
      options: options,
      selected: selected,
      onChanged: onChanged,
    );
  }
}
