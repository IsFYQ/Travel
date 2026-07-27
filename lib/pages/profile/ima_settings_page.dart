import 'package:flutter/material.dart';
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

  /// P0-6：保存凭证
  Future<void> _saveCredentials() async {
    final clientId = _clientIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    if (clientId.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 Client ID 和 API Key')),
      );
      return;
    }
    await _ima.saveCredentials(clientId: clientId, apiKey: apiKey);
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
    if (!_hasCredentials) return;
    setState(() => _loadingKbList = true);
    final result = await _ima.getKnowledgeBaseList();
    if (!mounted) return;
    setState(() {
      _loadingKbList = false;
      if (result.isSuccess) {
        _knowledgeBases = result.data ?? [];
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_hasCredentials) {
      setState(() => _testResult = '请先配置凭证');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final result = await _ima.getKnowledgeBaseList();
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('IMA 同步设置')),
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
                    '从 ima.qq.com/agent-interface 获取凭证',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                      labelText: 'API Key',
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
                          child: Text(
                            _testResult ?? (_testing ? '正在测试连接...' : '点击右侧按钮测试连接'),
                            style: TextStyle(
                              fontSize: 13,
                              color: _testResult?.startsWith('✅') == true
                                  ? Colors.green
                                  : _testResult?.startsWith('❌') == true
                                      ? Colors.red
                                      : AppTheme.textSecondary,
                            ),
                          ),
                        ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_syncProgress!,
                          style: const TextStyle(fontSize: 13)),
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
                  _tipItem('API Key 有效期约 3 个月，过期需到 IMA 官网重新生成'),
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
