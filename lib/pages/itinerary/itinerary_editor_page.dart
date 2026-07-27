import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../utils/date_format_util.dart';
import '../../app/theme.dart';
import '../../models/itinerary.dart';
import '../../models/itinerary_item.dart';
import '../../models/travel_record.dart' show kTripTypes;
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/disposable_sheet.dart';

/// 新建/编辑攻略页面
class ItineraryEditorPage extends StatefulWidget {
  final String? itineraryId; // 非空时为编辑模式

  const ItineraryEditorPage({super.key, this.itineraryId});

  @override
  State<ItineraryEditorPage> createState() => _ItineraryEditorPageState();
}

class _ItineraryEditorPageState extends State<ItineraryEditorPage> {
  final _uuid = const Uuid();
  final _destController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _people = 2;
  ItineraryStatus _status = ItineraryStatus.planning;
  String _tripType = '';
  List<DayPlan> _dayPlans = [];
  bool _isLoading = false;
  bool _pageLoading = false;
  bool _notFound = false;
  Itinerary? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.itineraryId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _pageLoading = true);
    final it = await DatabaseService().getItineraryById(widget.itineraryId!);
    if (!mounted) return;
    if (it == null) {
      setState(() {
        _pageLoading = false;
        _notFound = true;
      });
      return;
    }
    setState(() {
      _existing = it;
      _destController.text = it.destination;
      _budgetController.text = it.totalBudget.toStringAsFixed(0);
      _startDate = it.startDate;
      _endDate = it.endDate;
      _people = it.people;
      _status = it.status;
      _tripType = it.tripType;
      // P0-13：直接复用原对象，保留 actualCost / feeling 等执行期字段
      _dayPlans = it.dayPlans
          .map((d) => DayPlan(
                dayNumber: d.dayNumber,
                date: d.date,
                items: List<ItineraryItem>.from(d.items),
                accommodation: d.accommodation,
                dailyBudget: d.dailyBudget,
              ))
          .toList();
      _pageLoading = false;
    });
  }

  @override
  void dispose() {
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _addDay() {
    final nextNum = _dayPlans.isEmpty ? 1 : _dayPlans.last.dayNumber + 1;
    DateTime? date;
    if (_startDate != null) {
      date = _startDate!.add(Duration(days: nextNum - 1));
    }
    setState(() {
      _dayPlans.add(DayPlan(dayNumber: nextNum, date: date, items: []));
    });
  }

  void _removeDay(int index) {
    setState(() => _dayPlans.removeAt(index));
  }

  void _showAddItemSheet(int dayIndex) {
    final timeController = TextEditingController(text: '09:00');
    final titleController = TextEditingController();
    final costController = TextEditingController();
    final noteController = TextEditingController();

    showManagedModalBottomSheet(
      context: context,
      controllers: [timeController, titleController, costController, noteController],
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
              const Text('添加行程项',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                  if (t != null) {
                    timeController.text =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: '时间',
                      filled: true,
                      fillColor: AppTheme.inputBgColor,
                    ),
                  ),
                ),
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
                  filled: true,
                  fillColor: AppTheme.inputBgColor,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  filled: true,
                  fillColor: AppTheme.inputBgColor,
                ),
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
                      _dayPlans[dayIndex].items.add(ItineraryItem(
                        time: timeController.text.trim(),
                        title: title,
                        cost: cost,
                        note: noteController.text.trim().isNotEmpty
                            ? noteController.text.trim() : null,
                      ));
                    });
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
                  child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// P0-12：保留仅有住宿/预算的天，避免静默删除整天行程
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

  Future<void> _save() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写目的地')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final budget = double.tryParse(_budgetController.text.trim()) ?? 0;
      final provider = context.read<AppProvider>();
      final beforeCount = _dayPlans.length;
      final cleanedDayPlans = _cleanDayPlans(_dayPlans, _startDate);
      final removedDays = beforeCount - cleanedDayPlans.length;
      final days = cleanedDayPlans.isNotEmpty
          ? cleanedDayPlans.length
          : (_startDate != null && _endDate != null
              ? _endDate!.difference(_startDate!).inDays + 1
              : 1);

      final itinerary = Itinerary(
        id: _existing?.id ?? _uuid.v4(),
        destination: dest,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        totalBudget: budget,
        people: _people,
        rawContent: _existing?.rawContent ?? '',
        dayPlans: cleanedDayPlans,
        sourceChatId: _existing?.sourceChatId,
        tripType: _tripType,
        createdAt: _existing?.createdAt,
      );

      await provider.saveItinerary(itinerary);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(removedDays > 0
              ? '「$dest」攻略已保存！已移除 $removedDays 天空行程'
              : '「$dest」攻略已保存！'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pageLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑攻略')),
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
    final isEdit = widget.itineraryId != null && _existing != null;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? '编辑攻略' : '新建攻略',
          style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: _isLoading ? AppTheme.textTertiary : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          // 基本信息卡片
          _buildInfoCard(),
          const SizedBox(height: 14),
          // 日程列表
          _buildDayPlansSection(),
          // 添加日程按钮
          _buildAddDayButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final dateRange = _startDate != null && _endDate != null
        ? '${DateFormatUtil.monthDayShort().format(_startDate!)} - ${DateFormatUtil.monthDayShort().format(_endDate!)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基本信息',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          // 目的地
          TextField(
            controller: _destController,
            decoration: const InputDecoration(
              labelText: '目的地',
              hintText: '如 成都、桂林、三亚',
              filled: true,
              fillColor: AppTheme.inputBgColor,
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          // 日期
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.inputBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dateRange ?? '点击选择出行日期',
                      style: TextStyle(
                        fontSize: 14,
                        color: dateRange != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                  if (dateRange != null)
                    GestureDetector(
                      onTap: () => setState(() { _startDate = null; _endDate = null; }),
                      child: const Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 人数 + 预算
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('出行人数',
                        style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _countBtn(Icons.remove, () {
                          if (_people > 1) setState(() => _people--);
                        }),
                        const SizedBox(width: 10),
                        Text('$_people 人',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(width: 10),
                        _countBtn(Icons.add, () {
                          setState(() => _people++);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: '总预算（元）',
                    prefixText: '¥ ',
                    filled: true,
                    fillColor: AppTheme.inputBgColor,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 状态
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.inputBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ItineraryStatus>(
                value: _status,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, size: 20, color: AppTheme.textSecondary),
                items: ItineraryStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 旅行类型
          const Text('旅行类型',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kTripTypes.map((type) {
              final isSelected = _tripType == type;
              return GestureDetector(
                onTap: () => setState(() => _tripType = isSelected ? '' : type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_getEmojiForTripType(type)} $type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPlansSection() {
    if (_dayPlans.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.borderColor, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, size: 40, color: AppTheme.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 10),
            const Text('暂无日程安排',
                style: TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
            const SizedBox(height: 6),
            const Text('点击下方按钮添加日程',
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_dayPlans.length, (i) => _buildDayCard(i)),
    );
  }

  Widget _buildDayCard(int index) {
    final day = _dayPlans[index];
    final dateStr = day.date != null
        ? DateFormatUtil.monthDayWeekday().format(day.date!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('D${day.dayNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('第 ${day.dayNumber} 天',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                  ],
                ),
              ),
              // 删除当天
              GestureDetector(
                onTap: () => _removeDay(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 行程项列表
          ...day.items.asMap().entries.map((entry) {
            final ii = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(item.time,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                  ),
                  Expanded(
                    child: Text(
                      '${item.emoji.isNotEmpty ? "${item.emoji} " : ""}${item.title}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  if (item.cost > 0)
                    Text('¥${item.cost.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => _dayPlans[index].items.removeAt(ii));
                    },
                    child: const Icon(Icons.close, size: 14, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            );
          }),
          // 添加行程项按钮
          GestureDetector(
            onTap: () => _showAddItemSheet(index),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 5),
                  Text('添加行程项', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDayButton() {
    return GestureDetector(
      onTap: _addDay,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text('添加新的一天',
                style: TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textSecondary),
      ),
    );
  }

  String _getEmojiForTripType(String type) {
    switch (type) {
      case '自然风景': return '🏞️';
      case '海岛度假': return '🏖️';
      case '人文古迹': return '🏛️';
      case '美食之旅': return '🌶️';
      case '城市漫步': return '🏙️';
      case '自驾游': return '🚗';
      default: return '🧳';
    }
  }
}
