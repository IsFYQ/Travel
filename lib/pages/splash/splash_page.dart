import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

/// 启动开屏页 — 方案A：清新白底
/// 最短 1500ms，最长 3000ms，超时自动进入主界面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    // 2 秒后跳转
    Future.delayed(const Duration(seconds: 2), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF0F8FF),
            ],
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
                  // Logo 图标
                  _buildLogo(),
                  const SizedBox(height: 24),
                  // 品牌名
                  const Text(
                    '旅行搭子',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Slogan
                  const Text(
                    'RECORD · EXPLORE · REMEMBER',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 加载圆点
                  _buildDots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo：蓝色渐变圆角方块 + 山/太阳/飞机
  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SplashLogoPainter(),
        size: const Size(88, 88),
      ),
    );
  }

  /// 三个加载圆点（脉冲动画）
  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            // 交错动画：每个圆点延迟 200ms
            final t = (DateTime.now().millisecondsSinceEpoch % 1400) / 1400;
            final phase = (t + i * 0.15) % 1.0;
            final opacity = 0.3 + 0.7 * (phase < 0.5 ? phase * 2 : 2 - phase * 2);
            final scale = 0.8 + 0.3 * (phase < 0.5 ? phase * 2 : 2 - phase * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Logo 内部绘制：山 + 太阳 + 飞机轨迹
class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scaleX = w / 100;
    final scaleY = h / 100;

    // 高光层（顶部半透明）
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.5), highlightPaint);

    // 山廓
    final mountainPath = Path();
    mountainPath.moveTo(8 * scaleX, 76 * scaleY);
    mountainPath.cubicTo(
      8 * scaleX, 76 * scaleY,
      18 * scaleX, 64 * scaleY,
      28 * scaleX, 56 * scaleY,
    );
    mountainPath.cubicTo(
      38 * scaleX, 48 * scaleY,
      44 * scaleX, 60 * scaleY,
      52 * scaleX, 56 * scaleY,
    );
    mountainPath.cubicTo(
      60 * scaleX, 52 * scaleY,
      70 * scaleX, 38 * scaleY,
      80 * scaleX, 50 * scaleY,
    );
    mountainPath.cubicTo(
      86 * scaleX, 58 * scaleY,
      92 * scaleX, 64 * scaleY,
      92 * scaleX, 76 * scaleY,
    );
    mountainPath.close();

    final mountainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(mountainPath, mountainPaint);

    // 太阳
    final sunPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(74 * scaleX, 32 * scaleY),
      5 * scaleX,
      sunPaint,
    );

    // 飞机轨迹（虚线）
    final trailPath = Path();
    trailPath.moveTo(22 * scaleX, 36 * scaleY);
    trailPath.quadraticBezierTo(
      44 * scaleX, 22 * scaleY,
      70 * scaleX, 34 * scaleY,
    );
    final trailPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scaleX
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      trailPath,
      trailPaint,
    );

    // 飞机（简化三角形）
    canvas.save();
    canvas.translate(72 * scaleX, 32 * scaleY);
    canvas.rotate(-30 * 3.14159 / 180);
    final planePath = Path();
    planePath.moveTo(-7 * scaleX, 0);
    planePath.lineTo(7 * scaleX, 0);
    planePath.lineTo(4 * scaleX, -2 * scaleY);
    planePath.lineTo(2 * scaleX, -2 * scaleY);
    planePath.lineTo(0, -4 * scaleY);
    planePath.lineTo(-2 * scaleX, -2 * scaleY);
    planePath.lineTo(-4 * scaleX, -2 * scaleY);
    planePath.close();
    final planePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(planePath, planePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
