import 'package:flutter/material.dart';
import 'package:ui_design_system/ui_design_system.dart';
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
  AiTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _ai.getApiKey();
    if (key != null && key.isNotEmpty && mounted) {
      _keyController.text = key;
    }
  }

  bool _isValidKeyFormat(String key) =>
      key.startsWith('sk-') && key.length >= 20;

  Future<void> _saveKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请输入 API Key')),
      );
      return;
    }
    if (!_isValidKeyFormat(key)) {
      final force = await showUdsConfirmSheet(
        context: context,
        title: '格式异常',
        description: 'Key 通常以 sk- 开头，是否仍要保存？',
        confirmText: '仍要保存',
        cancelText: '取消',
        confirmColor: UdsColors.warning,
      );
      if (force != true) return;
    }

    await _ai.setApiKey(key);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('API Key 已保存')),
    );
  }

  Future<void> _testKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      // P1-2.11：测试时不写入 storage
      final result = await _ai.testApiKey(key);
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = result;
      });
    } on MissingCredentialException catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = AiTestResult(success: false, errorType: AiTestErrorType.unknown);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = const AiTestResult(success: false, errorType: AiTestErrorType.unknown);
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
      backgroundColor: UdsColors.background,
      appBar: const UdsSettingsAppBar(title: 'API 设置'),
      body: UdsContentConstrained(
        child: ListView(
          padding: const EdgeInsets.all(UdsSpacing.pagePadding),
          children: [
            UdsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TravelIcons.apiKey(size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: UdsSpacing.sm),
                      Text('DeepSeek API Key', style: UdsTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: UdsSpacing.sm),
                  Text(
                    '从 platform.deepseek.com 获取 API Key',
                    style: UdsTypography.labelSmall,
                  ),
                  const SizedBox(height: UdsSpacing.lg),
                  UdsTextField(
                    controller: _keyController,
                    obscureText: _obscure,
                    hintText: 'sk-...',
                    label: 'API Key',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      child: Text(_obscure ? '显示' : '隐藏'),
                    ),
                  ),
                  const SizedBox(height: UdsSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: UdsButton(
                          label: '保存',
                          icon: Icons.save_outlined,
                          variant: UdsButtonVariant.outlined,
                          onPressed: _saveKey,
                        ),
                      ),
                      const SizedBox(width: UdsSpacing.md),
                      Expanded(
                        child: UdsButton(
                          label: _testing ? '测试中...' : '测试连接',
                          icon: Icons.wifi_tethering,
                          loading: _testing,
                          onPressed: _testing ? null : _testKey,
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: UdsSpacing.md),
                    UdsStatusBanner(
                      message: _testResult!.message,
                      tone: _testResult!.success
                          ? UdsStatusTone.success
                          : UdsStatusTone.danger,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: UdsSpacing.xxl),
            UdsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('使用说明', style: UdsTypography.titleMedium),
                  const SizedBox(height: UdsSpacing.md),
                  _tipItem('1. 访问 platform.deepseek.com 注册账号'),
                  _tipItem('2. 在 API Keys 页面创建新的 Key'),
                  _tipItem('3. 复制 Key 粘贴到上方输入框'),
                  _tipItem('4. 点击"测试连接"确认 Key 有效（不会自动保存）'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UdsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TravelIcons.connectionOk(size: 16, color: AppTheme.accentMint),
          const SizedBox(width: UdsSpacing.sm),
          Expanded(child: Text(text, style: UdsTypography.bodyMedium)),
        ],
      ),
    );
  }
}
