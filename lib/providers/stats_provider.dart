import 'package:flutter/foundation.dart';
import '../data/repositories/travel_record_repository.dart';
import '../core/events/domain_event.dart';
import '../core/events/event_bus.dart';

/// P1-3.4：统计数据，订阅领域事件自动刷新
class StatsProvider extends ChangeNotifier {
  final TravelRecordRepository _repo;
  final EventBus _bus;

  Map<String, dynamic> _statistics = {};

  StatsProvider({TravelRecordRepository? repo, EventBus? bus})
      : _repo = repo ?? TravelRecordRepository(),
        _bus = bus ?? EventBus() {
    _bus.on<RecordSaved>().listen((_) => refresh());
    _bus.on<RecordDeleted>().listen((_) => refresh());
    _bus.on<RecordHidden>().listen((_) => refresh());
  }

  Map<String, dynamic> get statistics => _statistics;

  Future<void> init() => refresh();

  Future<void> refresh() async {
    _statistics = await _repo.getStatistics();
    notifyListeners();
  }
}
