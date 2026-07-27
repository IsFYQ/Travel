import 'package:flutter/material.dart';
import '../../app/travel_icons.dart';
import '../../services/ai_service.dart';
import '../../exceptions/missing_credential_exception.dart';
import '../../app/theme.dart';

/// API 设置页面
class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final _ai = AiService();
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _ai.getApiKey();
    // P0-5：无已存 Key 时保持输入框为空，不做回填
    if (key != null && key.isNotEmpty && mounted) {
      _keyController.text = key;
    }
  }

  Future<void> _saveKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请输入 API Key')),
      );
      return;
    }

    await _ai.setApiKey(key);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('API Key 已保存')),
    );
  }

  Future<void> _testKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    await _ai.setApiKey(key);

    try {
      final result = await _ai.sendMessage(
        userMessage: '你好，请用一句话介绍自己',
        history: [],
        maxTokens: 50,
      );
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = result.contains('错误') || result.contains('网络')
            ? '❌ 连接失败: $result'
            : '✅ 连接成功: $result';
      });
    } on MissingCredentialException catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = '❌ ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = '❌ 连接失败: $e';
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // DeepSeek API Key
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TravelIcons.apiKey(size: 20, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'DeepSeek API Key',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '从 platform.deepseek.com 获取 API Key',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'sk-...',
                      labelText: 'API Key',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: TravelIcons.eyeToggle(size: 20, visible: _obscure),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: TravelIcons.save(size: 18),
                          label: const Text('保存'),
                          onPressed: _saveKey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _testing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : TravelIcons.testConnection(size: 18),
                          label: Text(_testing ? '测试中...' : '测试连接'),
                          onPressed: _testing ? null : _testKey,
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResult!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 使用说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _tipItem('1. 访问 platform.deepseek.com 注册账号'),
                  _tipItem('2. 在 API Keys 页面创建新的 Key'),
                  _tipItem('3. 复制 Key 粘贴到上方输入框'),
                  _tipItem('4. 点击"测试连接"确认 Key 有效'),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 API Key 仅存储在你的设备本地，不会上传到任何服务器',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
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
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
