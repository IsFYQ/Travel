import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../../core/events/domain_event.dart';
import '../../core/events/event_bus.dart';

/// P1-3.2：用户画像仓储（声明层）
class UserProfileRepository {
  final DatabaseService _db;
  final AiService _ai;
  final EventBus _bus;

  UserProfileRepository({
    DatabaseService? db,
    AiService? ai,
    EventBus? bus,
  })  : _db = db ?? DatabaseService(),
        _ai = ai ?? AiService(),
        _bus = bus ?? EventBus();

  Future<UserProfile> getProfile() async {
    final declared = await _db.getDeclaredProfile();
    if (declared != null) return declared;
    // 兼容旧 secure storage 数据
    return _ai.getUserProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _db.saveDeclaredProfile(profile);
    await _ai.saveUserProfile(profile);
    _bus.publish(const ProfileDeclaredChanged());
  }
}
