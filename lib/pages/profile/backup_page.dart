import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_design_system/ui_design_system.dart';
import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/error_mapper.dart';
import '../../services/backup_service.dart';

/// 数据备份与恢复页面
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _backup = BackupService();
  Map<String, dynamic>? _summary;
  bool _exporting = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final s = await _backup.getDataSummary();
    if (mounted) setState(() => _summary = s);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final path = await _backup.exportToFile();
      await Share.shareXFiles([XFile(path)], text: '旅行搭子数据备份');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份已导出')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showUdsConfirmSheet(
      context: context,
      title: '从备份恢复',
      description:
          '导入将覆盖同 ID 的记录与攻略。建议在导入前先导出当前数据作为安全备份。',
      confirmText: '确认导入',
      confirmColor: UdsColors.warning,
    );
    if (confirmed != true || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _importing = true);
    try {
      final json = await File(result.files.single.path!).readAsString();
      final importResult = await _backup.importFromJson(json);
      if (!mounted) return;

      final msg = StringBuffer(
        '导入完成：${importResult.recordCount} 条记录，'
        '${importResult.itineraryCount} 条攻略',
      );
      if (importResult.skippedCount > 0) {
        msg.write('，跳过 ${importResult.skippedCount} 条');
      }
      if (importResult.errors.isNotEmpty) {
        msg.write('\n警告：${importResult.errors.first}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString())),
      );
      await _loadSummary();
    } on UnsupportedBackupVersionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UdsColors.background,
      appBar: const UdsSettingsAppBar(title: '数据备份'),
      body: UdsContentConstrained(
        child: ListView(
        padding: const EdgeInsets.all(UdsSpacing.pagePadding),
        children: [
          if (_summary == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: UdsLoading(message: '读取数据概况...'),
            )
          else
            UdsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前数据概况', style: UdsTypography.titleMedium),
                  const SizedBox(height: UdsSpacing.md),
                  _row('旅行记录', '${_summary!['record_count']} 条'),
                  _row('攻略', '${_summary!['itinerary_count']} 条'),
                  _row(
                    '媒体文件',
                    _formatBytes(_summary!['media_bytes'] as int),
                  ),
                ],
              ),
            ),
          const SizedBox(height: UdsSpacing.lg),
          UdsButton(
            label: _exporting ? '导出中...' : '导出备份',
            icon: Icons.upload_rounded,
            loading: _exporting,
            onPressed: _exporting ? null : _export,
          ),
          const SizedBox(height: UdsSpacing.md),
          UdsButton(
            label: _importing ? '导入中...' : '从备份恢复',
            icon: Icons.download_rounded,
            variant: UdsButtonVariant.outlined,
            loading: _importing,
            onPressed: _importing ? null : _import,
            color: UdsColors.warning,
          ),
          const SizedBox(height: UdsSpacing.xxl),
          Text(
            '备份文件为 JSON 格式，包含旅行记录、攻略、对话与用户画像。同 ID 记录在导入时将被覆盖。',
            style: UdsTypography.labelSmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UdsSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: UdsTypography.bodyMedium),
          Text(value, style: UdsTypography.titleMedium),
        ],
      ),
    );
  }
}
