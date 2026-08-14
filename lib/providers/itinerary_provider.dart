import 'package:flutter/foundation.dart';
import '../models/itinerary.dart';
import '../data/repositories/itinerary_repository.dart';
import '../core/events/domain_event.dart';
import '../core/events/event_bus.dart';

/// P1-3.4：攻略状态
class ItineraryProvider extends ChangeNotifier {
  final ItineraryRepository _repo;
  final EventBus _bus;

  List<Itinerary> _itineraries = [];
  bool _loading = false;

  ItineraryProvider({ItineraryRepository? repo, EventBus? bus})
      : _repo = repo ?? ItineraryRepository(),
        _bus = bus ?? EventBus() {
    _bus.on<ItineraryCreated>().listen((_) => loadItineraries());
    _bus.on<ItineraryStatusChanged>().listen((_) => loadItineraries());
    _bus.on<ItineraryItemRated>().listen((_) => loadItineraries());
  }

  List<Itinerary> get itineraries => _itineraries;
  bool get loading => _loading;

  Future<void> init() => loadItineraries();

  Future<void> loadItineraries({ItineraryStatus? status}) async {
    _loading = true;
    notifyListeners();
    try {
      _itineraries = await _repo.getAll(status: status);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    await _repo.save(itinerary);
    final idx = _itineraries.indexWhere((i) => i.id == itinerary.id);
    if (idx >= 0) {
      _itineraries[idx] = itinerary;
    } else {
      _itineraries.insert(0, itinerary);
    }
    notifyListeners();
  }

  Future<void> saveItineraryWithRating(Itinerary itinerary) async {
    await _repo.saveWithRating(itinerary);
    final idx = _itineraries.indexWhere((i) => i.id == itinerary.id);
    if (idx >= 0) {
      _itineraries[idx] = itinerary;
    }
    notifyListeners();
  }

  Future<void> deleteItinerary(String id) async {
    await _repo.delete(id);
    _itineraries.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
