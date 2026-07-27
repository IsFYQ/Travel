import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_provider.dart';
import '../../app/travel_icons.dart';
import '../../models/travel_record.dart';
import '../../services/media_service.dart';
import '../../utils/date_format_util.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../widgets/swipe_action_card.dart';
import '../../widgets/confirm_bottom_sheet.dart';

/// 首页 - 旅行时间线
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String? _selectedTag;
  final TextEditingController _searchController = TextEditingController();
  bool _hiddenSectionExpanded = false;
  String _documentsPath = '';
  final _media = MediaService();

  @override
  void initState() {
    super.initState();
    _initDocumentsPath();
  }

  Future<void> _initDocumentsPath() async {
    final docs = await getApplicationDocumentsDirectory();
    if (mounted) setState(() => _documentsPath = docs.path);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppProvider>().loadRecords(
                search: _searchQuery,
                tag: _selectedTag,
              );
          await context.read<AppProvider>().loadHiddenRecords();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            SwipeActionCard.closeAll();
            return false;
          },
          child: CustomScrollView(
            slivers: [
              // 自定义头部
              SliverToBoxAdapter(child: _buildHeader()),
              // 统计卡片
              SliverToBoxAdapter(child: _buildStatsCard(context)),
              // 搜索栏
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              // 标签筛选
              SliverToBoxAdapter(child: _buildTagFilter(context)),
              // 时间线
              _buildTimeline(context),
              // 隐藏记录折叠模块
              _buildHiddenRecordsSection(context),
              // 底部安全区
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  /// 自定义头部
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '旅行搭子',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.normal,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '记录每一段旅程',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 统计卡片 - 带装饰圆
  Widget _buildStatsCard(BuildContext context) {
    final stats = context.watch<AppProvider>().statistics;
    final cityCount = stats['city_count'] ?? 0;
    final recordCount = stats['record_count'] ?? 0;
    final totalCost = (stats['total_cost'] ?? 0.0) as double;
    final totalDays = stats['total_days'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
            AppTheme.primaryLighter,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 装饰圆 - 右上
          Positioned(
            right: -15,
            top: -23,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // 装饰圆 - 左下
          Positioned(
            left: -30,
            bottom: -38,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$cityCount', '个城市'),
              _statItem('$recordCount', '次旅行'),
              _statItem('$totalDays', '天'),
              _statItem('¥${totalCost.toStringAsFixed(0)}', '总花费'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: 0.85,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// 搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 0.8),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索目的地...',
            hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            border: InputBorder.none,
            filled: false,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: TravelIcons.search(size: 18, color: AppTheme.textTertiary),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: TravelIcons.clearSearch(
                        size: 18, color: AppTheme.textTertiary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      context.read<AppProvider>().loadRecords();
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            context
                .read<AppProvider>()
                .loadRecords(search: value, tag: _selectedTag);
          },
        ),
      ),
    );
  }

  /// 标签筛选
  Widget _buildTagFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          _buildFilterChip(
            label: '全部',
            selected: _selectedTag == null,
            onSelected: (_) {
              setState(() => _selectedTag = null);
              context.read<AppProvider>().loadRecords(search: _searchQuery);
            },
          ),
          const SizedBox(width: 8),
          ...kTripTypes.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: type,
                selected: _selectedTag == type,
                onSelected: (selected) {
                  setState(() => _selectedTag = selected ? type : null);
                  context.read<AppProvider>().loadRecords(
                        search: _searchQuery,
                        tag: selected ? type : null,
                      );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选标签 - 简洁胶囊样式
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// FAB 按钮 - 蓝色阴影
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.diaryEditor),
      child: TravelIcons.addDiary(color: Colors.white),
    );
  }

  /// 时间线列表
  Widget _buildTimeline(BuildContext context) {
    final records = context.watch<AppProvider>().records;
    final loading = context.watch<AppProvider>().recordsLoading;

    if (loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (records.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TravelIcons.emptyTravel(size: 80),
              const SizedBox(height: 16),
              Text(
                '还没有旅行记录',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 8),
              Text(
                '点击右下角 + 开始记录你的旅行',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    // 按年月分组
    final grouped = <String, List<TravelRecord>>{};
    final sortedRecords = records.toList()
      ..sort((a, b) {
        final aDate = a.endDate ?? a.startDate ?? a.createdAt;
        final bDate = b.endDate ?? b.startDate ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    for (final record in sortedRecords) {
      final date = record.endDate ?? record.startDate ?? record.createdAt;
      final key = DateFormatUtil.yearMonth().format(date);
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final keys = grouped.keys.toList();
          int flatIndex = 0;
          for (final key in keys) {
            final items = grouped[key]!;
            if (flatIndex == index) return _buildMonthHeader(key);
            flatIndex++;
            for (int i = 0; i < items.length; i++) {
              if (flatIndex == index) {
                return _buildTimelineCard(context, items[i]);
              }
              flatIndex++;
            }
          }
          return null;
        },
        childCount: _calculateTotalItems(grouped),
      ),
    );
  }

  int _calculateTotalItems(Map<String, List<TravelRecord>> grouped) {
    int count = 0;
    for (final items in grouped.values) {
      count += 1 + items.length;
    }
    return count;
  }

  /// 月份标题
  Widget _buildMonthHeader(String monthYear) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            monthYear,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 时间线卡片 - 左滑触发操作按钮
  Widget _buildTimelineCard(BuildContext context, TravelRecord record) {
    final firstType = record.tripType.split(',').where((s) => s.isNotEmpty).firstOrNull ?? '';
    final tagColors = AppTheme.getTagColors(firstType);
    final gradientColors = AppTheme.getCoverGradient(firstType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SwipeActionCard(
        key: ValueKey(record.id),
        borderRadius: 14,
        onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.diaryEditor,
        arguments: {'recordId': record.id},
      ),
      actions: [
        SwipeAction.hide(
          onTap: () => context.read<AppProvider>().hideRecord(record.id),
        ),
        SwipeAction.delete(
          onTap: () => _showDeleteConfirmDialog(context, record.id),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSoft, width: 0.8),
        ),
        child: Row(
          children: [
            // 封面占位图（渐变色）
            Padding(
              padding: const EdgeInsets.all(14),
              child: record.coverImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_media.resolveMediaPathSync(
                            record.coverImagePath!, _documentsPath)),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        // P0-1：旧路径失效时占位
                        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(gradientColors),
                      ),
                    )
                  : _buildCoverPlaceholder(gradientColors),
            ),
            // 文字信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 目的地 + 标签行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.destination,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (firstType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tagColors[0],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              firstType,
                              style: TextStyle(
                                fontSize: 11,
                                color: tagColors[1],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 摘要
                    Text(
                      record.textSummary.isNotEmpty
                          ? record.textSummary
                          : '暂无摘要',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// 封面占位 - 渐变背景
  Widget _buildCoverPlaceholder(List<Color> gradientColors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: TravelIcons.imagePlaceholder(
          size: 20,
          color: gradientColors[1].withOpacity(0.5),
        ),
      ),
    );
  }

  /// 隐藏记录折叠模块
  Widget _buildHiddenRecordsSection(BuildContext context) {
    final hiddenRecords = context.watch<AppProvider>().hiddenRecords;
    if (hiddenRecords.isEmpty) {
      return const SliverToBoxAdapter();
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.borderSoft, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // 折叠头部
              GestureDetector(
                onTap: () {
                  setState(() => _hiddenSectionExpanded = !_hiddenSectionExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 小图标徽章
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.inputBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.visibility_off_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            children: [
                              const TextSpan(text: '查看被隐藏的记录'),
                              TextSpan(
                                text: '（${hiddenRecords.length}条）',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        _hiddenSectionExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              // 展开内容
              if (_hiddenSectionExpanded) ...[
                const Divider(height: 1, color: AppTheme.borderSoft),
                ...hiddenRecords.map(
                  (record) => _buildHiddenRecordCard(context, record),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 隐藏记录卡片
  Widget _buildHiddenRecordCard(BuildContext context, TravelRecord record) {
    final firstType = record.tripType.split(',').where((s) => s.isNotEmpty).firstOrNull ?? '';
    final gradientColors = AppTheme.getCoverGradient(firstType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSoft, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 封面小图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: TravelIcons.imagePlaceholder(
                size: 18,
                color: gradientColors[1].withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.destination,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  record.textSummary.isNotEmpty
                      ? record.textSummary
                      : '暂无摘要',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 横排操作按钮（查看 + 删除）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 查看按钮
              _buildHiddenActionBtn(
                icon: Icons.visibility_outlined,
                onTap: () => context.read<AppProvider>().unhideRecord(record.id),
                color: AppTheme.textSecondary,
                bgColor: Colors.white,
                borderColor: AppTheme.borderColor,
              ),
              const SizedBox(width: 6),
              // 删除按钮
              _buildHiddenActionBtn(
                icon: Icons.delete_outline,
                onTap: () => _showDeleteConfirmDialog(context, record.id),
                color: AppTheme.danger,
                bgColor: AppTheme.dangerSoft,
                borderColor: AppTheme.danger.withOpacity(0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 隐藏记录操作按钮
  Widget _buildHiddenActionBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  /// 删除确认弹窗 — 匹配设计规范
  Future<void> _showDeleteConfirmDialog(BuildContext context, String recordId) async {
    final confirmed = await showDeleteConfirmBottomSheet(
      context: context,
      title: '确定要删除这条旅行记录吗？',
      description: '该旅行记录将被永久删除。已关联的照片、笔记、预算等数据会一并清空。',
    );

    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteRecordPermanently(recordId);
    }
  }
}
