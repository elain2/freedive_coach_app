import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../models/media_attachment.dart';

class DatabaseService {
  static const String _databaseName = 'freedive_coach.db';
  static const int _databaseVersion = 1;

  Database? _database;

  bool get isInitialized => _database != null;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Initialize with in-memory database for testing
  Future<void> initForTesting() async {
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dive_logs (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        dive_date TEXT NOT NULL,
        location TEXT,
        discipline TEXT NOT NULL,
        depth REAL,
        distance REAL,
        duration_seconds INTEGER,
        mouthfill_depth REAL,
        freefall_depth REAL,
        weight REAL,
        equipment TEXT,
        condition TEXT,
        contractions INTEGER,
        tags TEXT,
        buddies TEXT,
        notes TEXT,
        raw_input TEXT,
        ai_parsed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE media_attachments (
        id TEXT PRIMARY KEY,
        log_id TEXT NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        comment TEXT,
        order_index INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (log_id) REFERENCES dive_logs (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for common queries
    await db.execute('CREATE INDEX idx_dive_logs_dive_date ON dive_logs (dive_date)');
    await db.execute('CREATE INDEX idx_dive_logs_discipline ON dive_logs (discipline)');
    await db.execute('CREATE INDEX idx_media_attachments_log_id ON media_attachments (log_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get table names (for testing)
  Future<List<String>> getTableNames() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  // ==================== Dive Log Operations ====================

  Future<void> insertLog(DiveLog log) async {
    final db = await database;
    await db.insert(
      'dive_logs',
      _logToMap(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLog(DiveLog log) async {
    final db = await database;
    await db.update(
      'dive_logs',
      _logToMap(log),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteLog(String id) async {
    final db = await database;
    // Delete associated media attachments first (if CASCADE doesn't work)
    await db.delete('media_attachments', where: 'log_id = ?', whereArgs: [id]);
    await db.delete('dive_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<DiveLog?> getLogById(String id) async {
    final db = await database;
    final maps = await db.query(
      'dive_logs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToLog(maps.first);
  }

  Future<List<DiveLog>> getAllLogs() async {
    final db = await database;
    final maps = await db.query(
      'dive_logs',
      orderBy: 'dive_date DESC',
    );
    return maps.map((map) => _mapToLog(map)).toList();
  }

  Future<List<DiveLog>> getLogsByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'dive_logs',
      where: 'dive_date >= ? AND dive_date < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'dive_date DESC',
    );
    return maps.map((map) => _mapToLog(map)).toList();
  }

  Future<List<DiveLog>> getLogsByDiscipline(Discipline discipline) async {
    final db = await database;
    final maps = await db.query(
      'dive_logs',
      where: 'discipline = ?',
      whereArgs: [discipline.name],
      orderBy: 'dive_date DESC',
    );
    return maps.map((map) => _mapToLog(map)).toList();
  }

  Future<List<DiveLog>> getRecentLogs({int count = 10}) async {
    final db = await database;
    final maps = await db.query(
      'dive_logs',
      orderBy: 'dive_date DESC',
      limit: count,
    );
    return maps.map((map) => _mapToLog(map)).toList();
  }

  Future<int> getLogCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM dive_logs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double?> getMaxDepth() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(depth) as max_depth FROM dive_logs');
    if (result.isEmpty || result.first['max_depth'] == null) return null;
    return (result.first['max_depth'] as num).toDouble();
  }

  Future<double?> getMaxDistance() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(distance) as max_distance FROM dive_logs');
    if (result.isEmpty || result.first['max_distance'] == null) return null;
    return (result.first['max_distance'] as num).toDouble();
  }

  Future<Duration?> getMaxDuration() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(duration_seconds) as max_duration FROM dive_logs');
    if (result.isEmpty || result.first['max_duration'] == null) return null;
    return Duration(seconds: result.first['max_duration'] as int);
  }

  Future<Map<Discipline, int>> getLogCountByDiscipline() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT discipline, COUNT(*) as count FROM dive_logs GROUP BY discipline',
    );

    final Map<Discipline, int> counts = {};
    for (final row in result) {
      final discipline = Discipline.values.byName(row['discipline'] as String);
      counts[discipline] = row['count'] as int;
    }
    return counts;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('media_attachments');
    await db.delete('dive_logs');
  }

  // ==================== Media Attachment Operations ====================

  Future<void> insertMediaAttachment(MediaAttachment attachment) async {
    final db = await database;
    await db.insert(
      'media_attachments',
      _attachmentToMap(attachment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMediaAttachment(MediaAttachment attachment) async {
    final db = await database;
    await db.update(
      'media_attachments',
      _attachmentToMap(attachment),
      where: 'id = ?',
      whereArgs: [attachment.id],
    );
  }

  Future<void> deleteMediaAttachment(String id) async {
    final db = await database;
    await db.delete('media_attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MediaAttachment>> getMediaAttachmentsByLogId(String logId) async {
    final db = await database;
    final maps = await db.query(
      'media_attachments',
      where: 'log_id = ?',
      whereArgs: [logId],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => _mapToAttachment(map)).toList();
  }

  // ==================== Mapping Helpers ====================

  Map<String, dynamic> _logToMap(DiveLog log) {
    return {
      'id': log.id,
      'created_at': log.createdAt.toIso8601String(),
      'dive_date': log.diveDate.toIso8601String(),
      'location': log.location,
      'discipline': log.discipline.name,
      'depth': log.depth,
      'distance': log.distance,
      'duration_seconds': log.duration?.inSeconds,
      'mouthfill_depth': log.mouthfillDepth,
      'freefall_depth': log.freefallDepth,
      'weight': log.weight,
      'equipment': log.equipment,
      'condition': log.condition,
      'contractions': log.contractions,
      'tags': log.tags.isNotEmpty ? jsonEncode(log.tags) : null,
      'buddies': log.buddies.isNotEmpty ? jsonEncode(log.buddies) : null,
      'notes': log.notes,
      'raw_input': log.rawInput,
      'ai_parsed': log.aiParsed ? 1 : 0,
    };
  }

  DiveLog _mapToLog(Map<String, dynamic> map) {
    return DiveLog(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      diveDate: DateTime.parse(map['dive_date'] as String),
      location: map['location'] as String?,
      discipline: Discipline.values.byName(map['discipline'] as String),
      depth: (map['depth'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      duration: map['duration_seconds'] != null
          ? Duration(seconds: map['duration_seconds'] as int)
          : null,
      mouthfillDepth: (map['mouthfill_depth'] as num?)?.toDouble(),
      freefallDepth: (map['freefall_depth'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      equipment: map['equipment'] as String?,
      condition: map['condition'] as String?,
      contractions: map['contractions'] as int?,
      tags: map['tags'] != null
          ? (jsonDecode(map['tags'] as String) as List).cast<String>()
          : [],
      buddies: map['buddies'] != null
          ? (jsonDecode(map['buddies'] as String) as List).cast<String>()
          : [],
      notes: map['notes'] as String?,
      rawInput: map['raw_input'] as String?,
      aiParsed: (map['ai_parsed'] as int) == 1,
    );
  }

  Map<String, dynamic> _attachmentToMap(MediaAttachment attachment) {
    return {
      'id': attachment.id,
      'log_id': attachment.logId,
      'type': attachment.type.name,
      'file_path': attachment.filePath,
      'thumbnail_path': attachment.thumbnailPath,
      'comment': attachment.comment,
      'order_index': attachment.order,
      'created_at': attachment.createdAt.toIso8601String(),
    };
  }

  MediaAttachment _mapToAttachment(Map<String, dynamic> map) {
    return MediaAttachment(
      id: map['id'] as String,
      logId: map['log_id'] as String,
      type: MediaType.values.byName(map['type'] as String),
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      comment: map['comment'] as String?,
      order: map['order_index'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
