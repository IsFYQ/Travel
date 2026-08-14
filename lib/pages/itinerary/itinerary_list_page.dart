import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../providers/itinerary_provider.dart';
import '../../models/itinerary.dart';
import '../../models/itinerary_item.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../app/travel_icons.dart';
import '../../widgets/swipe_action_card.dart';
import '../../widgets/confirm_bottom_sheet.dart';
import '../../utils/date_format_util.dart';

/// 攻略列表页
class ItineraryListPage extends StatefulWidget {
  const ItineraryListPage({super.key});

  @override
  State<ItineraryListPage> createState() => _ItineraryListPageState();
}

class _ItineraryListPageState extends State<ItineraryListPage> {
  ItineraryStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UdsColors.background,
      body: Column(
        children: [
          const UdsPageHeader(
            title: '攻略',
            align: UdsPageHeaderAlign.center,
          ),
          Expanded(
            child: Consumer<ItineraryProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.itineraries.isEmpty) {
                  return const UdsLoading(message: '加载攻略中...');
                }

                final itineraries = provider.itineraries;

                if (itineraries.isEmpty) {
                  return _buildEmptyState();
                }

                final ongoing = itineraries
                    .where((i) => i.status == ItineraryStatus.ongoing)
                    .toList();
                final planning = itineraries
                    .where((i) => i.status == ItineraryStatus.planning)
                    .toList();
                final completed = itineraries
                    .where((i) => i.status == ItineraryStatus.completed)
                    .toList();

                final filteredOngoing =
                    _statusFilter == null ||
                            _statusFilter == ItineraryStatus.ongoing
                        ? ongoing
                        : <Itinerary>[];
                final filteredPlanning =
                    _statusFilter == null ||
                            _statusFilter == ItineraryStatus.planning
                        ? planning
                        : <Itinerary>[];
                final filteredCompleted =
                    _statusFilter == null ||
                            _statusFilter == ItineraryStatus.completed
                        ? completed
                        : <Itinerary>[];

                final hasFilteredResults = filteredOngoing.isNotEmpty ||
                    filteredPlanning.isNotEmpty ||
                    filteredCompleted.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<ItineraryProvider>().loadItineraries(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) {
                      SwipeActionCard.closeAll();
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        _buildStatsBanner(itineraries),
                        if (!hasFilteredResults)
                          _buildFilterEmptyState()
                        else ...[
                          if (filteredOngoing.isNotEmpty) ...[
                            _buildSectionHeader('进行中',
                                '${filteredOngoing.length} 个攻略', UdsColors.success),
                            ...filteredOngoing
                                .map((i) => _buildGuideCard(context, i)),
                          ],
                          if (filteredPlanning.isNotEmpty) ...[
                            _buildSectionHeader(
                                '规划中',
                                '${filteredPlanning.length} 个攻略',
                                UdsColors.primary),
                            ...filteredPlanning
                                .map((i) => _buildGuideCard(context, i)),
                          ],
                          if (filteredCompleted.isNotEmpty) ...[
                            _buildSectionHeader(
                                '已完成',
                                '${filteredCompleted.length} 个攻略',
                                UdsColors.textTertiary),
                            ...filteredCompleted
                                .map((i) => _buildGuideCard(context, i)),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatsBanner(List<Itinerary> itineraries) {
    final allCount = itineraries.length;
    final planningCount = itineraries.where((i) => i.status == ItineraryStatus.planning).length;
    final ongoingCount = itineraries.where((i) => i.status == ItineraryStatus.ongoing).length;
    final completedCount = itineraries.where((i) => i.status == ItineraryStatus.completed).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            UdsColors.primary,
            UdsColors.primaryLight,
            UdsColors.primaryLighter,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UdsRadii.xl),
      ),
      child: Row(
        children: [
          _buildStatItem(allCount.toString(), '全部', _statusFilter == null),
          _buildStatItem(planningCount.toString(), '规划中', _statusFilter == ItineraryStatus.planning),
          _buildStatItem(ongoingCount.toString(), '进行中', _statusFilter == ItineraryStatus.ongoing),
          _buildStatItem(completedCount.toString(), '已完成', _statusFilter == ItineraryStatus.completed),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, bool isActive) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (label == '全部') {
                _statusFilter = null;
              } else if (label == '规划中') {
                _statusFilter = _statusFilter == ItineraryStatus.planning ? null : ItineraryStatus.planning;
              } else if (label == '进行中') {
                _statusFilter = _statusFilter == ItineraryStatus.ongoing ? null : ItineraryStatus.ongoing;
              } else if (label == '已完成') {
                _statusFilter = _statusFilter == ItineraryStatus.completed ? null : ItineraryStatus.completed;
              }
            });
          },
          borderRadius: BorderRadius.circular(UdsRadii.md),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(UdsRadii.md),
            ),
            child: Column(
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isActive ? UdsColors.primary : Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? UdsColors.primary.withOpacity(0.8)
                        : Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          TravelIcons.emptyTravel(size: 64),
          const SizedBox(height: 16),
          const Text(
            '当前筛选下没有攻略',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _statusFilter = null),
            child: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Itinerary> itineraries) {
    final allCount = itineraries.length;
    final planningCount = itineraries.where((i) => i.status == ItineraryStatus.planning).length;
    final ongoingCount = itineraries.where((i) => i.status == ItineraryStatus.ongoing).length;
    final completedCount = itineraries.where((i) => i.status == ItineraryStatus.completed).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _filterTab('全部', allCount, _statusFilter == null),
          const SizedBox(width: 8),
          _filterTab('规划中', planningCount, _statusFilter == ItineraryStatus.planning),
          const SizedBox(width: 8),
          _filterTab('进行中', ongoingCount, _statusFilter == ItineraryStatus.ongoing),
          const SizedBox(width: 8),
          _filterTab('已完成', completedCount, _statusFilter == ItineraryStatus.completed),
        ],
      ),
    );
  }

  Widget _filterTab(String label, int count, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == '全部') {
            _statusFilter = null;
          } else if (label == '规划中') {
            _statusFilter = _statusFilter == ItineraryStatus.planning ? null : ItineraryStatus.planning;
          } else if (label == '进行中') {
            _statusFilter = _statusFilter == ItineraryStatus.ongoing ? null : ItineraryStatus.ongoing;
          } else if (label == '已完成') {
            _statusFilter = _statusFilter == ItineraryStatus.completed ? null : ItineraryStatus.completed;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, Itinerary itinerary) {
    final isOngoing = itinerary.status == ItineraryStatus.ongoing;
    final isDone = itinerary.status == ItineraryStatus.completed;

    final emoji = _getEmojiForDestination(itinerary.destination);
    final dateRange = _formatDateRange(itinerary.startDate, itinerary.endDate);
    final progress = _calculateProgress(itinerary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SwipeActionCard(
        key: ValueKey(itinerary.id),
        borderRadius: 16,
        actionWidth: 80,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.itineraryDetail,
          arguments: itinerary.id,
        ),
        actions: [
          SwipeAction.delete(
            onTap: () => _confirmDeleteItinerary(context, itinerary),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：emoji + 标题 + 状态标签
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOngoing
                            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                            : isDone
                                ? [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)]
                                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      itinerary.destination,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOngoing
                          ? const Color(0xFFE8F5E9)
                          : isDone
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOngoing) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentMint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          itinerary.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOngoing
                                ? AppTheme.accentMint
                                : isDone
                                    ? AppTheme.textSecondary
                                    : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 元信息
              Row(
                children: [
                  Text('📅 $dateRange', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 14),
                  Text('👥 ${itinerary.people} 人', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  if (itinerary.totalBudget > 0) ...[
                    const SizedBox(width: 14),
                    Text('💰 ¥${itinerary.totalBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // 进度条
              _buildProgressBar(itinerary, progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Itinerary itinerary, double progress) {
    final isOngoing = itinerary.status == ItineraryStatus.ongoing;
    final totalDays = itinerary.days;
    final completedDays = (totalDays * progress).round();

    String progressText;
    if (itinerary.status == ItineraryStatus.planning) {
      progressText = '待开始';
    } else if (itinerary.status == ItineraryStatus.completed) {
      progressText = 'Day $totalDays / Day $totalDays';
    } else {
      progressText = 'Day $completedDays / Day $totalDays';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOngoing
                  ? const Color(0xFF4CAF50)
                  : progress >= 1.0
                      ? AppTheme.textTertiary
                      : AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progressText,
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TravelIcons.emptyGuide(size: 80),
          const SizedBox(height: 16),
          const Text(
            '还没有攻略',
            style: TextStyle(fontSize: 18, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          const Text(
            '去 AI 对话页生成你的第一份攻略吧',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.itineraryEditor);
      },
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }

  String _getEmojiForDestination(String destination) {
    if (destination.contains('重庆')) return '🏯';
    if (destination.contains('厦门')) return '🌊';
    if (destination.contains('川西')) return '🗻';
    if (destination.contains('桂林')) return '🏞️';
    if (destination.contains('北京')) return '🏛️';
    if (destination.contains('三亚')) return '🏖️';
    if (destination.contains('西安')) return '🏺';
    return '🗺️';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '待定';
    final fmt = DateFormatUtil.monthDayShort();
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  Future<void> _confirmDeleteItinerary(BuildContext context, Itinerary itinerary) async {
    final confirmed = await showDeleteConfirmBottomSheet(
      context: context,
      title: '确定要删除这份攻略吗？',
      description: '「${itinerary.destination}」攻略将被删除。删除后无法恢复，已规划的日程、行程项等数据会一并清空。',
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<ItineraryProvider>().deleteItinerary(itinerary.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${itinerary.destination}」攻略已删除')),
    );
  }

  double _calculateProgress(Itinerary itinerary) {
    if (itinerary.status == ItineraryStatus.completed) return 1.0;
    if (itinerary.status == ItineraryStatus.planning) return 0.0;
    if (itinerary.dayPlans.isEmpty) return 0.0;
    
    int completed = 0;
    int total = itinerary.dayPlans.length;
    for (final day in itinerary.dayPlans) {
      if (day.items.every((i) => i.status == ItemStatus.completed || i.status == ItemStatus.skipped)) {
        completed++;
      }
    }
    return total > 0 ? completed / total : 0.0;
  }
}
