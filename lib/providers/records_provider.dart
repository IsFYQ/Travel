import 'package:flutter/foundation.dart';
import '../models/travel_record.dart';
import '../data/repositories/travel_record_repository.dart';
import '../core/events/domain_event.dart';
import '../core/events/event_bus.dart';
import '../utils/date_format_util.dart';

/// P1-3.9：时间线条目（header 或 record）
enum TimelineEntryType { header, record }

class TimelineEntry {
  final TimelineEntryType type;
  final String? headerLabel;
  final TravelRecord? record;

  const TimelineEntry.header(this.headerLabel)
      : type = TimelineEntryType.header,
        record = null;

  const TimelineEntry.record(this.record)
      : type = TimelineEntryType.record,
        headerLabel = null;
}

/// P1-3.4：旅行记录状态
class RecordsProvider extends ChangeNotifier {
  final TravelRecordRepository _repo;
  final EventBus _bus;

  List<TravelRecord> _records = [];
  List<TravelRecord> _hiddenRecords = [];
  List<String> _destinations = [];
  List<TimelineEntry> _timelineEntries = [];
  bool _loading = false;
  String? _searchQuery;
  String? _tagFilter;

  RecordsProvider({TravelRecordRepository? repo, EventBus? bus})
      : _repo = repo ?? TravelRecordRepository(),
        _bus = bus ?? EventBus() {
    _bus.on<RecordSaved>().listen((_) => _refreshAfterChange());
    _bus.on<RecordDeleted>().listen((_) => _refreshAfterChange());
    _bus.on<RecordHidden>().listen((_) => _refreshAfterChange());
  }

  List<TravelRecord> get records => _records;
  List<TravelRecord> get hiddenRecords => _hiddenRecords;
  List<String> get destinations => _destinations;
  List<TimelineEntry> get timelineEntries => _timelineEntries;
  bool get loading => _loading;

  Future<void> init() async {
    await loadRecords();
    await loadHiddenRecords();
    await _loadDestinations();
  }

  Future<void> loadRecords({String? search, String? tag}) async {
    _loading = true;
    _searchQuery = search;
    _tagFilter = tag;
    notifyListeners();

    _records = await _repo.getRecords(
      search: search,
      tags: tag != null && tag.isNotEmpty ? [tag] : null,
    );
    _rebuildTimeline();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadHiddenRecords() async {
    _hiddenRecords = await _repo.getHiddenRecords();
    notifyListeners();
  }

  Future<void> _loadDestinations() async {
    _destinations = await _repo.getDestinations();
    notifyListeners();
  }

  Future<void> _refreshAfterChange() async {
    await loadRecords(search: _searchQuery, tag: _tagFilter);
    await loadHiddenRecords();
    await _loadDestinations();
  }

  Future<void> saveRecord(TravelRecord record) async {
    await _repo.save(record);
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      _records[idx] = record;
    } else {
      _records.insert(0, record);
    }
    _rebuildTimeline();
    notifyListeners();
    await _loadDestinations();
  }

  Future<void> deleteRecord(String id) async {
    await _repo.delete(id);
    _records.removeWhere((r) => r.id == id);
    _rebuildTimeline();
    notifyListeners();
  }

  Future<void> hideRecord(String id) async {
    await _repo.hide(id);
    await _refreshAfterChange();
  }

  Future<void> unhideRecord(String id) async {
    await _repo.unhide(id);
    await _refreshAfterChange();
  }

  Future<void> deleteRecordPermanently(String id) async {
    await _repo.deletePermanently(id);
    await _refreshAfterChange();
  }

  /// P1-3.9：分组扁平化，O(n) 构建
  void _rebuildTimeline() {
    final entries = <TimelineEntry>[];
    String? currentGroup;
    for (final record in _records) {
      final group = _groupLabel(record);
      if (group != currentGroup) {
        currentGroup = group;
        entries.add(TimelineEntry.header(group));
      }
      entries.add(TimelineEntry.record(record));
    }
    _timelineEntries = entries;
  }

  String _groupLabel(TravelRecord record) {
    final date = record.endDate ?? record.startDate ?? record.createdAt;
    return DateFormatUtil.yearMonth().format(date);
  }
}
