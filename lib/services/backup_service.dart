import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/travel_record.dart';
import '../models/itinerary.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../core/network/api_exception.dart';

/// P1-2.2：备份导入结果
class BackupImportResult {
  final int recordCount;
  final int itineraryCount;
  final int skippedCount;
  final List<String> errors;
  final String? safetyBackupPath;

  const BackupImportResult({
    required this.recordCount,
    required this.itineraryCount,
    this.skippedCount = 0,
    this.errors = const [],
    this.safetyBackupPath,
  });

  bool get success => errors.isEmpty || (recordCount + itineraryCount) > 0;
}

/// P1-2.1/2.2：数据备份服务
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _db = DatabaseService();
  final _ai = AiService();
  static const _supportedSchemaVersions = {1, 2};

  /// 导出所有数据为 JSON
  Future<String> exportToJson() async {
    final records =
        await _db.getRecords(includeHidden: true, includeDeleted: false);
    final itineraries = await _db.getItineraries();
    final sessions = await _db.getSessions();
    final profile = await _ai.getUserProfile();

    final allMessages = <Map<String, dynamic>>[];
    for (final session in sessions) {
      final messages = await _db.getMessages(session.id);
      allMessages.addAll(messages.map((m) => m.toMap()));
    }

    final data = {
      'export_time': DateTime.now().toIso8601String(),
      'version': '2.0',
      'schema_version': _db.backupSchemaVersion,
      'user_profile': profile.toJson(),
      'records': records.map((r) => r.toMap()).toList(),
      'itineraries': itineraries.map((i) => i.toMap()).toList(),
      'chat_sessions': sessions.map((s) => s.toMap()).toList(),
      'chat_messages': allMessages,
    };

    return jsonEncode(data);
  }

  Future<String> exportToFile() async {
    final json = await exportToJson();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/travel_backup_$timestamp.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// P1-2.2：带校验与事务的导入
  Future<BackupImportResult> importFromJson(String jsonStr) async {
    final errors = <String>[];
    var recordCount = 0;
    var itineraryCount = 0;
    var skipped = 0;

    // 导入前自动安全备份
    String? safetyPath;
    try {
      safetyPath = await exportToFile();
    } catch (e) {
      errors.add('安全备份失败: $e');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return BackupImportResult(
        recordCount: 0,
        itineraryCount: 0,
        errors: ['JSON 解析失败: $e'],
        safetyBackupPath: safetyPath,
      );
    }

    final schemaVersion = data['schema_version'] as int? ??
        (data['version'] == '2.0' ? 2 : 1);
    if (!_supportedSchemaVersions.contains(schemaVersion)) {
      throw UnsupportedBackupVersionException(schemaVersion);
    }

    final recordsRaw = data['records'] as List? ?? [];
    final itinerariesRaw = data['itineraries'] as List? ?? [];
    final sessionsRaw = data['chat_sessions'] as List? ?? [];
    final messagesRaw = data['chat_messages'] as List? ?? [];
    final profileRaw = data['user_profile'];

    final parsedRecords = <TravelRecord>[];
    for (final raw in recordsRaw) {
      try {
        parsedRecords.add(TravelRecord.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        skipped++;
        errors.add('记录解析失败: $e');
      }
    }

    final parsedItineraries = <Itinerary>[];
    for (final raw in itinerariesRaw) {
      try {
        parsedItineraries
            .add(Itinerary.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        skipped++;
        errors.add('攻略解析失败: $e');
      }
    }

    try {
      await _db.runInTransaction((txn) async {
        for (final record in parsedRecords) {
          await txn.insert('travel_records', record.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          recordCount++;
        }
        for (final it in parsedItineraries) {
          await txn.insert('itineraries', it.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          itineraryCount++;
        }
        for (final raw in sessionsRaw) {
          await txn.insert(
            'chat_sessions',
            Map<String, dynamic>.from(raw),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final raw in messagesRaw) {
          await txn.insert(
            'chat_messages',
            Map<String, dynamic>.from(raw),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      // 事务外同步 tags
      for (final record in parsedRecords) {
        await _db.syncRecordTags(record.id, record.tags, record.tripType);
      }

      if (profileRaw != null) {
        try {
          final profile = UserProfile.fromJson(
              Map<String, dynamic>.from(profileRaw as Map));
          await _ai.saveUserProfile(profile);
          await _db.saveDeclaredProfile(profile);
        } catch (e) {
          errors.add('用户画像导入失败: $e');
        }
      }
    } catch (e) {
      return BackupImportResult(
        recordCount: 0,
        itineraryCount: 0,
        skippedCount: skipped,
        errors: ['导入事务失败（已回滚）: $e', ...errors],
        safetyBackupPath: safetyPath,
      );
    }

    return BackupImportResult(
      recordCount: recordCount,
      itineraryCount: itineraryCount,
      skippedCount: skipped,
      errors: errors,
      safetyBackupPath: safetyPath,
    );
  }

  /// 数据概况
  Future<Map<String, dynamic>> getDataSummary() async {
    final stats = await _db.getStatistics();
    final itineraries = await _db.getItineraries();
    final mediaSize = await _calcMediaSize();
    return {
      'record_count': stats['record_count'] ?? 0,
      'itinerary_count': itineraries.length,
      'media_bytes': mediaSize,
    };
  }

  Future<int> _calcMediaSize() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docs.path}/media');
      if (!await mediaDir.exists()) return 0;
      var total = 0;
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
