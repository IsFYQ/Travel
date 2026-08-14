import 'dart:async';
import 'domain_event.dart';

/// P1-3.3：领域事件总线
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<DomainEvent>.broadcast();

  void publish(DomainEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Stream<T> on<T extends DomainEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  void dispose() {
    _controller.close();
  }
}
