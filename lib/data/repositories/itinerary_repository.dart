import '../../models/itinerary.dart';
import '../../services/database_service.dart';
import '../../core/events/domain_event.dart';
import '../../core/events/event_bus.dart';

/// P1-3.2：攻略仓储
class ItineraryRepository {
  final DatabaseService _db;
  final EventBus _bus;

  ItineraryRepository({DatabaseService? db, EventBus? bus})
      : _db = db ?? DatabaseService(),
        _bus = bus ?? EventBus();

  Future<List<Itinerary>> getAll({ItineraryStatus? status}) =>
      _db.getItineraries(status: status);

  Future<Itinerary?> getById(String id) => _db.getItineraryById(id);

  Future<void> save(Itinerary itinerary) async {
    final existing = await _db.getItineraryById(itinerary.id);
    if (existing != null) {
      await _db.updateItinerary(itinerary);
      if (existing.status != itinerary.status) {
        _bus.publish(ItineraryStatusChanged(itinerary.id));
      }
    } else {
      await _db.insertItinerary(itinerary);
      _bus.publish(ItineraryCreated(itinerary.id));
    }
  }

  Future<void> saveWithRating(Itinerary itinerary) async {
    await save(itinerary);
    _bus.publish(ItineraryItemRated(itinerary.id));
  }

  Future<void> delete(String id) async {
    await _db.deleteItinerary(id);
  }
}
