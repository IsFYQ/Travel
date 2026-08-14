import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../app/routes.dart';

/// 启动开屏页 — 最短 1500ms，最长 3000ms
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _dotsCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _navigated = false;

  static const _minDisplay = Duration(milliseconds: 1500);
  static const _maxDisplay = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    // 最短展示 1500ms；最长 3000ms 强制进入
    await Future.any([
      Future.delayed(_minDisplay),
      Future.delayed(_maxDisplay),
    ]);
    // 已至少等满 min；若动画未结束再等到动画完成，但不超过 max 总预算
    final remaining = _maxDisplay - _minDisplay;
    if (_ctrl.isAnimating) {
      await Future.any([
        _ctrl.forward(),
        Future.delayed(remaining),
      ]);
    }
    _goHome();
  }

  void _goHome() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [UdsColors.darkBackground, UdsColors.darkSurface]
                : const [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 28),
                  Text(
                    '旅行搭子',
                    style: UdsTypography.headlineMedium.copyWith(
                      color: isDark
                          ? UdsColors.darkTextPrimary
                          : UdsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '记录每一段旅程',
                    style: UdsTypography.bodyMedium.copyWith(
                      color: isDark
                          ? UdsColors.darkTextSecondary
                          : UdsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildDots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UdsRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: UdsElevation.raised,
      ),
      child: CustomPaint(
        painter: _SplashLogoPainter(),
        size: const Size(88, 88),
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotsCtrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_dotsCtrl.value + i * 0.15) % 1.0;
            final opacity =
                0.3 + 0.7 * (phase < 0.5 ? phase * 2 : 2 - phase * 2);
            final scale =
                0.75 + 0.25 * (phase < 0.5 ? phase * 2 : 2 - phase * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: UdsColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Simple path mark
    final path = Path()
      ..moveTo(cx - 18, cy + 8)
      ..quadraticBezierTo(cx - 4, cy - 18, cx + 6, cy - 4)
      ..quadraticBezierTo(cx + 14, cy + 6, cx + 18, cy - 10);
    canvas.drawPath(path, paint);

    final fill = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + 18, cy - 12), 4, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
