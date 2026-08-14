import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../app/theme.dart';
import '../../models/user_profile.dart';
import '../../services/ai_service.dart';
import '../../widgets/confirm_bottom_sheet.dart';

/// 个人信息编辑页面 — 匹配设计规范
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _ai = AiService();
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _nicknameError;

  // 基本信息
  late TextEditingController _cityCtrl;
  late TextEditingController _nicknameCtrl;

  // 偏好标签（多选）
  final List<String> _travelStyles = [];
  final List<String> _foodPrefs = [];
  final List<String> _companions = [];
  final List<String> _avoidances = [];

  // 扩展自定义选项池
  final List<String> _travelStyleOptions = List.from(UserProfilePresets.travelStyles);
  final List<String> _foodPrefOptions = List.from(UserProfilePresets.foodPrefs);
  final List<String> _companionOptions = List.from(UserProfilePresets.companions);
  final List<String> _avoidanceOptions = List.from(UserProfilePresets.avoidances);

  // 单选
  BudgetLevel? _budgetLevel;
  TravelGroupSize? _groupSize;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController();
    _nicknameCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _loadProfile() async {
    final profile = await _ai.getUserProfile();
    if (!mounted) return;
    setState(() {
      _cityCtrl.text = profile.homeCity;
      _nicknameCtrl.text = profile.nickname;
      _travelStyles
        ..clear()
        ..addAll(profile.travelStyles);
      _foodPrefs
        ..clear()
        ..addAll(profile.foodPrefs);
      _companions
        ..clear()
        ..addAll(profile.companions);
      _avoidances
        ..clear()
        ..addAll(profile.avoidances);
      _budgetLevel = profile.budgetLevel;
      _groupSize = profile.groupSize;

      for (final t in profile.travelStyles) {
        if (!_travelStyleOptions.contains(t)) _travelStyleOptions.add(t);
      }
      for (final t in profile.foodPrefs) {
        if (!_foodPrefOptions.contains(t)) _foodPrefOptions.add(t);
      }
      for (final t in profile.companions) {
        if (!_companionOptions.contains(t)) _companionOptions.add(t);
      }
      for (final t in profile.avoidances) {
        if (!_avoidanceOptions.contains(t)) _avoidanceOptions.add(t);
      }

      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final nickname = _nicknameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写居住城市')),
      );
      return;
    }
    if (nickname.isNotEmpty && (nickname.length < 2 || nickname.length > 16)) {
      setState(() => _nicknameError = '昵称需为 2–16 个字符');
      return;
    }
    setState(() {
      _nicknameError = null;
      _saving = true;
    });

    try {
      final profile = UserProfile(
        homeCity: city,
        nickname: nickname,
        travelStyles: List.from(_travelStyles),
        foodPrefs: List.from(_foodPrefs),
        budgetLevel: _budgetLevel,
        groupSize: _groupSize,
        companions: List.from(_companions),
        avoidances: List.from(_avoidances),
      );

      await _ai.saveUserProfile(profile);

      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      Navigator.pop(context, profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showUdsConfirmSheet(
      context: context,
      title: '放弃修改？',
      description: '你有未保存的修改，放弃后将无法恢复。',
      confirmText: '放弃修改',
      cancelText: '继续编辑',
      confirmColor: UdsColors.danger,
    );
    return discard == true;
  }

  /// 弹出自定义标签输入框
  Future<void> _showAddTagDialog({
    required String title,
    required void Function(String tag) onAdd,
  }) async {
    final tempCtrl = TextEditingController();
    final result = await showInputBottomSheet(
      context: context,
      title: '添加$title',
      hint: '输入自定义$title',
      controller: tempCtrl,
      icon: Icons.add,
      confirmText: '添加',
    );
    // BugFix: sheet 关闭动画 + IME 收起可能超过一帧，延后释放 controller
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      tempCtrl.dispose();
    });
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      onAdd(result);
      _markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final top = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        _buildTopBar(top),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 100),
            children: [
              _buildInfoCard(
                title: '基本信息',
                child: Column(
                  children: [
                    _buildRowItem(
                      label: '居住城市',
                      value: _cityCtrl.text.isEmpty ? '' : _cityCtrl.text,
                      onTap: () => _editTextField(
                        title: '编辑居住城市',
                        subtitle: '你目前居住的城市',
                        controller: _cityCtrl,
                        hint: '如：成都、北京',
                      ),
                    ),
                    _buildRowDivider(),
                    _buildRowItem(
                      label: '昵称',
                      value: _nicknameCtrl.text.isEmpty ? '' : _nicknameCtrl.text,
                      valueAccent: true,
                      errorText: _nicknameError,
                      onTap: () async {
                        await _editTextField(
                          title: '编辑昵称',
                          subtitle: '支持中英文、数字，2-16 个字符',
                          controller: _nicknameCtrl,
                          hint: '请输入新昵称',
                        );
                        if (_nicknameError != null) {
                          setState(() => _nicknameError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '旅行风格',
                subtitle: '选择你喜欢的旅行方式（可多选）',
                child: _buildTagCloud(
                  selected: _travelStyles,
                  options: _travelStyleOptions,
                  onChanged: (tag, sel) {
                    setState(() {
                      sel ? _travelStyles.add(tag) : _travelStyles.remove(tag);
                    });
                    _markDirty();
                  },
                  onAdd: () => _showAddTagDialog(
                    title: '旅行风格',
                    onAdd: (tag) => setState(() {
                      if (!_travelStyleOptions.contains(tag)) _travelStyleOptions.add(tag);
                      _travelStyles.add(tag);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '饮食偏好',
                subtitle: '告诉我们你爱吃什么',
                child: _buildTagCloud(
                  selected: _foodPrefs,
                  options: _foodPrefOptions,
                  onChanged: (tag, sel) {
                    setState(() {
                      sel ? _foodPrefs.add(tag) : _foodPrefs.remove(tag);
                    });
                    _markDirty();
                  },
                  onAdd: () => _showAddTagDialog(
                    title: '饮食偏好',
                    onAdd: (tag) => setState(() {
                      if (!_foodPrefOptions.contains(tag)) _foodPrefOptions.add(tag);
                      _foodPrefs.add(tag);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '预算偏好',
                subtitle: '单次旅行的预算范围（单人）',
                child: _buildPillGroup(
                  options: BudgetLevel.values.map((l) => l.label).toList(),
                  selectedIndex: _budgetLevel != null ? BudgetLevel.values.indexOf(_budgetLevel!) : -1,
                  onSelect: (i) {
                    setState(() => _budgetLevel = BudgetLevel.values[i]);
                    _markDirty();
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '出行习惯',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubLabel('常出行人数'),
                    _buildPillGroup(
                      options: TravelGroupSize.values.map((s) => s.label).toList(),
                      selectedIndex: _groupSize != null ? TravelGroupSize.values.indexOf(_groupSize!) : -1,
                      onSelect: (i) {
                        setState(() => _groupSize = TravelGroupSize.values[i]);
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSubLabel('同行对象'),
                    const SizedBox(height: 8),
                    _buildTagCloud(
                      selected: _companions,
                      options: _companionOptions,
                      onChanged: (tag, sel) {
                        setState(() {
                          sel ? _companions.add(tag) : _companions.remove(tag);
                        });
                        _markDirty();
                      },
                      onAdd: () => _showAddTagDialog(
                        title: '同行对象',
                        onAdd: (tag) => setState(() {
                          if (!_companionOptions.contains(tag)) _companionOptions.add(tag);
                          _companions.add(tag);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '忌讳事项',
                subtitle: 'AI 规划时会主动回避这些项',
                child: _buildTagCloud(
                  selected: _avoidances,
                  options: _avoidanceOptions,
                  danger: true,
                  onChanged: (tag, sel) {
                    setState(() {
                      sel ? _avoidances.add(tag) : _avoidances.remove(tag);
                    });
                    _markDirty();
                  },
                  onAdd: () => _showAddTagDialog(
                    title: '忌讳事项',
                    onAdd: (tag) => setState(() {
                      if (!_avoidanceOptions.contains(tag)) _avoidanceOptions.add(tag);
                      _avoidances.add(tag);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(double top) {
    return Container(
      color: UdsColors.surface,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
      child: Row(
        children: [
          UdsIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 18,
            tooltip: '返回',
            onPressed: () async {
              if (!_dirty) {
                Navigator.pop(context);
                return;
              }
              final discard = await _confirmDiscard();
              if (discard && mounted) Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              '个人信息',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderSoft, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.only(left: 14), child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary))),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required String label,
    required String value,
    bool valueAccent = false,
    String? errorText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const Spacer(),
                if (value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: valueAccent
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary)),
                  ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textTertiary),
              ]),
              if (errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  errorText,
                  style: const TextStyle(fontSize: 12, color: UdsColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDivider() {
    return Divider(height: 1, thickness: 0.8, color: AppTheme.borderSoft);
  }

  Widget _buildTagCloud({
    required List<String> selected,
    required List<String> options,
    required void Function(String tag, bool selected) onChanged,
    required VoidCallback onAdd,
    bool danger = false,
  }) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      ...options.map((tag) {
        final isSelected = selected.contains(tag);
        return GestureDetector(
          onTap: () => onChanged(tag, !isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? (danger ? AppTheme.dangerSoft : AppTheme.primarySoft) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              border: Border.all(color: isSelected ? Colors.transparent : AppTheme.borderColor, width: 1),
            ),
            child: Text(tag, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? (danger ? AppTheme.danger : AppTheme.primaryColor) : AppTheme.textSecondary)),
          ),
        );
      }),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.radiusChip), border: Border.all(color: AppTheme.borderColor, width: 1)),
          child: const Text('+ 添加', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textTertiary)),
        ),
      ),
    ]);
  }

  Widget _buildPillGroup({required List<String> options, required int selectedIndex, required void Function(int index) onSelect}) {
    return Wrap(spacing: 8, runSpacing: 8, children: List.generate(options.length, (i) {
      final selected = i == selectedIndex;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 80) / 2 - 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            border: Border.all(color: selected ? Colors.transparent : AppTheme.borderColor, width: 1),
          ),
          child: Text(options[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary)),
        ),
      );
    }));
  }

  Widget _buildSubLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary));
  }

  Future<void> _editTextField({required String title, required String subtitle, required TextEditingController controller, required String hint}) async {
    final tempCtrl = TextEditingController(text: controller.text);
    final result = await showInputBottomSheet(
      context: context,
      title: title,
      subtitle: subtitle,
      hint: hint,
      controller: tempCtrl,
      icon: Icons.person_outline,
      confirmText: '保存',
    );
    // BugFix: sheet 关闭动画 + IME 收起可能超过一帧，延后释放 controller
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      tempCtrl.dispose();
    });
    if (!mounted) return;
    if (result != null) {
      controller.text = result;
      _markDirty();
      setState(() {});
    }
  }
}

