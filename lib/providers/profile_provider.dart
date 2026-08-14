import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../data/repositories/user_profile_repository.dart';
import '../data/repositories/travel_record_repository.dart';
import '../services/ai_service.dart';
import '../core/events/domain_event.dart';
import '../core/events/event_bus.dart';

/// P1-3.4 / P1-3.11：用户画像状态
class ProfileProvider extends ChangeNotifier {
  final UserProfileRepository _profileRepo;
  final TravelRecordRepository _recordRepo;
  final AiService _ai;
  final EventBus _bus;

  UserProfile? _profile;
  String _promptText = '';

  ProfileProvider({
    UserProfileRepository? profileRepo,
    TravelRecordRepository? recordRepo,
    AiService? ai,
    EventBus? bus,
  })  : _profileRepo = profileRepo ?? UserProfileRepository(),
        _recordRepo = recordRepo ?? TravelRecordRepository(),
        _ai = ai ?? AiService(),
        _bus = bus ?? EventBus() {
    _bus.on<RecordSaved>().listen((_) => _rebuildPrompt());
    _bus.on<RecordDeleted>().listen((_) => _rebuildPrompt());
    _bus.on<ProfileDeclaredChanged>().listen((_) => _rebuildPrompt());
  }

  UserProfile? get profile => _profile;
  String get promptText => _promptText;

  Future<void> init() async {
    _profile = await _profileRepo.getProfile();
    await _rebuildPrompt();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profileRepo.saveProfile(profile);
    _profile = profile;
    await _rebuildPrompt();
  }

  Future<void> _rebuildPrompt() async {
    final profile = _profile ?? await _profileRepo.getProfile();
    _profile = profile;
    final stats = await _recordRepo.getStatistics();
    final records = await _recordRepo.getRecords();
    final destinations = await _recordRepo.getDestinations();

    final totalCost = (stats['total_cost'] ?? 0.0) as double;
    final recordCount = (stats['record_count'] ?? 0) as int;
    final avgBudget = recordCount > 0 ? totalCost / recordCount : 0.0;
    final lastTrip = records.isNotEmpty ? records.first.destination : '';

    _promptText = _ai.renderProfilePrompt(
      profile: profile,
      visitedPlaces: destinations,
      avgBudget: avgBudget,
      totalTrips: recordCount,
      totalDays: (stats['total_days'] ?? 0) as int,
      lastTrip: lastTrip,
    );
    notifyListeners();
  }
}
