import 'package:flutter/foundation.dart';
import '../models/travel_record.dart';
import '../models/itinerary.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';

/// 应用全局状态管理
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // ========== 统计数据 ==========
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> get statistics => _statistics;

  // ========== 旅行记录 ==========
  List<TravelRecord> _records = [];
  List<TravelRecord> get records => _records;
  bool _recordsLoading = false;
  bool get recordsLoading => _recordsLoading;

  // ========== 隐藏记录 ==========
  List<TravelRecord> _hiddenRecords = [];
  List<TravelRecord> get hiddenRecords => _hiddenRecords;

  // ========== 攻略 ==========
  List<Itinerary> _itineraries = [];
  List<Itinerary> get itineraries => _itineraries;

  // ========== 目的地列表 ==========
  List<String> _destinations = [];
  List<String> get destinations => _destinations;

  /// 初始化加载
  Future<void> init() async {
    await Future.wait([
      loadRecords(),
      loadHiddenRecords(),
      loadItineraries(),
      loadStatistics(),
      _loadDestinations(),
    ]);
  }

  /// 加载统计数据
  Future<void> loadStatistics() async {
    _statistics = await _db.getStatistics();
    notifyListeners();
  }

  /// 加载所有目的地
  Future<void> _loadDestinations() async {
    _destinations = await _db.getAllDestinations();
    notifyListeners();
  }

  // ========== 旅行记录操作 ==========

  Future<void> loadRecords({String? search, String? tag}) async {
    _recordsLoading = true;
    notifyListeners();

    _records = await _db.getRecords(searchQuery: search, tagFilter: tag);

    _recordsLoading = false;
    notifyListeners();
  }

  Future<void> saveRecord(TravelRecord record) async {
    final existing = await _db.getRecordById(record.id);
    if (existing != null) {
      await _db.updateRecord(record);
    } else {
      await _db.insertRecord(record);
    }
    await loadRecords();
    await loadStatistics();
    await _loadDestinations();
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteRecord(id);
    await loadRecords();
    await loadStatistics();
    await _loadDestinations();
  }

  /// 隐藏记录
  Future<void> hideRecord(String id) async {
    final record = await _db.getRecordById(id);
    if (record != null) {
      await _db.updateRecord(record.copyWith(isHidden: true));
    }
    await loadRecords();
    await loadHiddenRecords();
    await loadStatistics();
    await _loadDestinations();
  }

  /// 取消隐藏记录
  Future<void> unhideRecord(String id) async {
    final record = await _db.getRecordById(id);
    if (record != null) {
      await _db.updateRecord(record.copyWith(isHidden: false));
    }
    await loadRecords();
    await loadHiddenRecords();
    await loadStatistics();
    await _loadDestinations();
  }

  /// 永久删除记录（标记 IMA 待删除）
  Future<void> deleteRecordPermanently(String id) async {
    // 标记为 IMA 待删除
    await _db.markRecordForImaDeletion(id);
    // 从本地数据库删除
    await _db.deleteRecord(id);
    await loadRecords();
    await loadHiddenRecords();
    await loadStatistics();
    await _loadDestinations();
  }

  /// 加载隐藏记录
  Future<void> loadHiddenRecords() async {
    _hiddenRecords = await _db.getHiddenRecords();
    notifyListeners();
  }

  // ========== 攻略操作 ==========

  Future<void> loadItineraries({ItineraryStatus? status}) async {
    _itineraries = await _db.getItineraries(status: status);
    notifyListeners();
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    final existing = await _db.getItineraryById(itinerary.id);
    if (existing != null) {
      await _db.updateItinerary(itinerary);
    } else {
      await _db.insertItinerary(itinerary);
    }
    await loadItineraries();
  }

  Future<void> deleteItinerary(String id) async {
    await _db.deleteItinerary(id);
    await loadItineraries();
  }

  // ========== 对话操作 ==========

  Future<void> saveChatSession(ChatSession session) async {
    await _db.insertSession(session);
  }

  Future<List<ChatSession>> getChatSessions() async {
    return await _db.getSessions();
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _db.insertMessage(message);
    // 仅更新会话时间戳，不覆盖标题
    await _db.touchSession(message.sessionId);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    return await _db.getMessages(sessionId);
  }

  Future<void> deleteChatSession(String sessionId) async {
    await _db.deleteSession(sessionId);
  }
}
