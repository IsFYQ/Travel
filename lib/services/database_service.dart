import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/travel_record.dart';
import '../models/itinerary.dart';
import '../models/chat_message.dart';

/// SQLite 数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_app.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 旅行日记表
    await db.execute('''
      CREATE TABLE travel_records (
        id TEXT PRIMARY KEY,
        destination TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        people INTEGER DEFAULT 1,
        trip_type TEXT DEFAULT '',
        transport_type TEXT DEFAULT '',
        tags TEXT DEFAULT '[]',
        content TEXT DEFAULT '[]',
        cover_image_path TEXT,
        summary TEXT,
        total_cost REAL DEFAULT 0,
        rating REAL DEFAULT 0,
        is_hidden INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 攻略表
    await db.execute('''
      CREATE TABLE itineraries (
        id TEXT PRIMARY KEY,
        destination TEXT NOT NULL,
        status TEXT DEFAULT 'planning',
        start_date TEXT,
        end_date TEXT,
        days INTEGER DEFAULT 1,
        total_budget REAL DEFAULT 0,
        people INTEGER DEFAULT 1,
        raw_content TEXT DEFAULT '',
        day_plans TEXT DEFAULT '[]',
        source_chat_id TEXT,
        trip_type TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 对话会话表
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT DEFAULT '新对话',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 对话消息表
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        follow_up_suggestions TEXT DEFAULT '[]',
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    // IMA 待删除队列
    await db.execute('''
      CREATE TABLE pending_ima_deletions (
        id TEXT PRIMARY KEY,
        record_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建索引
    await db.execute(
        'CREATE INDEX idx_records_destination ON travel_records(destination)');
    await db.execute(
        'CREATE INDEX idx_records_created ON travel_records(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_itineraries_status ON itineraries(status)');
    await db.execute(
        'CREATE INDEX idx_messages_session ON chat_messages(session_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE itineraries ADD COLUMN trip_type TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE travel_records ADD COLUMN is_hidden INTEGER DEFAULT 0');
      await db.execute('''
        CREATE TABLE pending_ima_deletions (
          id TEXT PRIMARY KEY,
          record_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ========== 旅行日记 CRUD ==========

  Future<void> insertRecord(TravelRecord record) async {
    final db = await database;
    await db.insert('travel_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TravelRecord>> getRecords({
    String? searchQuery,
    String? tagFilter,
    int? limit,
    int? offset,
    bool includeHidden = false,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (!includeHidden) {
      where = 'is_hidden = 0';
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'destination LIKE ?';
      whereArgs.add('%$searchQuery%');
    }

    if (tagFilter != null && tagFilter.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += '(trip_type LIKE ? OR tags LIKE ?)';
      whereArgs.add('%$tagFilter%');
      whereArgs.add('%$tagFilter%');
    }

    final maps = await db.query(
      'travel_records',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'COALESCE(end_date, start_date, created_at) DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => TravelRecord.fromMap(map)).toList();
  }

  /// 获取所有被隐藏的记录
  Future<List<TravelRecord>> getHiddenRecords() async {
    final db = await database;
    final maps = await db.query(
      'travel_records',
      where: 'is_hidden = 1',
      orderBy: 'COALESCE(end_date, start_date, created_at) DESC',
    );
    return maps.map((map) => TravelRecord.fromMap(map)).toList();
  }

  Future<TravelRecord?> getRecordById(String id) async {
    final db = await database;
    final maps =
        await db.query('travel_records', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : TravelRecord.fromMap(maps.first);
  }

  Future<void> updateRecord(TravelRecord record) async {
    final db = await database;
    await db.update('travel_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('travel_records', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 攻略 CRUD ==========

  Future<void> insertItinerary(Itinerary itinerary) async {
    final db = await database;
    await db.insert('itineraries', itinerary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Itinerary>> getItineraries({ItineraryStatus? status}) async {
    final db = await database;
    final maps = await db.query(
      'itineraries',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.value] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Itinerary.fromMap(map)).toList();
  }

  Future<Itinerary?> getItineraryById(String id) async {
    final db = await database;
    final maps =
        await db.query('itineraries', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Itinerary.fromMap(maps.first);
  }

  Future<void> updateItinerary(Itinerary itinerary) async {
    final db = await database;
    await db.update('itineraries', itinerary.toMap(),
        where: 'id = ?', whereArgs: [itinerary.id]);
  }

  Future<void> deleteItinerary(String id) async {
    final db = await database;
    await db.delete('itineraries', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 对话会话 CRUD ==========

  Future<void> insertSession(ChatSession session) async {
    final db = await database;
    await db.insert('chat_sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final maps =
        await db.query('chat_sessions', orderBy: 'updated_at DESC');
    return maps.map((map) => ChatSession.fromMap(map)).toList();
  }

  Future<void> updateSession(ChatSession session) async {
    final db = await database;
    await db.update('chat_sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  /// 仅更新会话的 updated_at 时间戳，不影响标题等字段
  Future<void> touchSession(String sessionId) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [id]);
    await db
        .delete('chat_messages', where: 'session_id = ?', whereArgs: [id]);
  }

  // ========== 对话消息 CRUD ==========

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('chat_messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await database;
    final maps = await db.query('chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC');
    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  // ========== 统计查询 ==========

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final recordCount =
        Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM travel_records WHERE is_hidden = 0')) ??
        0;

    final destinations = await db.rawQuery(
        'SELECT DISTINCT destination FROM travel_records WHERE is_hidden = 0');
    final cityCount = destinations.length;

    final totalCostResult = await db.rawQuery(
        'SELECT SUM(total_cost) as total FROM travel_records WHERE is_hidden = 0');
    final totalCost =
        (totalCostResult.first['total'] as num?)?.toDouble() ?? 0;

    final totalDaysResult = await db.rawQuery(
        'SELECT SUM(JULIANDAY(COALESCE(end_date, start_date)) - JULIANDAY(start_date) + 1) as days FROM travel_records WHERE start_date IS NOT NULL AND is_hidden = 0');
    final totalDays =
        (totalDaysResult.first['days'] as num?)?.toInt() ?? 0;

    return {
      'record_count': recordCount,
      'city_count': cityCount,
      'total_cost': totalCost,
      'total_days': totalDays,
    };
  }

  /// 获取所有去过的目的地（用于日记编辑器选择，排除隐藏记录）
  Future<List<String>> getAllDestinations() async {
    final db = await database;
    final results = await db.rawQuery(
        'SELECT DISTINCT destination FROM travel_records WHERE is_hidden = 0 ORDER BY destination');
    return results.map((r) => r['destination'] as String).toList();
  }

  // ========== IMA 待删除队列 ==========

  Future<void> markRecordForImaDeletion(String recordId) async {
    final db = await database;
    await db.insert(
      'pending_ima_deletions',
      {
        'id': '${DateTime.now().millisecondsSinceEpoch}_$recordId',
        'record_id': recordId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getPendingImaDeletions() async {
    final db = await database;
    final results = await db.query('pending_ima_deletions');
    return results.map((r) => r['record_id'] as String).toList();
  }

  Future<void> clearPendingImaDeletion(String recordId) async {
    final db = await database;
    await db.delete(
      'pending_ima_deletions',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }
}
