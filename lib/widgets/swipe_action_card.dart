import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 左滑操作按钮定义
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  /// 预设：隐藏按钮（中性白底）
  factory SwipeAction.hide({required VoidCallback onTap}) {
    return SwipeAction(
      icon: Icons.visibility_off_outlined,
      label: '隐藏',
      color: AppTheme.textSecondary,
      bgColor: Colors.white,
      borderColor: AppTheme.borderColor,
      onTap: onTap,
    );
  }

  /// 预设：删除按钮（危险色软底）
  factory SwipeAction.delete({required VoidCallback onTap}) {
    return SwipeAction(
      icon: Icons.delete_outline,
      label: '删除',
      color: AppTheme.danger,
      bgColor: AppTheme.dangerSoft,
      borderColor: AppTheme.danger.withValues(alpha: 0.15),
      onTap: onTap,
    );
  }
}

/// 通用左滑操作卡片
///
/// 包裹任意卡片内容，支持左滑 / 点击右侧区域 露出操作按钮。
/// 操作按钮采用软胶囊样式，与设计规范统一。
class SwipeActionCard extends StatefulWidget {
  /// 卡片正面内容
  final Widget child;

  /// 操作按钮列表（从左到右排列）
  final List<SwipeAction> actions;

  /// 操作区总宽度
  final double actionWidth;

  /// 卡片圆角（用于裁剪背景渐变）
  final double borderRadius;

  /// 卡片正面点击回调（卡片收起时触发）
  final VoidCallback? onTap;

  const SwipeActionCard({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 130,
    this.borderRadius = 14,
    this.onTap,
  });

  /// 关闭当前已展开的卡片（由外部调用）
  static void closeAll() {
    _SwipeActionCardState._globalClose?.call();
  }

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _isOpen = false;

  static VoidCallback? _globalClose;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    if (_globalClose == _close) _globalClose = null;
    _ctrl.dispose();
    super.dispose();
  }

  void _open() {
    // 关闭其他已展开的卡片
    _globalClose?.call();
    setState(() => _isOpen = true);
    _ctrl.forward();
    _globalClose = _close;
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _ctrl.reverse();
    if (_globalClose == _close) _globalClose = null;
  }

  @override
  Widget build(BuildContext context) {
    final openOffset = -widget.actionWidth.toDouble();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final dx = details.primaryDelta ?? 0;
        final current = _ctrl.value;
        final newVal = (current - dx / widget.actionWidth).clamp(0.0, 1.0);
        _ctrl.value = newVal;
      },
      onHorizontalDragEnd: (details) {
        if (_ctrl.value > 0.4) {
          _open();
        } else {
          _close();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final slide = openOffset * _anim.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // 操作按钮层（位于卡片下方右侧）
                if (_anim.value > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: widget.actionWidth.toDouble(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.backgroundColor.withValues(alpha: 0),
                              AppTheme.backgroundColor.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: widget.actions
                              .map((a) => Expanded(
                                    child: _buildCapsuleBtn(a),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                // 卡片正面
                Transform.translate(
                  offset: Offset(slide, 0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_isOpen) {
                        _close();
                      } else {
                        widget.onTap?.call();
                      }
                    },
                    child: widget.child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 软胶囊操作按钮
  Widget _buildCapsuleBtn(SwipeAction action) {
    return GestureDetector(
      onTap: () {
        _close();
        action.onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: action.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: action.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 16, color: action.color),
            const SizedBox(height: 2),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
