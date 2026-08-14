import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver2_fixed/image_gallery_saver2_fixed.dart';
import 'package:provider/provider.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../providers/itinerary_provider.dart';
import '../../models/itinerary.dart';
import '../../models/itinerary_item.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../services/database_service.dart';
import '../../services/permission_service.dart';
import '../../utils/date_format_util.dart';
import '../../widgets/disposable_sheet.dart';
import '../../services/ai_service.dart';
import '../../exceptions/missing_credential_exception.dart';
import '../../widgets/confirm_bottom_sheet.dart';
import '../../models/accommodation_info.dart';
import 'itinerary_detail_view_model.dart';
import 'widgets/execute_item_tile.dart';
import 'widgets/itinerary_hero_banner.dart';
import 'widgets/itinerary_summary_card.dart';
import 'widgets/itinerary_timeline.dart';
import 'widgets/itinerary_day_card.dart';
import 'widgets/itinerary_ui_helpers.dart';
import 'widgets/rate_sheet.dart';
/// 攻略详情页 - 编辑视图 + 执行视图
class ItineraryDetailPage extends StatefulWidget {
  final String itineraryId;
  const ItineraryDetailPage({super.key, required this.itineraryId});
  @override
  State<ItineraryDetailPage> createState() => _ItineraryDetailPageState();
}
class _ItineraryDetailPageState extends State<ItineraryDetailPage> {
  Itinerary? _itinerary;
  bool _loading = true;
  bool _notFound = false;
  bool _isExecuteMode = false;
  bool _isEditing = false;
  bool _isBuildingShare = false;
  int _currentDay = 0;

  // 编辑模式临时变量
  late TextEditingController _destController;
  late TextEditingController _budgetController;
  late int _editingPeople;
  late ItineraryStatus _editingStatus;
  late List<DayPlan> _editingDayPlans;
  DateTime? _editingStartDate;
  DateTime? _editingEndDate;
  String _editingTripType = '';

  @override
  void initState() {
    super.initState();
    _destController = TextEditingController();
    _budgetController = TextEditingController();
    _loadItinerary();
  }

  @override
  void dispose() {
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
  Future<void> _loadItinerary() async {
    final it = await DatabaseService().getItineraryById(widget.itineraryId);
    if (!mounted) return;
    if (it == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }
    setState(() {
      _itinerary = it;
      _loading = false;
      if (it.dayPlans.isNotEmpty) {
        _currentDay = _currentDay.clamp(0, it.dayPlans.length - 1);
      }
      if (it.status == ItineraryStatus.ongoing ||
          it.status == ItineraryStatus.completed) {
        _isExecuteMode = true;
        _currentDay = _getCurrentDayIndex();
      }
    });
  }

  /// P0-17：非编辑模式统一持久化
  Future<void> _persist(Itinerary next) async {
    try {
      await context.read<ItineraryProvider>().saveItinerary(next);
      if (!mounted) return;
      setState(() => _itinerary = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _destController.text = _itinerary!.destination;
      _budgetController.text = _itinerary!.totalBudget.toStringAsFixed(0);
      _editingPeople = _itinerary!.people;
      _editingStatus = _itinerary!.status;
      _editingStartDate = _itinerary!.startDate;
      _editingEndDate = _itinerary!.endDate;
      _editingTripType = _itinerary!.tripType;
      // 深拷贝 dayPlans（使用 copyWith 确保所有字段都被复制）
      _editingDayPlans = _itinerary!.dayPlans.map((d) => DayPlan(
        dayNumber: d.dayNumber,
        date: d.date,
        items: d.items.map((i) => ItineraryItem(
          time: i.time,
          emoji: i.emoji,
          title: i.title,
          cost: i.cost,
          actualCost: i.actualCost,
          note: i.note,
          rating: i.rating,
          status: i.status,
          feeling: i.feeling,
        )).toList(),
        accommodation: d.accommodation,
        dailyBudget: d.dailyBudget,
      )).toList();
    });
  }

  /// P0-12：保留仅有住宿/预算的天
  List<DayPlan> _cleanDayPlans(List<DayPlan> dayPlans, DateTime? startDate) {
    final filtered = dayPlans
        .where((d) =>
            d.items.isNotEmpty ||
            d.accommodation != null ||
            d.dailyBudget > 0)
        .toList();
    if (filtered.isEmpty && dayPlans.isNotEmpty) {
      return dayPlans;
    }
    return List.generate(filtered.length, (i) {
      final old = filtered[i];
      return DayPlan(
        dayNumber: i + 1,
        date: startDate != null ? startDate.add(Duration(days: i)) : old.date,
        items: old.items,
        accommodation: old.accommodation,
        dailyBudget: old.dailyBudget,
      );
    });
  }

  Future<void> _saveEditing() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目的地不能为空')),
      );
      return;
    }
    try {
      final budget = double.tryParse(_budgetController.text.trim()) ?? 0;
      final beforeCount = _editingDayPlans.length;
      final cleanedDayPlans = _cleanDayPlans(_editingDayPlans, _editingStartDate);
      final removedDays = beforeCount - cleanedDayPlans.length;
      // P0-11：按 id 合并执行期字段，避免下标错位
      final oldItemsById = <String, ItineraryItem>{};
      for (final day in _itinerary!.dayPlans) {
        for (final item in day.items) {
          oldItemsById[item.id] = item;
        }
      }
      for (int d = 0; d < cleanedDayPlans.length; d++) {
        final mergedItems = cleanedDayPlans[d].items.map((item) {
          final old = oldItemsById[item.id];
          if (old == null) return item;
          return item.copyWith(
            note: old.note ?? item.note,
            rating: old.rating > 0 ? old.rating : item.rating,
            actualCost: old.actualCost > 0 ? old.actualCost : item.actualCost,
            feeling: old.feeling ?? item.feeling,
            status: old.status,
          );
        }).toList();
        cleanedDayPlans[d] = DayPlan(
          dayNumber: cleanedDayPlans[d].dayNumber,
          date: cleanedDayPlans[d].date,
          items: mergedItems,
          accommodation: cleanedDayPlans[d].accommodation,
          dailyBudget: cleanedDayPlans[d].dailyBudget,
        );
      }
      final days = cleanedDayPlans.isNotEmpty ? cleanedDayPlans.length : _itinerary!.days;
      final updated = _itinerary!.copyWith(
        destination: dest,
        startDate: _editingStartDate,
        endDate: _editingEndDate,
        days: days,
        totalBudget: budget,
        people: _editingPeople,
        dayPlans: cleanedDayPlans,
        status: _editingStatus,
        tripType: _editingTripType,
      );
      await context.read<ItineraryProvider>().saveItinerary(updated);
      await _loadItinerary();
      if (!mounted) return;
      setState(() => _isEditing = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(removedDays > 0
              ? '攻略已保存，已移除 $removedDays 天空行程'
              : '攻略已保存'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  void _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: (_isEditing ? _editingStartDate : _itinerary!.startDate) != null &&
              (_isEditing ? _editingEndDate : _itinerary!.endDate) != null
          ? DateTimeRange(
              start: _isEditing ? _editingStartDate! : _itinerary!.startDate!,
              end: _isEditing ? _editingEndDate! : _itinerary!.endDate!)
          : null,
    );
    if (!mounted || result == null) return;
    if (_isEditing) {
      setState(() {
        _editingStartDate = result.start;
        _editingEndDate = result.end;
        for (int i = 0; i < _editingDayPlans.length; i++) {
          final old = _editingDayPlans[i];
          _editingDayPlans[i] = DayPlan(
            dayNumber: old.dayNumber,
            date: result.start.add(Duration(days: i)),
            items: old.items,
            accommodation: old.accommodation,
            dailyBudget: old.dailyBudget,
          );
        }
      });
    } else {
      // P0-17：非编辑模式持久化
      final updated = _itinerary!.copyWith(
        startDate: result.start,
        endDate: result.end,
        days: result.end.difference(result.start).inDays + 1,
      );
      await _persist(updated);
    }
  }

  void _addNewDay() {
    final nextDay = _editingDayPlans.isEmpty
        ? 1
        : _editingDayPlans.last.dayNumber + 1;
    setState(() {
      _editingDayPlans.add(DayPlan(dayNumber: nextDay, items: []));
    });
  }

  void _showAddItemSheet(int dayIndex) {
    _showItemSheet(dayIndex: dayIndex, isEdit: false);
  }

  void _showEditItemSheet(int dayIndex, int itemIndex, ItineraryItem item) {
    _showItemSheet(dayIndex: dayIndex, itemIndex: itemIndex, item: item, isEdit: true);
  }

  void _showItemSheet({
    required int dayIndex,
    int? itemIndex,
    ItineraryItem? item,
    required bool isEdit,
  }) {
    final timeController = TextEditingController(text: item?.time ?? '09:00');
    final titleController = TextEditingController(text: item?.title ?? '');
    final costController = TextEditingController(
        text: (item != null && item.cost > 0) ? item.cost.toStringAsFixed(0) : '');
    final noteController = TextEditingController(text: item?.note ?? '');

    showManagedModalBottomSheet(
      context: context,
      controllers: [timeController, titleController, costController, noteController],
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? '编辑行程项' : '添加行程项',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: '时间',
                    hintText: '如 09:00',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                  ),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) {
                      timeController.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    }
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '活动名称',
                    hintText: '如 洪崖洞夜游',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: '预估费用（元）',
                    hintText: '0',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '可选，最多50字',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                  ),
                  maxLength: 50,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      final cost = double.tryParse(costController.text.trim()) ?? 0;
                      setState(() {
                        final newItem = ItineraryItem(
                          time: timeController.text.trim(),
                          title: title,
                          cost: cost,
                          note: noteController.text.trim().isNotEmpty
                              ? noteController.text.trim()
                              : null,
                        );
                        if (isEdit && itemIndex != null) {
                          final old = _editingDayPlans[dayIndex].items[itemIndex];
                          _editingDayPlans[dayIndex].items[itemIndex] =
                              newItem.copyWith(
                            emoji: old.emoji,
                            actualCost: old.actualCost,
                            rating: old.rating,
                            status: old.status,
                            feeling: old.feeling,
                          );
                        } else {
                          _editingDayPlans[dayIndex].items.add(newItem);
                        }
                      });
                      FocusScope.of(ctx).unfocus();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isEdit ? '保存' : '确定',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound || _itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('攻略详情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('攻略不存在'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    if (_isExecuteMode) {
      return _buildExecuteView(top, bottom);
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 自定义头部
          _buildHeader(top),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _isEditing
                    ? ItineraryEditableHeroBanner(
                        destController: _destController,
                        budgetController: _budgetController,
                        startDate: _editingStartDate,
                        endDate: _editingEndDate,
                        people: _editingPeople,
                        status: _editingStatus,
                        tripType: _editingTripType,
                        onPickDateRange: _pickDateRange,
                        onPeopleChanged: (p) => setState(() => _editingPeople = p),
                        onStatusChanged: (s) => setState(() => _editingStatus = s),
                        onTripTypeChanged: (t) => setState(() => _editingTripType = t),
                      )
                    : ItineraryHeroBanner(itinerary: _itinerary!),
                _buildModeSwitch(),
                // 日卡片
                ...List.generate(
                  _isEditing ? _editingDayPlans.length : _itinerary!.dayPlans.length,
                  (i) => _buildDayCard(
                    _isEditing ? _editingDayPlans[i] : _itinerary!.dayPlans[i],
                    i,
                  ),
                ),
                // 添加新的一天
                _buildAddDayButton(),
                // 行程总览
                ItinerarySummaryCard(
                  itinerary: _itinerary!,
                  totalItems: _itinerary!.dayPlans
                      .fold<int>(0, (sum, d) => sum + d.items.length),
                ),
                ItineraryActionButtons(
                  status: _itinerary!.status,
                  onEnterExecute: () => setState(() => _isExecuteMode = true),
                  onConvertToDiary: _convertToDiary,
                  onShare: _shareItinerary,
                  onDelete: _confirmDeleteItinerary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(double top) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 15, 16, 12),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor, width: 1),
                color: Colors.white,
              ),
              child: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              _itinerary!.destination,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _isEditing ? _cancelEditing : null,
            child: _isEditing
                ? const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_isEditing) const SizedBox(width: 12),
          GestureDetector(
            onTap: _isEditing ? _saveEditing : _startEditing,
            child: Text(
              _isEditing ? '保存' : '编辑',
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
  Widget _buildModeSwitch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExecuteMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isExecuteMode ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 14,
                        color: !_isExecuteMode ? Colors.white : AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text('编辑视图',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_isExecuteMode ? Colors.white : AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExecuteMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isExecuteMode ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 14,
                        color: _isExecuteMode ? Colors.white : AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text('执行视图',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isExecuteMode ? Colors.white : AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDayCard(DayPlan dayPlan, int dayIndex) {
    return ItineraryDayCard(
      dayPlan: dayPlan,
      dayIndex: dayIndex,
      dayTitle: _getDayTitle(dayIndex),
      isOngoingDay: _itinerary!.status == ItineraryStatus.ongoing &&
          dayIndex == _getCurrentDayIndex(),
      isEditing: _isEditing,
      hideActions: _isBuildingShare,
      timeline: _buildTimeline(dayPlan, dayIndex),
      dayBudget: _calculateDayBudget(dayPlan),
      onAddItem: _isEditing
          ? () => _showAddItemSheet(dayIndex)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('点击右上角「编辑」后可添加行程项')),
              );
            },
      onEditAccommodation: _isEditing
          ? (acc) => _showAccommodationSheet(dayIndex, acc)
          : null,
      onAddAccommodation: () => _showAccommodationSheet(dayIndex, null),
    );
  }

  Widget _buildTimeline(DayPlan dayPlan, int dayIndex) {
    return ItineraryTimeline(
      items: dayPlan.items,
      isEditing: _isEditing,
      dayIndex: dayIndex,
      onReorder: _isEditing
          ? (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final list = sortItineraryItems(
                    List<ItineraryItem>.from(_editingDayPlans[dayIndex].items));
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                for (var i = 0; i < list.length; i++) {
                  list[i] = list[i].copyWith(sortOrder: i);
                }
                final day = _editingDayPlans[dayIndex];
                _editingDayPlans[dayIndex] = DayPlan(
                  dayNumber: day.dayNumber,
                  date: day.date,
                  items: list,
                  accommodation: day.accommodation,
                  dailyBudget: day.dailyBudget,
                );
              });
            }
          : null,
      onEditItem: (itemIndex, item) =>
          _showEditItemSheet(dayIndex, itemIndex, item),
      onDeleteItem: (itemId) => _deleteTimelineItem(dayIndex, itemId),
    );
  }

  void _deleteTimelineItem(int dayIndex, String itemId) {
    setState(() {
      final list = sortItineraryItems(
          List<ItineraryItem>.from(_editingDayPlans[dayIndex].items));
      list.removeWhere((e) => e.id == itemId);
      final day = _editingDayPlans[dayIndex];
      _editingDayPlans[dayIndex] = DayPlan(
        dayNumber: day.dayNumber,
        date: day.date,
        items: list,
        accommodation: day.accommodation,
        dailyBudget: day.dailyBudget,
      );
    });
  }

  void _showAccommodationSheet(int dayIndex, AccommodationInfo? existing) {
    final typeController = TextEditingController(text: existing?.type ?? '酒店');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final areaController = TextEditingController(text: existing?.area ?? '');
    final costController = TextEditingController(
        text: (existing != null && existing.cost > 0)
            ? existing.cost.toStringAsFixed(0)
            : '');
    String selectedType = existing?.type ?? '酒店';
    final accTypes = ['酒店', '民宿', '青旅'];

    showManagedModalBottomSheet(
      context: context,
      controllers: [typeController, nameController, areaController, costController],
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing != null ? '编辑住宿' : '添加住宿',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    const Text('住宿类型',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: accTypes.map((t) {
                        final isSelected = selectedType == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => selectedType = t);
                              typeController.text = t;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF3E0)
                                    : AppTheme.inputBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFB923C)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF9A3412)
                                        : AppTheme.textSecondary,
                                  )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        hintText: '如 全季酒店(春熙路店)',
                        filled: true,
                        fillColor: AppTheme.inputBgColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: '区域',
                        hintText: '如 春熙路商圈',
                        filled: true,
                        fillColor: AppTheme.inputBgColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costController,
                      decoration: const InputDecoration(
                        labelText: '花费（元/晚）',
                        hintText: '0',
                        filled: true,
                        fillColor: AppTheme.inputBgColor,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final area = areaController.text.trim();
                          final cost =
                              double.tryParse(costController.text.trim()) ?? 0;
                          final newAcc = existing != null
                              ? existing.copyWith(
                                  type: selectedType,
                                  name: name,
                                  area: area,
                                  cost: cost,
                                )
                              : AccommodationInfo(
                                  type: selectedType,
                                  name: name,
                                  area: area,
                                  cost: cost,
                                );
                          final plans = _isEditing
                              ? _editingDayPlans
                              : _itinerary!.dayPlans
                                  .map((d) => DayPlan(
                                        dayNumber: d.dayNumber,
                                        date: d.date,
                                        items: d.items,
                                        accommodation: d.accommodation,
                                        dailyBudget: d.dailyBudget,
                                      ))
                                  .toList();
                          plans[dayIndex] = DayPlan(
                            dayNumber: plans[dayIndex].dayNumber,
                            date: plans[dayIndex].date,
                            items: plans[dayIndex].items,
                            accommodation: newAcc,
                            dailyBudget: plans[dayIndex].dailyBudget,
                          );
                          if (dayIndex == 0) {
                            for (int i = 1; i < plans.length; i++) {
                              if (i == plans.length - 1) continue;
                              plans[i] = DayPlan(
                                dayNumber: plans[i].dayNumber,
                                date: plans[i].date,
                                items: plans[i].items,
                                accommodation: newAcc,
                                dailyBudget: plans[i].dailyBudget,
                              );
                            }
                          }
                          if (_isEditing) {
                            setState(() => _editingDayPlans = plans);
                          } else {
                            final updated =
                                _itinerary!.copyWith(dayPlans: plans);
                            await _persist(updated);
                          }
                          if (!ctx.mounted) return;
                          FocusScope.of(ctx).unfocus();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusInput),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(existing != null ? '保存' : '确定',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildAddDayButton() {
    return GestureDetector(
      onTap: _isEditing
          ? _addNewDay
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('点击右上角「编辑」后可添加新的一天')),
              );
            },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text('添加新的一天',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  // ========================
  // 执行视图
  // ========================
  Widget _buildExecuteView(double top, double bottom) {
    final dayPlans = _itinerary!.dayPlans;
    if (dayPlans.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('暂无行程', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isExecuteMode = false),
                child: const Text('返回编辑'),
              ),
            ],
          ),
        ),
      );
    }
    final currentDay = dayPlans[_currentDay];
    final completedItems = currentDay.items
        .where((i) => i.status == ItemStatus.completed || i.status == ItemStatus.skipped)
        .length;
    final totalItems = currentDay.items.length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 绿色渐变顶栏
          _buildExecuteTopBar(top, currentDay, _currentDay),
          // 进度卡片
          _buildProgressCard(completedItems, totalItems, progress),
          // 日签Tab
          _buildDayTabs(dayPlans),
          // 行程列表 + 住宿卡片
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: currentDay.items.length + 1,
              itemBuilder: (context, index) {
                if (index < currentDay.items.length) {
                  return _buildExecuteItem(currentDay.items[index], index);
                }
                // 住宿卡片（始终显示在最后）
                return _buildExecuteAccommodation(currentDay, _currentDay);
              },
            ),
          ),
          // 结束今天按钮
          _buildFinishDayButton(bottom),
        ],
      ),
    );
  }
  Widget _buildExecuteTopBar(double top, DayPlan dayPlan, int dayIndex) {
    final dateStr = dayPlan.date != null
        ? DateFormatUtil.monthDayDot().format(dayPlan.date!)
        : '';
    final totalDays = _itinerary!.dayPlans.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 导航栏
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExecuteMode = false),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              const Text('执行视图',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${dayIndex + 1}/$totalDays',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Day ${dayIndex + 1} · ${_itinerary!.status == ItineraryStatus.ongoing ? "进行中" : "待开始"}',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 2),
          Text(
            _getDayTitle(dayIndex),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('📅 $dateStr',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.9))),
              const SizedBox(width: 8),
              Text('👥 ${_itinerary!.people} 人',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.9))),
              const SizedBox(width: 8),
              Text('💰 ¥${_calculateDayBudget(dayPlan).toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildProgressCard(
      int completed, int total, double progress) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        boxShadow: UdsElevation.soft,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日进度',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Text('已完成 $completed/$total',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    ),
    );
  }
  Widget _buildDayTabs(List<DayPlan> dayPlans) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dayPlans.length,
        itemBuilder: (context, index) {
          final isSelected = _currentDay == index;
          final completed = dayPlans[index]
              .items
              .where((i) =>
                  i.status == ItemStatus.completed ||
                  i.status == ItemStatus.skipped)
              .length;
          final total = dayPlans[index].items.length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _currentDay = index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentMint : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentMint
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day ${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        completed > 0 ? '$completed/$total' : '0/$total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildExecuteItem(ItineraryItem item, int itemIndex) {
    return ExecuteItemTile(
      item: item,
      onTap: () => _showRateSheet(itemIndex),
      onToggleStatus: () =>
          _toggleItemStatus(_currentDay, itemIndex, item.status),
    );
  }

  Widget _buildFinishDayButton(double bottom) {
    final isLastDay = _currentDay >= _itinerary!.dayPlans.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 一键转日记 - 仅最后一天显示
          if (isLastDay) ...[
            GestureDetector(
              onTap: _convertToDiary,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: UdsElevation.soft,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.description_outlined,
                          size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text('一键转日记',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 结束今天 - 始终显示
          GestureDetector(
            onTap: _finishToday,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: UdsElevation.soft,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check,
                        size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Text('结束今天',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ========================
  // 执行视图住宿卡片
  // ========================
  Widget _buildExecuteAccommodation(DayPlan dayPlan, int dayIndex) {
    final acc = dayPlan.accommodation;
    if (acc == null) {
      // 无住宿信息，显示空提示
      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('🛖', style: TextStyle(fontSize: 22)),
              ),
            ),
            const Expanded(
              child: Text(
                '暂无住宿信息',
                style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showAccommodationRateSheet(dayIndex),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 住宿图标
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFB923C),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('🛖', style: TextStyle(fontSize: 22)),
              ),
            ),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          acc.name.isNotEmpty ? '住宿 · ${acc.name}' : '住宿',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (acc.cost > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFB923C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '¥${acc.cost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (acc.type.isNotEmpty || acc.area.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [if (acc.type.isNotEmpty) acc.type, if (acc.area.isNotEmpty) acc.area].join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ),
                  // 星级
                  if (acc.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Text(
                          i < acc.rating ? '★' : '☆',
                          style: TextStyle(
                            fontSize: 14,
                            color: i < acc.rating
                                ? const Color(0xFFFFB300)
                                : const Color(0xFFE5E7EB),
                          ),
                        );
                      }),
                    ),
                  ],
                  // 一句话备注
                  if (acc.feeling != null && acc.feeling!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFFFB74D), width: 2),
                        ),
                      ),
                      child: Text(
                        '💬 ${acc.feeling}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 右侧快评提示
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFB923C)),
          ],
        ),
      ),
    );
  }

  void _showAccommodationRateSheet(int dayIndex) {
    final acc = _itinerary!.dayPlans[dayIndex].accommodation;
    if (acc == null) return;
    showAccommodationRateSheet(
      context: context,
      accommodation: acc,
      onSave: (result) => _saveAccommodationRate(
        dayIndex,
        result.rating,
        result.feeling,
        result.actualCost,
      ),
    );
  }

  Future<void> _saveAccommodationRate(
      int dayIndex, double rating, String feeling, double actualCost) async {
    final dayPlans = List<DayPlan>.from(_itinerary!.dayPlans);
    final acc = dayPlans[dayIndex].accommodation;
    if (acc == null) return;
    final updatedAcc = acc.copyWith(
      rating: rating,
      feeling: feeling.isEmpty ? null : feeling,
      actualCost: actualCost,
    );
    dayPlans[dayIndex] = DayPlan(
      dayNumber: dayPlans[dayIndex].dayNumber,
      date: dayPlans[dayIndex].date,
      items: dayPlans[dayIndex].items,
      accommodation: updatedAcc,
      dailyBudget: dayPlans[dayIndex].dailyBudget,
    );
    final updated = _itinerary!.copyWith(dayPlans: dayPlans);
    // BugFix: 先持久化再 setState，避免 sheet 关闭期间触发父组件重建
    await context.read<ItineraryProvider>().saveItinerary(updated);
    if (!mounted) return;
    setState(() => _itinerary = updated);
  }

  // ========================
  // 快评浮层
  // ========================
  void _showRateSheet(int itemIndex) {
    final item = _itinerary!.dayPlans[_currentDay].items[itemIndex];
    showItemRateSheet(
      context: context,
      item: item,
      dayNumber: _currentDay + 1,
      onSave: (result) => _saveRate(
        itemIndex,
        result.rating,
        result.feeling,
        result.status ?? item.status,
        result.actualCost,
        result.quickTags,
      ),
    );
  }

  // ========================
  // 操作
  // ========================

  /// 检查并自动更新攻略状态
  Future<void> _checkAndUpdateItineraryStatus(Itinerary itinerary) async {
    ItineraryStatus newStatus = itinerary.status;
    final allDayPlans = itinerary.dayPlans;

    if (allDayPlans.isNotEmpty &&
        allDayPlans.every((d) =>
            d.items.isEmpty ||
            d.items.every((i) =>
                i.status == ItemStatus.completed ||
                i.status == ItemStatus.skipped))) {
      newStatus = ItineraryStatus.completed;
    } else if (itinerary.status == ItineraryStatus.planning &&
        allDayPlans.any((d) => d.items.any((i) =>
            i.status == ItemStatus.completed ||
            i.status == ItemStatus.skipped))) {
      newStatus = ItineraryStatus.ongoing;
    }

    if (newStatus != itinerary.status) {
      final updated = itinerary.copyWith(status: newStatus);
      if (!mounted) return;
      setState(() => _itinerary = updated);
      await context.read<ItineraryProvider>().saveItinerary(updated);
    }
  }

  Future<void> _toggleItemStatus(
      int dayIndex, int itemIndex, ItemStatus currentStatus) async {
    final dayPlans = List<DayPlan>.from(_itinerary!.dayPlans);
    final items = List<ItineraryItem>.from(dayPlans[dayIndex].items);
    // P0-16：三态切换 pending → completed → pending；skipped → pending
    final ItemStatus newStatus;
    switch (currentStatus) {
      case ItemStatus.pending:
        newStatus = ItemStatus.completed;
      case ItemStatus.completed:
        newStatus = ItemStatus.pending;
      case ItemStatus.skipped:
        newStatus = ItemStatus.pending;
    }
    items[itemIndex] = items[itemIndex].copyWith(status: newStatus);
    dayPlans[dayIndex] = DayPlan(
      dayNumber: dayPlans[dayIndex].dayNumber,
      date: dayPlans[dayIndex].date,
      items: items,
      accommodation: dayPlans[dayIndex].accommodation,
      dailyBudget: dayPlans[dayIndex].dailyBudget,
    );
    ItineraryStatus status = _itinerary!.status;
    if (newStatus == ItemStatus.completed && status == ItineraryStatus.planning) {
      status = ItineraryStatus.ongoing;
    }
    final updated = _itinerary!.copyWith(dayPlans: dayPlans, status: status);
    setState(() => _itinerary = updated);
    await context.read<ItineraryProvider>().saveItinerary(updated);
    if (!mounted) return;
    await _checkAndUpdateItineraryStatus(updated);
  }
  Future<void> _saveRate(int itemIndex, double rating, String feeling,
      ItemStatus status, double actualCost, List<String> quickTags) async {
    final dayPlans = List<DayPlan>.from(_itinerary!.dayPlans);
    final items = List<ItineraryItem>.from(dayPlans[_currentDay].items);
    items[itemIndex] = items[itemIndex].copyWith(
      rating: rating,
      feeling: feeling.isEmpty ? null : feeling,
      status: status,
      actualCost: actualCost,
      quickTags: quickTags, // P1-2.4
    );
    dayPlans[_currentDay] = DayPlan(
      dayNumber: dayPlans[_currentDay].dayNumber,
      date: dayPlans[_currentDay].date,
      items: items,
      accommodation: dayPlans[_currentDay].accommodation,
      dailyBudget: dayPlans[_currentDay].dailyBudget,
    );
    ItineraryStatus itStatus = _itinerary!.status;
    if ((status == ItemStatus.completed || status == ItemStatus.skipped) &&
        itStatus == ItineraryStatus.planning) {
      itStatus = ItineraryStatus.ongoing;
    }
    final updated = _itinerary!.copyWith(dayPlans: dayPlans, status: itStatus);
    // BugFix: 先持久化再 setState，避免 sheet 关闭期间触发 _dependents.isEmpty
    await context.read<ItineraryProvider>().saveItineraryWithRating(updated);
    if (!mounted) return;
    setState(() => _itinerary = updated);
    await _checkAndUpdateItineraryStatus(updated);
  }

  Future<void> _finishToday() async {
    final isLastDay = _currentDay >= _itinerary!.dayPlans.length - 1;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: UdsColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 32, color: Color(0xFF2196F3)),
              ),
              const SizedBox(height: 16),
              const Text(
                '结束今天',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '将 Day ${_currentDay + 1} 的所有待处理行程标记为「已完成」？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.borderColor, width: 1),
                        ),
                        child: const Center(
                          child: Text('取消',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: UdsElevation.soft,
                        ),
                        child: const Center(
                          child: Text('确认',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final dayPlans = List<DayPlan>.from(_itinerary!.dayPlans);
    final items = List<ItineraryItem>.from(dayPlans[_currentDay].items);
    for (int i = 0; i < items.length; i++) {
      if (items[i].status == ItemStatus.pending) {
        items[i] = items[i].copyWith(status: ItemStatus.completed);
      }
    }
    dayPlans[_currentDay] = DayPlan(
      dayNumber: dayPlans[_currentDay].dayNumber,
      date: dayPlans[_currentDay].date,
      items: items,
      accommodation: dayPlans[_currentDay].accommodation,
      dailyBudget: dayPlans[_currentDay].dailyBudget,
    );
    final updated = _itinerary!.copyWith(
      dayPlans: dayPlans,
      status: _itinerary!.status == ItineraryStatus.planning
          ? ItineraryStatus.ongoing
          : _itinerary!.status,
    );
    setState(() => _itinerary = updated);
    await context.read<ItineraryProvider>().saveItinerary(updated);
    await _checkAndUpdateItineraryStatus(updated);
    if (!mounted) return;
    if (isLastDay) {
      // 最后一天：弹窗提示是否转日记
      final toDiary = await showModalBottomSheet<bool>(
        context: context,
        barrierColor: UdsColors.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration_outlined,
                      size: 32, color: Color(0xFFFF9800)),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🎉 旅程结束',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Day ${_currentDay + 1} 已结束！是否将攻略转为旅行日记？',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.borderColor, width: 1),
                          ),
                          child: const Center(
                            child: Text('稍后再说',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: UdsElevation.soft,
                          ),
                          child: const Center(
                            child: Text('转为日记',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (toDiary == true && mounted) {
        _convertToDiary();
      }
    } else {
      // 非最后一天：跳转下一天
      setState(() => _currentDay += 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day $_currentDay 已结束，自动跳转 Day ${_currentDay + 1}')),
      );
    }
  }
  Future<void> _convertToDiary() async {
    final totalItems = _itinerary!.dayPlans.fold<int>(0,
        (sum, day) => sum + day.items.length);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: UdsColors.scrim,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined,
                    size: 32, color: Color(0xFFFF9800)),
              ),
              const SizedBox(height: 16),
              const Text(
                '转为旅行日记？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '系统会自动带入以下内容，你可以在日记编辑器中继续补充文字和照片。',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _checkItem('行程结构（${_itinerary!.days} 天 $totalItems 项）'),
                    const SizedBox(height: 10),
                    _checkItem('旅途评分与备注'),
                    const SizedBox(height: 10),
                    _checkItem('花费与时间数据'),
                    const SizedBox(height: 10),
                    _checkItem('基本信息（目的地 / 人数 / 日期）'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.borderColor, width: 1),
                        ),
                        child: const Center(
                          child: Text('再等等',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: UdsElevation.soft,
                        ),
                        child: const Center(
                          child: Text('确认转日记',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    // P1-2.5：统一流水账生成
    final itineraryItems = ItineraryDetailViewModel.buildItineraryDigest(_itinerary!);
    final meta = ItineraryDetailViewModel.computeDiaryMeta(_itinerary!);
    final totalActualCost = meta.totalActualCost;
    final avgRating = meta.avgRating;
    if (!mounted) return;
    var loadingOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    void closeLoading() {
      if (loadingOpen && mounted) {
        Navigator.pop(context);
        loadingOpen = false;
      }
    }
    // P0-8：60s 超时自动关闭 loading
    Future.delayed(const Duration(seconds: 60), () {
      if (loadingOpen && mounted) {
        closeLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('转换超时，请稍后重试')),
        );
      }
    });
    try {
      final ai = AiService();
      final dateFmt = DateFormatUtil.monthDay();
      final dateRange =
          _itinerary!.startDate != null && _itinerary!.endDate != null
              ? '${dateFmt.format(_itinerary!.startDate!)} - ${dateFmt.format(_itinerary!.endDate!)}'
              : '';
      final draft = await ai.generateDiaryFromItinerary(
        itineraryItems: itineraryItems,
        destination: _itinerary!.destination,
        dateRange: dateRange,
        people: _itinerary!.people,
      );
      if (!mounted) return;
      closeLoading();
      Navigator.pop(context);
      Navigator.pushNamed(context, AppRoutes.diaryEditor, arguments: {
        'itineraryId': _itinerary!.id,
        'initialContent': draft,
        'destination': _itinerary!.destination,
        'startDate': _itinerary!.startDate,
        'endDate': _itinerary!.endDate,
        'people': _itinerary!.people,
        'tripType': _itinerary!.tripType,
        'totalCost': totalActualCost,
        'rating': avgRating,
      });
    } on MissingCredentialException catch (e) {
      if (!mounted) return;
      closeLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      Navigator.pushNamed(context, AppRoutes.apiSettings);
    } catch (e) {
      if (!mounted) return;
      closeLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转换失败：$e')),
      );
    }
  }
  // ========================
  // 分享攻略
  // ========================
  Future<void> _shareItinerary() async {
    if (!mounted) return;
    // P0-20：保存前申请相册权限
    final permitted = await PermissionService().ensureGallerySavePermission();
    if (!permitted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限才能保存图片，请在系统设置中授权')),
      );
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在生成攻略图片…'),
          duration: Duration(seconds: 2),
        ),
      );

      // 使用 OverlayEntry 渲染完整内容以截取全图
      final shareKey = GlobalKey();
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: shareKey,
            child: _buildShareWidget(),
          ),
        ),
      );
      Overlay.of(context).insert(entry);

      // 等待渲染完成
      await Future.delayed(const Duration(milliseconds: 600));

      final boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成图片失败')),
        );
        return;
      }
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(
        pixelRatio: math.min(2.0, dpr),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      entry.remove();

      if (byteData == null || !mounted) return;
      final pngBytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 95,
        name: '攻略_${_itinerary!.destination}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      final bool success = result['isSuccess'] == true;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '攻略图片已保存到相册 🎉'
              : '保存失败，请检查存储权限'),
          backgroundColor: success ? AppTheme.accentMint : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成图片失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 构建用于分享的完整攻略视图（Day1 到最后一天）
  Widget _buildShareWidget() {
    _isBuildingShare = true;
    final dayPlans = _itinerary!.dayPlans;
    final widget = Container(
      width: 375,
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 攻略标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Text(
                  '${ItineraryUiHelpers.emojiForDestination(_itinerary!.destination)} ${_itinerary!.destination}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ItineraryUiHelpers.formatDateRange(_itinerary!.startDate, _itinerary!.endDate)} · ${_itinerary!.people}人 · ${_itinerary!.tripType}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 所有日卡片
          ...dayPlans.asMap().entries.map(
            (entry) => _buildDayCard(entry.value, entry.key),
          ),
        ],
      ),
    );
    _isBuildingShare = false;
    return widget;
  }

  // ========================
  // 删除攻略
  // ========================
  Future<void> _confirmDeleteItinerary() async {
    final confirmed = await showDeleteConfirmBottomSheet(
      context: context,
      title: '删除攻略',
      description: '确定要删除「${_itinerary!.destination}」攻略吗？此操作无法撤销。',
    );
    if (confirmed != true || !mounted) return;
    await context.read<ItineraryProvider>().deleteItinerary(_itinerary!.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${_itinerary!.destination}」攻略已删除')),
      );
    }
  }

  // ========================
  // 辅助方法
  // ========================
  Widget _checkItem(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check,
              size: 14, color: Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  String _getDayTitle(int index) {
    return 'Day ${index + 1}';
  }
  int _getCurrentDayIndex() {
    if (_itinerary == null || _itinerary!.dayPlans.isEmpty) return 0;
    final plans = _itinerary!.dayPlans;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // P0-18：优先返回首个 date >= today 的索引
    for (int i = 0; i < plans.length; i++) {
      final date = plans[i].date;
      if (date != null) {
        final d = DateTime(date.year, date.month, date.day);
        if (!d.isBefore(todayDate)) return i.clamp(0, plans.length - 1);
      }
    }

    // 全部早于 today：返回最后一天
    final allDatesPast = plans.every((d) {
      if (d.date == null) return false;
      final dd = DateTime(d.date!.year, d.date!.month, d.date!.day);
      return dd.isBefore(todayDate);
    });
    if (allDatesPast && plans.any((d) => d.date != null)) {
      return (plans.length - 1).clamp(0, plans.length - 1);
    }

    // date 全为 null：返回首个存在未完成项的天
    for (int i = 0; i < plans.length; i++) {
      if (plans[i].items.any((it) => it.status == ItemStatus.pending)) {
        return i.clamp(0, plans.length - 1);
      }
    }
    return 0;
  }
  double _calculateDayBudget(DayPlan dayPlan) {
    double total = dayPlan.items.fold<double>(
        0, (sum, item) => sum + item.cost);
    if (dayPlan.accommodation != null && dayPlan.accommodation!.cost > 0) {
      total += dayPlan.accommodation!.cost;
    }
    return total;
  }
}
