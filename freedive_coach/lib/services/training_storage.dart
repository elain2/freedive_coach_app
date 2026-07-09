import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/breathing_table.dart';
import '../models/training_session.dart';

/// Service for persisting training sessions to local storage
class TrainingStorage {
  static const String _sessionsKey = 'training_sessions';
  static const int _maxSessions = 100; // Keep last 100 sessions

  SharedPreferences? _prefs;

  /// Initialize the storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure storage is initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Save a training session
  Future<void> saveSession(TrainingSession session) async {
    final prefs = await _getPrefs();
    final sessions = await getSessions();

    // Add new session at the beginning
    sessions.insert(0, session);

    // Keep only the most recent sessions
    final trimmedSessions = sessions.take(_maxSessions).toList();

    // Serialize and save
    final jsonList = trimmedSessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(jsonList));
  }

  /// Get all saved sessions (most recent first)
  Future<List<TrainingSession>> getSessions() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_sessionsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => TrainingSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's a parsing error, return empty list
      return [];
    }
  }

  /// Get sessions filtered by table type
  Future<List<TrainingSession>> getSessionsByType(TableType type) async {
    final sessions = await getSessions();
    return sessions.where((s) => s.tableType == type).toList();
  }

  /// Get recent sessions (last n)
  Future<List<TrainingSession>> getRecentSessions({int count = 5}) async {
    final sessions = await getSessions();
    return sessions.take(count).toList();
  }

  /// Delete a session by ID
  Future<void> deleteSession(String sessionId) async {
    final prefs = await _getPrefs();
    final sessions = await getSessions();

    sessions.removeWhere((s) => s.id == sessionId);

    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(jsonList));
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    final prefs = await _getPrefs();
    await prefs.remove(_sessionsKey);
  }

  /// Get training statistics
  Future<TrainingStats> getStats() async {
    final sessions = await getSessions();
    final completedSessions = sessions.where((s) => s.isCompleted).toList();

    return TrainingStats(
      totalSessions: sessions.length,
      completedSessions: completedSessions.length,
      co2Sessions: sessions.where((s) => s.tableType == TableType.co2).length,
      o2Sessions: sessions.where((s) => s.tableType == TableType.o2).length,
    );
  }
}

/// Training statistics
class TrainingStats {
  final int totalSessions;
  final int completedSessions;
  final int co2Sessions;
  final int o2Sessions;

  const TrainingStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.co2Sessions,
    required this.o2Sessions,
  });

  double get completionRate {
    if (totalSessions == 0) return 0;
    return completedSessions / totalSessions;
  }
}
