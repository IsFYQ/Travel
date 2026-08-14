import 'package:flutter/material.dart';
import '../tokens/uds_colors.dart';
import '../tokens/uds_spacing.dart';

/// Full-page or inline loading indicator.
class UdsLoading extends StatelessWidget {
  const UdsLoading({
    super.key,
    this.message,
    this.fullscreen = false,
  });

  final String? message;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: UdsColors.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: UdsSpacing.md),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 13,
              color: UdsColors.textSecondary,
            ),
          ),
        ],
      ],
    );

    if (!fullscreen) return Center(child: body);
    return ColoredBox(
      color: UdsColors.background,
      child: Center(child: body),
    );
  }
}

/// Lightweight skeleton pulse block.
class UdsSkeleton extends StatefulWidget {
  const UdsSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<UdsSkeleton> createState() => _UdsSkeletonState();
}

class _UdsSkeletonState extends State<UdsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.4 + _c.value * 0.4,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: UdsColors.borderSoft,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
