import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/ai_service.dart';
import '../../app/theme.dart';
import '../../widgets/confirm_bottom_sheet.dart';

/// 提示词元数据
class _PromptInfo {
  final String filename;
  final String name;
  final String description;

  const _PromptInfo({
    required this.filename,
    required this.name,
    required this.description,
  });
}

/// 所有提示词定义
const List<_PromptInfo> _allPrompts = [
  _PromptInfo(
    filename: 'system_prompt.txt',
    name: '系统人设',
    description: 'AI 助手的基础角色与行为设定',
  ),
  _PromptInfo(
    filename: 'followup_suggestions.txt',
    name: '追问建议',
    description: 'AI 回复后附带的推荐追问格式',
  ),
  _PromptInfo(
    filename: 'generate_itinerary.txt',
    name: '攻略生成',
    description: 'AI 生成旅行攻略的指令',
  ),
  _PromptInfo(
    filename: 'recommend_destination.txt',
    name: '目的地推荐',
    description: 'AI 推荐旅行目的地的指令',
  ),
  _PromptInfo(
    filename: 'diary_from_itinerary.txt',
    name: '攻略转日记',
    description: '将行程数据转为日记的指令',
  ),
];

/// 提示词管理页面
class PromptSettingsPage extends StatefulWidget {
  const PromptSettingsPage({super.key});

  @override
  State<PromptSettingsPage> createState() => _PromptSettingsPageState();
}

class _PromptSettingsPageState extends State<PromptSettingsPage> {
  final _ai = AiService();
  final Map<String, bool> _customFlags = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomFlags();
  }

  Future<void> _loadCustomFlags() async {
    final flags = <String, bool>{};
    for (final p in _allPrompts) {
      flags[p.filename] = await _ai.hasCustomPrompt(p.filename);
    }
    if (mounted) setState(() { _customFlags.addAll(flags); _loading = false; });
  }

  Future<void> _openEditor(_PromptInfo info) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PromptEditorPage(info: info),
      ),
    );
    if (changed == true) _loadCustomFlags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('提示词管理'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    '自定义 AI 提示词，修改后下次使用 AI 功能时自动生效',
                    style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                  ),
                ),
                ..._allPrompts.map((info) => _buildCard(info)),
              ],
            ),
    );
  }

  Widget _buildCard(_PromptInfo info) {
    final isCustom = _customFlags[info.filename] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor, width: 0.8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openEditor(info),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.description_outlined,
                        size: 20, color: Color(0xFF00897B)),
                  ),
                ),
                const SizedBox(width: 14),
                // 文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            info.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (isCustom) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMint.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '已自定义',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentMint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 箭头
                const Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 提示词编辑页面
class _PromptEditorPage extends StatefulWidget {
  final _PromptInfo info;

  const _PromptEditorPage({required this.info});

  @override
  State<_PromptEditorPage> createState() => _PromptEditorPageState();
}

class _PromptEditorPageState extends State<_PromptEditorPage> {
  final _ai = AiService();
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _controller.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    // 优先读自定义版本，无则读 assets 默认
    final custom = await _ai.loadPromptWithOverride(widget.info.filename);
    if (mounted) {
      setState(() {
        _controller.text = custom;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _ai.saveCustomPrompt(widget.info.filename, _controller.text);
    if (mounted) {
      setState(() { _saving = false; _dirty = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${widget.info.name}」已保存')),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showConfirmBottomSheet(
      context: context,
      title: '恢复默认',
      description: '确定要将「${widget.info.name}」恢复为默认内容吗？你的自定义修改将丢失。',
      confirmText: '确认恢复',
      confirmColor: AppTheme.danger,
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppTheme.warningSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.restore, size: 28, color: AppTheme.warning),
      ),
    );
    if (confirmed != true) return;
    await _ai.resetPrompt(widget.info.filename);
    // 重新加载默认内容
    final defaultContent =
        await rootBundle.loadString('assets/prompts/${widget.info.filename}');
    if (mounted) {
      setState(() {
        _controller.text = defaultContent;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${widget.info.name}」已恢复默认')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.info.name),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _loading ? null : _resetToDefault,
            child: const Text(
              '恢复默认',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 编辑区
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '输入提示词内容...',
                        filled: true,
                        fillColor: AppTheme.inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusInput),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusInput),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusInput),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
                // 底部保存按钮
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor, width: 0.8),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_dirty && !_saving) ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusBtn),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              '保存',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
