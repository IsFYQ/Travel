import '../core/events/event_bus.dart';
import '../core/events/domain_event.dart';
import '../core/logger.dart';

/// P1-3.3：应用启动时注册事件消费者
class AppBootstrap {
  static void registerEventConsumers() {
    final bus = EventBus();
    // 各消费者独立 try/catch，异常不影响主流程
    bus.on<RecordSaved>().listen((e) {
      try {
        AppLogger().debug('RecordSaved: ${e.recordId}');
      } catch (_) {}
    });
    bus.on<RecordDeleted>().listen((e) {
      try {
        AppLogger().debug('RecordDeleted: ${e.recordId}');
      } catch (_) {}
    });
    bus.on<ItineraryItemRated>().listen((e) {
      try {
        AppLogger().debug('ItineraryItemRated: ${e.itineraryId}');
      } catch (_) {}
    });
  }
}
