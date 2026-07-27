import 'package:flutter/material.dart';
import '../../app/travel_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/ai_service.dart';
import '../../models/user_profile.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

/// 我的页面 - 个人中心
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _ai = AiService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _ai.getUserProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 自定义头部
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 22, 16, 12),
            child: const Text(
              '我的',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // 旅行统计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatsGrid(context),
          ),
          const SizedBox(height: 20),
          // 个人信息
          _buildSection(context, '个人信息', [
            _SettingsItem(
              icon: const Icon(Icons.person_outline, size: 22, color: Color(0xFF7C3AED)),
              iconBg: const Color(0xFFEDE7F6),
              title: '个人信息',
              subtitle: _profile?.summary ?? '点击填写个人信息，提升AI推荐准确度',
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.userProfile,
                );
                if (result is UserProfile) {
                  setState(() => _profile = result);
                }
              },
            ),
          ]),
          const SizedBox(height: 20),
          // 设置
          _buildSection(context, '设置', [
            _SettingsItem(
              icon: TravelIcons.apiKey(size: 22, color: AppTheme.primaryColor),
              iconBg: AppTheme.settingsIconBg['api']!,
              title: 'API 设置',
              subtitle: '配置 DeepSeek API Key',
              onTap: () => Navigator.pushNamed(context, AppRoutes.apiSettings),
            ),
            _SettingsItem(
              icon: TravelIcons.knowledgeBase(size: 22, color: AppTheme.accentMint),
              iconBg: AppTheme.settingsIconBg['knowledge']!,
              title: '知识库管理',
              subtitle: '查看和管理知识库数据',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('知识库管理功能开发中...')),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),
          // 数据
          _buildSection(context, '数据', [
            _SettingsItem(
              icon: TravelIcons.backup(size: 22, color: AppTheme.primaryColor),
              iconBg: AppTheme.settingsIconBg['backup']!,
              title: '数据备份',
              subtitle: '导出数据为 JSON 文件',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据备份功能开发中...')),
                );
              },
            ),
            _SettingsItem(
              icon: TravelIcons.imaSync(size: 22, color: const Color(0xFFE91E63)),
              iconBg: AppTheme.settingsIconBg['ima']!,
              title: 'IMA 同步',
              subtitle: '腾讯 IMA 知识库同步',
              onTap: () => Navigator.pushNamed(context, AppRoutes.imaSettings),
            ),
            _SettingsItem(
              icon: const Icon(Icons.description_outlined, size: 22, color: Color(0xFF00897B)),
              iconBg: const Color(0xFFE0F2F1),
              title: '提示词',
              subtitle: '查看和编辑 AI 提示词',
              onTap: () => Navigator.pushNamed(context, AppRoutes.promptSettings),
            ),
          ]),
          const SizedBox(height: 20),
          // 关于
          _buildSection(context, '关于', [
            _SettingsItem(
              icon: TravelIcons.about(size: 22, color: AppTheme.textTertiary),
              iconBg: AppTheme.settingsIconBg['about']!,
              title: '关于',
              subtitle: '旅行搭子 v1.0.0',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// 统计网格 - 4个独立卡片
  Widget _buildStatsGrid(BuildContext context) {
    final stats = context.watch<AppProvider>().statistics;
    final cityCount = stats['city_count'] ?? 0;
    final recordCount = stats['record_count'] ?? 0;
    final totalDays = stats['total_days'] ?? 0;
    final totalCost = ((stats['total_cost'] ?? 0.0) as double).toStringAsFixed(0);

    return Row(
      children: [
        _statBox('$cityCount', '去过的城市'),
        const SizedBox(width: 8),
        _statBox('$recordCount', '旅行次数'),
        const SizedBox(width: 8),
        _statBox('$totalDays', '旅行天数'),
        const SizedBox(width: 8),
        _statBox('¥$totalCost', '总花费'),
      ],
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor, width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 0.8),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildSettingsTile(context, items[i]),
                  if (i < items.length - 1)
                    Divider(
                      height: 0.8,
                      thickness: 0.8,
                      color: AppTheme.borderColor,
                      indent: 68,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, _SettingsItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            // 图标背景
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: item.icon),
            ),
            const SizedBox(width: 14),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            TravelIcons.arrowRight(
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置项数据
class _SettingsItem {
  final Widget icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
