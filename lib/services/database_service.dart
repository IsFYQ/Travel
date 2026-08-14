import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/travel_record.dart';
import '../models/itinerary.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

/// P1-3.5：SQLite 数据库服务（v4 schema）
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static const int _version = 4;
  static const int _backupSchemaVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_app.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createV4Schema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE itineraries ADD COLUMN trip_type TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE travel_records ADD COLUMN is_hidden INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      // P1-3.5：v4 占位迁移（设备无真实存量数据，简化实现）
      await _migrateToV4(db);
    }
  }

  Future<void> _migrateToV4(Database db) async {
    // 新增 travel_records 列
    for (final col in [
      "ALTER TABLE travel_records ADD COLUMN origin TEXT DEFAULT 'local'",
      'ALTER TABLE travel_records ADD COLUMN content_hash TEXT',
      'ALTER TABLE travel_records ADD COLUMN deleted_at TEXT',
      'ALTER TABLE travel_records ADD COLUMN rating_scenery REAL DEFAULT 0',
      'ALTER TABLE travel_records ADD COLUMN rating_food REAL DEFAULT 0',
      'ALTER TABLE travel_records ADD COLUMN rating_stay REAL DEFAULT 0',
      'ALTER TABLE travel_records ADD COLUMN rating_transport REAL DEFAULT 0',
      'ALTER TABLE travel_records ADD COLUMN rating_value REAL DEFAULT 0',
    ]) {
      try {
        await db.execute(col);
      } catch (_) {}
    }

    await _createV4ExtraTables(db);

    // 迁移 tags 到关联表
    await _migrateTagsFromRecords(db);

    // 删除旧 IMA 待删除表
    try {
      await db.execute('DROP TABLE IF EXISTS pending_ima_deletions');
    } catch (_) {}
  }

  Future<void> _createV4Schema(Database db) async {
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
        rating_scenery REAL DEFAULT 0,
        rating_food REAL DEFAULT 0,
        rating_stay REAL DEFAULT 0,
        rating_transport REAL DEFAULT 0,
        rating_value REAL DEFAULT 0,
        is_hidden INTEGER DEFAULT 0,
        origin TEXT DEFAULT 'local',
        content_hash TEXT,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT DEFAULT '新对话',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        display_content TEXT,
        follow_up_suggestions TEXT DEFAULT '[]',
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await _createV4ExtraTables(db);

    await db.execute(
        'CREATE INDEX idx_records_destination ON travel_records(destination)');
    await db.execute(
        'CREATE INDEX idx_records_created ON travel_records(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_records_deleted ON travel_records(deleted_at)');
    await db.execute(
        'CREATE INDEX idx_itineraries_status ON itineraries(status)');
    await db.execute(
        'CREATE INDEX idx_messages_session ON chat_messages(session_id)');
  }

  Future<void> _createV4ExtraTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_mappings (
        entity_type TEXT NOT NULL,
        local_id TEXT NOT NULL,
        remote_note_id TEXT,
        remote_media_id TEXT,
        remote_folder_id TEXT,
        local_hash TEXT,
        synced_hash TEXT,
        remote_hash TEXT,
        last_synced_at TEXT,
        state TEXT DEFAULT 'pending',
        PRIMARY KEY (entity_type, local_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        local_id TEXT NOT NULL,
        op TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_queue_unique
      ON sync_queue(entity_type, local_id, op)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_declared (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        home_city TEXT DEFAULT '',
        nickname TEXT DEFAULT '',
        travel_styles TEXT DEFAULT '[]',
        food_prefs TEXT DEFAULT '[]',
        budget_level TEXT,
        group_size TEXT,
        companions TEXT DEFAULT '[]',
        avoidances TEXT DEFAULT '[]',
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_facts (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT,
        confidence REAL NOT NULL,
        evidence_count INTEGER DEFAULT 1,
        source_ids TEXT DEFAULT '[]',
        first_seen_at TEXT,
        last_seen_at TEXT,
        suppressed INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_facts_key
      ON profile_facts(category, key)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_snapshot (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        version INTEGER DEFAULT 1,
        prompt_text TEXT DEFAULT '',
        source_hash TEXT,
        generated_at TEXT,
        is_dirty INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT DEFAULT 'custom'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS record_tags (
        record_id TEXT NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (record_id, tag_id),
        FOREIGN KEY (record_id) REFERENCES travel_records(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_record_tags_tag
      ON record_tags(tag_id, record_id)
    ''');
  }

  Future<void> _migrateTagsFromRecords(Database db) async {
    final records = await db.query('travel_records');
    for (final row in records) {
      final recordId = row['id'] as String;
      await _syncRecordTags(recordId, row['tags'] as String? ?? '[]',
          row['trip_type'] as String? ?? '');
    }
  }

  /// P1-3.7：同步 record_tags 关联表
  Future<void> syncRecordTags(String recordId, List<String> tags, String tripType) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('record_tags', where: 'record_id = ?', whereArgs: [recordId]);
      final allTags = {...tags};
      if (tripType.isNotEmpty) {
        for (final t in tripType.split(',')) {
          final trimmed = t.trim();
          if (trimmed.isNotEmpty) allTags.add(trimmed);
        }
      }
      for (final name in allTags) {
        final tagId = await _getOrCreateTag(txn, name);
        await txn.insert('record_tags', {'record_id': recordId, 'tag_id': tagId},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> _syncRecordTags(String recordId, String tagsJson, String tripType) async {
    try {
      final tags = List<String>.from(jsonDecode(tagsJson));
      await syncRecordTags(recordId, tags, tripType);
    } catch (_) {}
  }

  Future<int> _getOrCreateTag(DatabaseExecutor db, String name) async {
    final existing = await db.query('tags', where: 'name = ?', whereArgs: [name]);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await db.insert('tags', {'name': name, 'category': 'custom'});
  }

  static const _activeRecordFilter = 'deleted_at IS NULL';

  // ========== 旅行日记 CRUD ==========

  Future<void> insertRecord(TravelRecord record) async {
    final db = await database;
    await db.insert('travel_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await syncRecordTags(record.id, record.tags, record.tripType);
  }

  Future<List<TravelRecord>> getRecords({
    String? searchQuery,
    List<String>? tagFilters,
    int? limit,
    int? offset,
    bool includeHidden = false,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (!includeDeleted) {
      whereParts.add(_activeRecordFilter);
    }
    if (!includeHidden) {
      whereParts.add('is_hidden = 0');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereParts.add('destination LIKE ?');
      whereArgs.add('%$searchQuery%');
    }

    String? joinClause;
    if (tagFilters != null && tagFilters.isNotEmpty) {
      joinClause = '''
        INNER JOIN record_tags rt ON travel_records.id = rt.record_id
        INNER JOIN tags t ON rt.tag_id = t.id
      ''';
      whereParts.add('t.name IN (${List.filled(tagFilters.length, '?').join(',')})');
      whereArgs.addAll(tagFilters);
    }

    final where = whereParts.isEmpty ? null : whereParts.join(' AND ');
    final table = joinClause != null ? 'travel_records $joinClause' : 'travel_records';

    final maps = await db.query(
      table,
      distinct: joinClause != null,
      columns: joinClause != null ? ['travel_records.*'] : null,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'COALESCE(end_date, start_date, created_at) DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => TravelRecord.fromMap(map)).toList();
  }

  Future<List<TravelRecord>> getHiddenRecords() async {
    final db = await database;
    final maps = await db.query(
      'travel_records',
      where: 'is_hidden = 1 AND $_activeRecordFilter',
      orderBy: 'COALESCE(end_date, start_date, created_at) DESC',
    );
    return maps.map((map) => TravelRecord.fromMap(map)).toList();
  }

  Future<TravelRecord?> getRecordById(String id, {bool includeDeleted = false}) async {
    final db = await database;
    final where = includeDeleted ? 'id = ?' : 'id = ? AND $_activeRecordFilter';
    final maps = await db.query('travel_records', where: where, whereArgs: [id]);
    return maps.isEmpty ? null : TravelRecord.fromMap(maps.first);
  }

  Future<void> updateRecord(TravelRecord record) async {
    final db = await database;
    await db.update('travel_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
    await syncRecordTags(record.id, record.tags, record.tripType);
  }

  /// P1-3.6：软删除
  Future<void> softDeleteRecord(String id) async {
    final db = await database;
    await db.update(
      'travel_records',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRecordPermanently(String id) async {
    final db = await database;
    await db.delete('record_tags', where: 'record_id = ?', whereArgs: [id]);
    await db.delete('travel_records', where: 'id = ?', whereArgs: [id]);
    await db.delete('sync_mappings',
        where: 'entity_type = ? AND local_id = ?', whereArgs: ['record', id]);
  }

  /// 清理超过 30 天的软删记录
  Future<int> purgeOldDeletedRecords() async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final maps = await db.query(
      'travel_records',
      columns: ['id'],
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
    for (final row in maps) {
      await deleteRecordPermanently(row['id'] as String);
    }
    return maps.length;
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

  // ========== 对话 CRUD ==========

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
    const filter = 'is_hidden = 0 AND $_activeRecordFilter';

    final recordCount =
        Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM travel_records WHERE $filter')) ??
        0;

    final destinations = await db.rawQuery(
        'SELECT DISTINCT destination FROM travel_records WHERE $filter');
    final cityCount = destinations.length;

    final totalCostResult = await db.rawQuery(
        'SELECT SUM(total_cost) as total FROM travel_records WHERE $filter');
    final totalCost =
        (totalCostResult.first['total'] as num?)?.toDouble() ?? 0;

    final totalDaysResult = await db.rawQuery(
        'SELECT SUM(JULIANDAY(COALESCE(end_date, start_date)) - JULIANDAY(start_date) + 1) as days FROM travel_records WHERE start_date IS NOT NULL AND $filter');
    final totalDays =
        (totalDaysResult.first['days'] as num?)?.toInt() ?? 0;

    return {
      'record_count': recordCount,
      'city_count': cityCount,
      'total_cost': totalCost,
      'total_days': totalDays,
    };
  }

  Future<List<String>> getAllDestinations() async {
    final db = await database;
    final results = await db.rawQuery(
        'SELECT DISTINCT destination FROM travel_records WHERE is_hidden = 0 AND $_activeRecordFilter ORDER BY destination');
    return results.map((r) => r['destination'] as String).toList();
  }

  // ========== profile_declared ==========

  Future<UserProfile?> getDeclaredProfile() async {
    final db = await database;
    final maps = await db.query('profile_declared', where: 'id = 1');
    if (maps.isEmpty) return null;
    final m = maps.first;
    return UserProfile(
      homeCity: m['home_city'] as String? ?? '',
      nickname: m['nickname'] as String? ?? '',
      travelStyles: _decodeStringList(m['travel_styles']),
      foodPrefs: _decodeStringList(m['food_prefs']),
      budgetLevel: _parseBudgetLevel(m['budget_level'] as String?),
      groupSize: _parseGroupSize(m['group_size'] as String?),
      companions: _decodeStringList(m['companions']),
      avoidances: _decodeStringList(m['avoidances']),
    );
  }

  Future<void> saveDeclaredProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profile_declared',
      {
        'id': 1,
        'home_city': profile.homeCity,
        'nickname': profile.nickname,
        'travel_styles': jsonEncode(profile.travelStyles),
        'food_prefs': jsonEncode(profile.foodPrefs),
        'budget_level': profile.budgetLevel?.name,
        'group_size': profile.groupSize?.name,
        'companions': jsonEncode(profile.companions),
        'avoidances': jsonEncode(profile.avoidances),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  List<String> _decodeStringList(Object? raw) {
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw as String));
    } catch (_) {
      return [];
    }
  }

  BudgetLevel? _parseBudgetLevel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return BudgetLevel.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  TravelGroupSize? _parseGroupSize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return TravelGroupSize.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  /// P1-2.2：事务导入
  Future<void> runInTransaction(Future<void> Function(Transaction txn) action) async {
    final db = await database;
    await db.transaction((txn) => action(txn));
  }

  int get backupSchemaVersion => _backupSchemaVersion;

  /// 兼容旧 IMA 待删除队列 API（v4 已迁移至 sync_queue，板块4 接入）
  Future<List<String>> getPendingImaDeletions() async => [];

  Future<void> clearPendingImaDeletion(String recordId) async {}
}
