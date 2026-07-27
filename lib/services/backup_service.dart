import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/travel_record.dart';
import '../models/itinerary.dart';
import '../services/database_service.dart';

/// 数据备份服务
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _db = DatabaseService();

  /// 导出所有数据为 JSON（包含隐藏记录）
  Future<String> exportToJson() async {
    final records = await _db.getRecords(includeHidden: true);
    final itineraries = await _db.getItineraries();

    final data = {
      'export_time': DateTime.now().toIso8601String(),
      'version': '1.0',
      'records': records.map((r) => r.toMap()).toList(),
      'itineraries': itineraries.map((i) => i.toMap()).toList(),
    };

    return jsonEncode(data);
  }

  /// 导出到文件
  Future<String> exportToFile() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/travel_backup_$timestamp.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// 从 JSON 导入
  Future<int> importFromJson(String json) async {
    try {
      final data = jsonDecode(json);
      int count = 0;

      // 导入旅行记录
      if (data['records'] != null) {
        final records = data['records'] as List;
        for (final record in records) {
          await _db.insertRecord(
            TravelRecord.fromMap(Map<String, dynamic>.from(record)),
          );
          count++;
        }
      }

      // 导入攻略
      if (data['itineraries'] != null) {
        final itineraries = data['itineraries'] as List;
        for (final itinerary in itineraries) {
          await _db.insertItinerary(
            Itinerary.fromMap(Map<String, dynamic>.from(itinerary)),
          );
          count++;
        }
      }

      return count;
    } catch (e) {
      return -1;
    }
  }
}
