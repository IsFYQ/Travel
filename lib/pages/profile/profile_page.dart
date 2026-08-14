import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../app/travel_icons.dart';
import '../../providers/stats_provider.dart';
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

  Future<void> _showAbout() async {
    await showUdsConfirmSheet(
      context: context,
      title: '旅行搭子',
      description: 'v1.0.0\n记录旅行、AI 做攻略、发现新目的地',
      confirmText: '知道了',
      cancelText: '关闭',
      confirmColor: UdsColors.primary,
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: UdsColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.flight_takeoff_rounded,
            size: 28, color: UdsColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UdsPageHeader(title: '我的'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UdsSpacing.pagePadding),
            child: _buildStatsGrid(context),
          ),
          const SizedBox(height: UdsSpacing.xl),
          UdsSectionCard(
            title: '个人信息',
            children: [
              UdsSettingsTile(
                icon: const Icon(Icons.person_outline,
                    size: 22, color: UdsColors.primary),
                iconBg: UdsColors.primarySoft,
                title: '个人信息',
                subtitle: _profile?.summary ?? '点击填写个人信息，提升AI推荐准确度',
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.userProfile,
                  );
                  if (!mounted) return;
                  if (result is UserProfile) {
                    setState(() => _profile = result);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('保存成功')),
                      );
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: UdsSpacing.xl),
          UdsSectionCard(
            title: '设置',
            children: [
              UdsSettingsTile(
                icon: TravelIcons.apiKey(size: 22, color: AppTheme.primaryColor),
                iconBg: AppTheme.settingsIconBg['api']!,
                title: 'API 设置',
                subtitle: '配置 DeepSeek API Key',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.apiSettings),
              ),
              const Divider(indent: 68),
              UdsSettingsTile(
                icon: TravelIcons.knowledgeBase(
                    size: 22, color: AppTheme.accentMint),
                iconBg: AppTheme.settingsIconBg['knowledge']!,
                title: '知识库管理',
                subtitle: '查看和管理知识库数据',
                comingSoon: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: UdsSpacing.xl),
          UdsSectionCard(
            title: '数据',
            children: [
              UdsSettingsTile(
                icon: TravelIcons.backup(size: 22, color: AppTheme.primaryColor),
                iconBg: AppTheme.settingsIconBg['backup']!,
                title: '数据备份',
                subtitle: '导出数据为 JSON 文件',
                onTap: () => Navigator.pushNamed(context, AppRoutes.backup),
              ),
              const Divider(indent: 68),
              UdsSettingsTile(
                icon: TravelIcons.imaSync(
                    size: 22, color: const Color(0xFFE91E63)),
                iconBg: AppTheme.settingsIconBg['ima']!,
                title: 'IMA 同步',
                subtitle: '腾讯 IMA 知识库同步',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.imaSettings),
              ),
              const Divider(indent: 68),
              UdsSettingsTile(
                icon: const Icon(Icons.description_outlined,
                    size: 22, color: UdsColors.tertiary),
                iconBg: AppTheme.settingsIconBg['prompt']!,
                title: '提示词',
                subtitle: '查看和编辑 AI 提示词',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.promptSettings),
              ),
            ],
          ),
          const SizedBox(height: UdsSpacing.xl),
          UdsSectionCard(
            title: '关于',
            children: [
              UdsSettingsTile(
                icon: TravelIcons.about(
                    size: 22, color: AppTheme.textTertiary),
                iconBg: AppTheme.settingsIconBg['about']!,
                title: '关于',
                subtitle: '旅行搭子 v1.0.0',
                onTap: _showAbout,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = context.watch<StatsProvider>().statistics;
    final cityCount = stats['city_count'] ?? 0;
    final recordCount = stats['record_count'] ?? 0;
    final totalDays = stats['total_days'] ?? 0;
    final totalCost =
        ((stats['total_cost'] ?? 0.0) as double).toStringAsFixed(0);

    return Row(
      children: [
        _statBox('$cityCount', '去过的城市'),
        const SizedBox(width: UdsSpacing.sm),
        _statBox('$recordCount', '旅行次数'),
        const SizedBox(width: UdsSpacing.sm),
        _statBox('$totalDays', '旅行天数'),
        const SizedBox(width: UdsSpacing.sm),
        _statBox('¥$totalCost', '总花费'),
      ],
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: UdsCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: UdsTypography.headlineMedium.copyWith(
                fontSize: 20,
                color: UdsColors.primary,
              ),
            ),
            const SizedBox(height: UdsSpacing.sm),
            Text(label, style: UdsTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}
