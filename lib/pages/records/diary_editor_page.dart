import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/travel_record.dart';
import '../../services/database_service.dart';
import '../../services/media_service.dart';
import '../../app/theme.dart';

/// 日记编辑器 - 支持图文混排 + 选择式标签
class DiaryEditorPage extends StatefulWidget {
  final String? recordId;
  final String? itineraryId;
  final String? initialContent;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? people;
  final String? tripType;
  final double? initialTotalCost;
  final double? initialRating;

  const DiaryEditorPage({
    super.key,
    this.recordId,
    this.itineraryId,
    this.initialContent,
    this.destination,
    this.startDate,
    this.endDate,
    this.people,
    this.tripType,
    this.initialTotalCost,
    this.initialRating,
  });

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _media = MediaService();

  String _destination = '';
  late TextEditingController _destController;
  DateTime? _startDate;
  DateTime? _endDate;
  int _people = 2;
  final Set<String> _tripTypes = {};
  final Set<String> _transportTypes = {};
  double _totalCost = 0;
  double _rating = 0;
  String? _coverImagePath;
  String _documentsPath = '';

  List<Map<String, dynamic>> _contentBlocks = [];
  final Map<int, TextEditingController> _textControllers = {};

  bool _showOptionalFields = false;
  bool _saving = false;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final docs = await getApplicationDocumentsDirectory();
    _documentsPath = docs.path;

    if (widget.recordId != null) {
      // P0-7：直接查库，兼容隐藏记录
      final record =
          await DatabaseService().getRecordById(widget.recordId!);
      if (record == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _notFound = true;
          });
        }
        return;
      }
      _destination = record.destination;
      _startDate = record.startDate;
      _endDate = record.endDate;
      _people = record.people;
      _tripTypes.addAll(record.tripType.split(',').where((s) => s.isNotEmpty));
      _transportTypes
          .addAll(record.transportType.split(',').where((s) => s.isNotEmpty));
      _totalCost = record.totalCost;
      _rating = record.rating;
      _coverImagePath = record.coverImagePath;
      try {
        _contentBlocks =
            List<Map<String, dynamic>>.from(jsonDecode(record.content));
      } catch (_) {
        _contentBlocks = [];
      }
    } else if (widget.initialContent != null) {
      _addTextBlock(widget.initialContent!);
    }

    // 从攻略转换时自动填充基本信息
    if (widget.itineraryId != null && widget.recordId == null) {
      if (widget.destination != null) _destination = widget.destination!;
      if (widget.startDate != null) _startDate = widget.startDate;
      if (widget.endDate != null) _endDate = widget.endDate;
      if (widget.people != null) _people = widget.people!;
      if (widget.tripType != null && widget.tripType!.isNotEmpty) {
        _tripTypes.addAll(widget.tripType!.split(',').where((s) => s.isNotEmpty));
      }
      // 从攻略带入花费和评分
      if (widget.initialTotalCost != null && widget.initialTotalCost! > 0) {
        _totalCost = widget.initialTotalCost!;
        _showOptionalFields = true;
      }
      if (widget.initialRating != null && widget.initialRating! > 0) {
        _rating = widget.initialRating!;
        _showOptionalFields = true;
      }
    }

    if (_contentBlocks.isEmpty) _addTextBlock('');
    _destController = TextEditingController(text: _destination);
    _initControllers();
    if (mounted) setState(() => _loading = false);
  }

  void _initControllers() {
    for (int i = 0; i < _contentBlocks.length; i++) {
      if (_contentBlocks[i]['type'] == 'text') {
        _textControllers[i] =
            TextEditingController(text: _contentBlocks[i]['data'] as String?);
      }
    }
  }

  void _addTextBlock(String text) {
    final index = _contentBlocks.length;
    _contentBlocks.add({'type': 'text', 'data': text});
    _textControllers[index] = TextEditingController(text: text);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        _syncTextBlocks();
        for (final image in images) {
          // P0-1：持久化到应用私有目录，存相对路径
          final relativePath = await _media.persistImage(image);
          _contentBlocks.add({'type': 'image', 'path': relativePath});
        }
        _addTextBlock('');
        setState(() {});
      }
    } else {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        _syncTextBlocks();
        final relativePath = await _media.persistImage(image);
        _contentBlocks.add({'type': 'image', 'path': relativePath});
        _addTextBlock('');
        setState(() {});
      }
    }
  }

  void _syncTextBlocks() {
    _textControllers.forEach((index, controller) {
      if (index < _contentBlocks.length) {
        _contentBlocks[index]['data'] = controller.text;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      _syncTextBlocks();
      _destination = _destController.text.trim();
      if (_destination.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写目的地')),
        );
        return;
      }

      final summaryText = _contentBlocks
          .where((b) => b['type'] == 'text')
          .map((b) => b['data'] as String)
          .join('');
      final record = TravelRecord(
        id: widget.recordId ?? _uuid.v4(),
        destination: _destination,
        startDate: _startDate,
        endDate: _endDate,
        people: _people,
        tripType: _tripTypes.join(','),
        transportType: _transportTypes.join(','),
        content: jsonEncode(_contentBlocks),
        coverImagePath: _coverImagePath ??
            _contentBlocks
                .where((b) => b['type'] == 'image')
                .map((b) => b['path'] as String)
                .firstWhere((_) => true, orElse: () => ''),
        summary: summaryText.length > 100
            ? summaryText.substring(0, 100)
            : summaryText,
        totalCost: _totalCost,
        rating: _rating,
      );

      await context.read<AppProvider>().saveRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('日记已保存！')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    if (!_loading && !_notFound) {
      _destController.dispose();
    }
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // P0-7：加载中与记录不存在空态
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑日记')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('记录不存在'),
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // 自定义头部
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFormGroup(
                  icon: Icons.location_on_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  label: '目的地',
                  child: _buildDestinationInput(),
                ),
                const SizedBox(height: 16),
                _buildFormGroup(
                  icon: Icons.calendar_today_outlined,
                  iconBg: const Color(0xFFE3F2FD),
                  label: '出行日期',
                  child: _buildDateRangePicker(),
                ),
                const SizedBox(height: 16),
                _buildFormGroup(
                  icon: Icons.people_outline,
                  iconBg: const Color(0xFFE8F5E9),
                  label: '出行人数',
                  child: _buildPeopleSelector(),
                ),
                const SizedBox(height: 16),
                _buildFormGroup(
                  icon: Icons.label_outline,
                  iconBg: const Color(0xFFFCE4EC),
                  label: '旅行类型',
                  child: _buildTripTypeSelector(),
                ),
                const SizedBox(height: 16),
                _buildFormGroup(
                  icon: Icons.directions_car_outlined,
                  iconBg: const Color(0xFFE3F2FD),
                  label: '交通方式',
                  child: _buildTransportSelector(),
                ),
                const SizedBox(height: 16),
                _buildOptionalSection(),
                const SizedBox(height: 16),
                // 图文内容区
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildContentBlocks(),
                  ),
                ),
                const SizedBox(height: 16),
                // 插入图片按钮
                Center(
                  child: GestureDetector(
                    onTap: () => _showImagePickerOptions(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_outlined,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text(
                            '插入图片',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 10),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppTheme.borderColor, width: 0.8),
              ),
              child: const Center(
                child:
                    Icon(Icons.arrow_back_ios, size: 18, color: AppTheme.textPrimary),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              '编辑日记',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Text(
              _saving ? '保存中...' : '保存',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _saving ? AppTheme.textTertiary : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 表单分组卡片
  Widget _buildFormGroup({
    required IconData icon,
    required Color iconBg,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签头
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDestinationInput() {
    return TextField(
      controller: _destController,
      decoration: const InputDecoration(hintText: '输入目的地名称'),
      onChanged: (value) => _destination = value,
    );
  }

  Widget _buildDateRangePicker() {
    final hasDate = _startDate != null && _endDate != null;
    final dateStr = hasDate
        ? '${DateFormat('yyyy/M/d').format(_startDate!)} ~ ${DateFormat('yyyy/M/d').format(_endDate!)}'
        : '点击选择出行日期';
    return InkWell(
      onTap: () async {
        final result = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: hasDate
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
        );
        if (result != null) {
          setState(() {
            _startDate = result.start;
            _endDate = result.end;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 18,
                color: hasDate ? AppTheme.primaryColor : AppTheme.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(
                  color: hasDate ? AppTheme.textPrimary : AppTheme.textTertiary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('同行人数',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary)),
          const Spacer(),
          _circleButton(Icons.remove, _people > 1
              ? () => setState(() => _people--)
              : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_people',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _circleButton(Icons.add, () => setState(() => _people++)),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 0.8),
        ),
        child: Center(
          child: Icon(icon,
              size: 16,
              color: onTap != null
                  ? AppTheme.textPrimary
                  : AppTheme.textTertiary),
        ),
      ),
    );
  }

  Widget _buildTripTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kTripTypes.map((type) {
        final isSelected = _tripTypes.contains(type);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _tripTypes.remove(type);
              } else {
                _tripTypes.add(type);
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFFE3F2FD) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.borderColor,
                width: 0.8,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransportSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kTransportTypes.map((type) {
        final isSelected = _transportTypes.contains(type);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _transportTypes.remove(type);
              } else {
                _transportTypes.add(type);
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFFE3F2FD) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.borderColor,
                width: 0.8,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showOptionalFields = !_showOptionalFields),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(Icons.edit_note,
                        size: 14, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '补充信息',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '可选',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textTertiary),
                ),
                const Spacer(),
                Icon(
                  _showOptionalFields
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
          if (_showOptionalFields) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.inputBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('总花费',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(
                    _totalCost > 0
                        ? _totalCost.toStringAsFixed(0)
                        : '0',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.inputBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('综合评分',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const Spacer(),
                  ...List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _rating = (i + 1).toDouble()),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildContentBlocks() {
    final widgets = <Widget>[];
    int blockIndex = 0;

    for (int i = 0; i < _contentBlocks.length; i++) {
      final block = _contentBlocks[i];

      if (block['type'] == 'text') {
        final controller = _textControllers[i];
        if (controller != null) {
          widgets.add(
            TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: blockIndex == 0
                    ? '记录旅途见闻、心得体会...'
                    : '继续写...',
                hintStyle: const TextStyle(
                    color: Color(0xFF757575), fontSize: 15),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                  fontSize: 15, height: 1.55, color: Color(0xFF757575)),
            ),
          );
          blockIndex++;
        }
      } else if (block['type'] == 'image') {
        final path = block['path'] as String;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_media.resolveMediaPathSync(
                        path, _documentsPath)),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    // P0-1：旧路径失效时占位，不崩溃
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      // P0-9：删除前先同步正文，再清理文件
                      _syncTextBlocks();
                      final removedPath = path;
                      setState(() {
                        _contentBlocks.removeAt(i);
                        if (_coverImagePath == removedPath) {
                          _coverImagePath = null;
                        }
                        _mergeAdjacentTextBlocks();
                        _reindexControllers();
                      });
                      await _media.deleteMedia(removedPath);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _coverImagePath = path),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _coverImagePath == path
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text('封面',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _pickerOption(Icons.camera_alt, '拍照', () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              }),
              _pickerOption(Icons.photo_library, '相册', () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.inputBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
                child: Icon(icon, size: 24, color: AppTheme.primaryColor)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  /// P0-9：合并相邻 text block，避免删图后出现连续空输入框
  void _mergeAdjacentTextBlocks() {
    final merged = <Map<String, dynamic>>[];
    for (final block in _contentBlocks) {
      if (block['type'] == 'text' &&
          merged.isNotEmpty &&
          merged.last['type'] == 'text') {
        merged.last['data'] =
            '${merged.last['data'] ?? ''}${block['data'] ?? ''}';
      } else {
        merged.add(Map<String, dynamic>.from(block));
      }
    }
    _contentBlocks = merged;
  }

  void _reindexControllers() {
    // P0-9：先 dispose 旧控制器再重建
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    for (int i = 0; i < _contentBlocks.length; i++) {
      if (_contentBlocks[i]['type'] == 'text') {
        _textControllers[i] = TextEditingController(
          text: _contentBlocks[i]['data'] as String?,
        );
      }
    }
  }
}
