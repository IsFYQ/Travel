import 'dart:convert';
import '../../models/travel_record.dart';
import '../../services/database_service.dart';
import '../../services/media_service.dart';
import '../../core/events/domain_event.dart';
import '../../core/events/event_bus.dart';

/// P1-3.2：旅行记录仓储
class TravelRecordRepository {
  final DatabaseService _db;
  final MediaService _media;
  final EventBus _bus;

  TravelRecordRepository({
    DatabaseService? db,
    MediaService? media,
    EventBus? bus,
  })  : _db = db ?? DatabaseService(),
        _media = media ?? MediaService(),
        _bus = bus ?? EventBus();

  Future<List<TravelRecord>> getRecords({
    String? search,
    List<String>? tags,
    bool includeHidden = false,
  }) =>
      _db.getRecords(
        searchQuery: search,
        tagFilters: tags,
        includeHidden: includeHidden,
      );

  Future<List<TravelRecord>> getHiddenRecords() => _db.getHiddenRecords();

  Future<TravelRecord?> getById(String id) => _db.getRecordById(id);

  Future<void> save(TravelRecord record) async {
    final existing = await _db.getRecordById(record.id, includeDeleted: true);
    if (existing != null) {
      await _db.updateRecord(record);
    } else {
      await _db.insertRecord(record);
    }
    _bus.publish(RecordSaved(record.id));
  }

  Future<void> hide(String id) async {
    final record = await _db.getRecordById(id);
    if (record != null) {
      await _db.updateRecord(record.copyWith(isHidden: true));
      _bus.publish(RecordHidden(id, true));
    }
  }

  Future<void> unhide(String id) async {
    final record = await _db.getRecordById(id, includeDeleted: true);
    if (record != null) {
      await _db.updateRecord(record.copyWith(isHidden: false));
      _bus.publish(RecordHidden(id, false));
    }
  }

  /// P1-3.6：软删除
  Future<void> delete(String id) async {
    await _db.softDeleteRecord(id);
    _bus.publish(RecordDeleted(id));
  }

  /// 物理删除并清理媒体
  Future<void> deletePermanently(String id) async {
    final record = await _db.getRecordById(id, includeDeleted: true);
    if (record != null) {
      await _deleteContentMedia(record.content);
    }
    await _db.deleteRecordPermanently(id);
    _bus.publish(RecordDeleted(id));
  }

  Future<void> _deleteContentMedia(String contentJson) async {
    try {
      final blocks = List<Map<String, dynamic>>.from(jsonDecode(contentJson));
      for (final block in blocks) {
        if (block['type'] == 'image' && block['path'] != null) {
          await _media.deleteMedia(block['path'] as String);
        }
      }
    } catch (_) {}
  }

  Future<List<String>> getDestinations() => _db.getAllDestinations();

  Future<Map<String, dynamic>> getStatistics() => _db.getStatistics();
}
