import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../app/travel_icons.dart';
import '../../services/ima_sync_service.dart';
import '../../app/theme.dart';

/// IMA 同步设置页面
class ImaSettingsPage extends StatefulWidget {
  const ImaSettingsPage({super.key});

  @override
  State<ImaSettingsPage> createState() => _ImaSettingsPageState();
}

class _ImaSettingsPageState extends State<ImaSettingsPage> {
  final _ima = ImaSyncService();
  final _clientIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _kbIdController = TextEditingController();

  bool _obscureApiKey = true;
  bool _loadingCreds = true;
  bool _testing = false;
  bool _syncing = false;
  bool _loadingKbList = false;
  String? _testResult;
  String? _syncProgress;
  List<ImaKnowledgeBase> _knowledgeBases = [];
  String? _selectedKbId;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _apiKeyController.dispose();
    _kbIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final creds = await _ima.getCredentials();
    final kbId = await _ima.getTravelKnowledgeBaseId();
    if (!mounted) return;
    setState(() {
      _clientIdController.text = creds['clientId'] ?? '';
      _apiKeyController.text = creds['apiKey'] ?? '';
      _kbIdController.text = kbId ?? '';
      _selectedKbId = kbId;
      _loadingCreds = false;
    });
  }

  bool get _hasCredentials =>
      _clientIdController.text.trim().isNotEmpty &&
      _apiKeyController.text.trim().isNotEmpty;

  /// BugFix: 读取输入框凭证，避免测试/加载时仍使用未保存的旧密钥
  Map<String, String>? _inputCredentials() {
    final clientId = _clientIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    if (clientId.isEmpty || apiKey.isEmpty) return null;
    return {'clientId': clientId, 'apiKey': apiKey};
  }

  /// P0-6：保存凭证
  Future<void> _saveCredentials() async {
    final creds = _inputCredentials();
    if (creds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 Client ID 和 API Key')),
      );
      return;
    }
    await _ima.saveCredentials(
      clientId: creds['clientId']!,
      apiKey: creds['apiKey']!,
    );
    final kbId = _kbIdController.text.trim();
    if (kbId.isNotEmpty) {
      await _ima.saveKnowledgeBaseId(kbId);
      _selectedKbId = kbId;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('凭证已保存')),
    );
    setState(() {});
    await _loadKnowledgeBases();
  }

  Future<void> _loadKnowledgeBases() async {
    final creds = _inputCredentials();
    if (creds == null) return;
    setState(() => _loadingKbList = true);
    // BugFix: 加载前先持久化输入框凭证，保证请求头与界面一致
    await _ima.saveCredentials(
      clientId: creds['clientId']!,
      apiKey: creds['apiKey']!,
    );
    final result = await _ima.getKnowledgeBaseList(
      clientId: creds['clientId'],
      apiKey: creds['apiKey'],
    );
    if (!mounted) return;
    setState(() {
      _loadingKbList = false;
      if (result.isSuccess) {
        _knowledgeBases = result.data ?? [];
      }
    });
  }

  Future<void> _testConnection() async {
    final creds = _inputCredentials();
    if (creds == null) {
      setState(() => _testResult = '请先配置凭证');
      return;
    }
    // BugFix: 官网常只常显 Client ID，用户容易把同一串填进 API Key
    if (creds['clientId'] == creds['apiKey']) {
      setState(() =>
          _testResult = '❌ Client ID 与 API Key 不能相同。请重新获取并分别填写两项');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });

    // BugFix: 测试连接时使用当前输入框凭证，并同步写入本地存储
    await _ima.saveCredentials(
      clientId: creds['clientId']!,
      apiKey: creds['apiKey']!,
    );
    final result = await _ima.getKnowledgeBaseList(
      clientId: creds['clientId'],
      apiKey: creds['apiKey'],
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result.isSuccess
          ? '✅ 连接成功！发现 ${result.data!.length} 个知识库'
          : '❌ 连接失败: ${result.error}';
      if (result.isSuccess) {
        _knowledgeBases = result.data ?? [];
      }
    });
  }

  Future<void> _startSync() async {
    if (!await _ima.hasFullConfig()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置凭证并选择知识库')),
      );
      return;
    }
    final confirmed = await showUdsConfirmSheet(
      context: context,
      title: '从 IMA 导入？',
      description: '将把知识库中的旅行笔记导入到本地。同 ID 内容可能被覆盖。',
      confirmText: '开始导入',
      confirmColor: UdsColors.primary,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _syncing = true;
      _syncProgress = '开始同步...';
    });

    final result = await _ima.importFromIma(
      onProgress: (message) {
        if (mounted) setState(() => _syncProgress = message);
      },
    );

    if (mounted) {
      setState(() {
        _syncing = false;
        _syncProgress = '同步完成！成功导入 ${result.importedCount} 条记录';
        if (result.hasErrors) {
          _syncProgress =
              '${_syncProgress!}\n\n部分条目导入失败：\n${result.errors.join('\n')}';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入完成：${result.importedCount} 条记录')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCreds) {
      return const Scaffold(
        appBar: UdsSettingsAppBar(title: 'IMA 同步设置'),
        body: UdsLoading(message: '加载凭证...'),
      );
    }

    return Scaffold(
      appBar: const UdsSettingsAppBar(title: 'IMA 同步设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // P0-6：凭证配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TravelIcons.apiKey(size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('IMA 凭证',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '从 ima.qq.com/agent-interface 获取凭证。\n'
                    '注意：API Key 生成后只显示一次；若页面只剩 Client ID，'
                    '请先「删除API Key」再「重新获取」，立刻复制 Client ID 和 API Key 两项。',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _clientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Client ID',
                      hintText: '输入 Client ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key（与 Client ID 不同，勿填同一串）',
                      hintText: '输入 API Key',
                      suffixIcon: IconButton(
                        icon: TravelIcons.eyeToggle(
                            size: 20, visible: _obscureApiKey),
                        onPressed: () =>
                            setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _kbIdController,
                    decoration: const InputDecoration(
                      labelText: '知识库 ID（可手动填写或下方选择）',
                      hintText: '知识库 ID',
                    ),
                    onChanged: (v) => _selectedKbId = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: TravelIcons.save(size: 18),
                      label: const Text('保存凭证'),
                      onPressed: _saveCredentials,
                    ),
                  ),
                  if (_hasCredentials) ...[
                    const SizedBox(height: 16),
                    const Text('选择目标知识库',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_loadingKbList)
                      const Center(child: CircularProgressIndicator())
                    else if (_knowledgeBases.isEmpty)
                      OutlinedButton(
                        onPressed: _loadKnowledgeBases,
                        child: const Text('加载知识库列表'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedKbId != null &&
                                _knowledgeBases.any((k) => k.id == _selectedKbId)
                            ? _selectedKbId
                            : null,
                        decoration: const InputDecoration(
                          labelText: '知识库',
                          border: OutlineInputBorder(),
                        ),
                        items: _knowledgeBases
                            .map((kb) => DropdownMenuItem(
                                  value: kb.id,
                                  child: Text(kb.name),
                                ))
                            .toList(),
                        onChanged: (id) async {
                          if (id == null) return;
                          setState(() {
                            _selectedKbId = id;
                            _kbIdController.text = id;
                          });
                          await _ima.saveKnowledgeBaseId(id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('知识库已选择')),
                            );
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 连接状态 =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TravelIcons.imaSync(size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('IMA 连接状态',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_hasCredentials)
                    const Text('请先配置凭证',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: UdsStatusBanner(
                            message: _testResult ??
                                (_testing ? '正在测试连接...' : '点击右侧按钮测试连接'),
                            tone: _testResult?.startsWith('✅') == true
                                ? UdsStatusTone.success
                                : _testResult?.startsWith('❌') == true
                                    ? UdsStatusTone.danger
                                    : UdsStatusTone.info,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : TravelIcons.testConnection(size: 16),
                          label: Text(_testing ? '测试中' : '测试连接'),
                          onPressed: _testing ? null : _testConnection,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 同步操作 =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TravelIcons.folder(size: 20, color: AppTheme.accentCoral),
                      const SizedBox(width: 8),
                      const Text('旅游记录',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '从 IMA 知识库导入所有目的地的旅行笔记',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : TravelIcons.cloudDownload(size: 18),
                      label: Text(_syncing ? '同步中...' : '从 IMA 导入到本地'),
                      onPressed: (_syncing || !_hasCredentials) ? null : _startSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_syncProgress != null) ...[
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        child: UdsStatusBanner(
                          message: _syncProgress!,
                          tone: _syncProgress!.contains('失败')
                              ? UdsStatusTone.warning
                              : _syncProgress!.contains('完成')
                                  ? UdsStatusTone.success
                                  : UdsStatusTone.info,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('同步说明',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _tipItem('每个目的地文件夹下的笔记会同步为一条旅行日记'),
                  _tipItem('导入的内容以纯文本形式保存，可在日记编辑器中补充照片'),
                  _tipItem('API Key 生成后只显示一次；失效时需删除后重新获取并同时更新两项凭证'),
                  _tipItem('同步方向：IMA → 本地（单向导入）'),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ 凭证仅存储在本地设备，不会上传到任何服务器',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TravelIcons.connectionOk(size: 16, color: AppTheme.accentMint),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
