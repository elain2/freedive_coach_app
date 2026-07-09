import '../models/dive_log.dart';
import '../models/discipline.dart';
import 'database_service.dart';

/// Service for persisting dive logs to local storage (SQLite)
class LogStorage {
  final DatabaseService _dbService;

  LogStorage({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  /// Initialize the storage
  Future<void> init() async {
    await _dbService.database;
  }

  /// Initialize with in-memory database for testing
  Future<void> initForTesting() async {
    await _dbService.initForTesting();
  }

  /// Save a dive log (insert or update)
  Future<void> saveLog(DiveLog log) async {
    final existing = await _dbService.getLogById(log.id);
    if (existing != null) {
      await _dbService.updateLog(log);
    } else {
      await _dbService.insertLog(log);
    }
  }

  /// Get all saved logs (most recent first)
  Future<List<DiveLog>> getLogs() async {
    return await _dbService.getAllLogs();
  }

  /// Get a specific log by ID
  Future<DiveLog?> getLog(String id) async {
    return await _dbService.getLogById(id);
  }

  /// Delete a log by ID
  Future<void> deleteLog(String id) async {
    await _dbService.deleteLog(id);
  }

  /// Get logs filtered by month
  Future<List<DiveLog>> getLogsByMonth(int year, int month) async {
    return await _dbService.getLogsByMonth(year, month);
  }

  /// Get logs filtered by discipline
  Future<List<DiveLog>> getLogsByDiscipline(Discipline discipline) async {
    return await _dbService.getLogsByDiscipline(discipline);
  }

  /// Get recent logs
  Future<List<DiveLog>> getRecentLogs({int count = 10}) async {
    return await _dbService.getRecentLogs(count: count);
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    await _dbService.clearAllData();
  }

  /// Get dive statistics
  Future<LogStats> getStats() async {
    final logCount = await _dbService.getLogCount();

    if (logCount == 0) {
      return const LogStats(
        totalLogs: 0,
        logsByDiscipline: {},
        maxDepth: null,
        maxDistance: null,
        maxDuration: null,
      );
    }

    final byDiscipline = await _dbService.getLogCountByDiscipline();
    final maxDepth = await _dbService.getMaxDepth();
    final maxDistance = await _dbService.getMaxDistance();
    final maxDuration = await _dbService.getMaxDuration();

    return LogStats(
      totalLogs: logCount,
      logsByDiscipline: byDiscipline,
      maxDepth: maxDepth,
      maxDistance: maxDistance,
      maxDuration: maxDuration,
    );
  }

  /// Get monthly statistics
  Future<MonthlyStats> getMonthlyStats(int year, int month) async {
    final logs = await getLogsByMonth(year, month);

    if (logs.isEmpty) {
      return MonthlyStats(
        year: year,
        month: month,
        diveCount: 0,
        maxDepth: null,
        maxDistance: null,
      );
    }

    double? maxDepth;
    double? maxDistance;

    for (final log in logs) {
      if (log.depth != null) {
        maxDepth = maxDepth == null ? log.depth : (log.depth! > maxDepth ? log.depth : maxDepth);
      }
      if (log.distance != null) {
        maxDistance = maxDistance == null ? log.distance : (log.distance! > maxDistance ? log.distance : maxDistance);
      }
    }

    return MonthlyStats(
      year: year,
      month: month,
      diveCount: logs.length,
      maxDepth: maxDepth,
      maxDistance: maxDistance,
    );
  }

  /// Close the database connection
  Future<void> close() async {
    await _dbService.close();
  }
}

/// Overall dive statistics
class LogStats {
  final int totalLogs;
  final Map<Discipline, int> logsByDiscipline;
  final double? maxDepth;
  final double? maxDistance;
  final Duration? maxDuration;

  const LogStats({
    required this.totalLogs,
    required this.logsByDiscipline,
    this.maxDepth,
    this.maxDistance,
    this.maxDuration,
  });
}

/// Monthly dive statistics
class MonthlyStats {
  final int year;
  final int month;
  final int diveCount;
  final double? maxDepth;
  final double? maxDistance;

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.diveCount,
    this.maxDepth,
    this.maxDistance,
  });

  String get monthFormatted => '$month월';

  String get maxDepthFormatted => maxDepth != null ? '${maxDepth!.toStringAsFixed(0)}m' : '-';
}
