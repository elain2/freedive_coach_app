import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';

/// Service for persisting analysis results to local storage
class AnalysisStorage {
  static const String _storageKey = 'analysis_results';
  static const int _maxResults = 50;

  /// Save an analysis result
  Future<void> saveResult(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getResults();

    // Remove existing result with same ID if exists
    results.removeWhere((r) => r.id == result.id);

    // Add new result at the beginning
    results.insert(0, result);

    // Keep only max results
    if (results.length > _maxResults) {
      results.removeRange(_maxResults, results.length);
    }

    // Save to storage
    final jsonList = results.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Get all saved analysis results (most recent first)
  Future<List<AnalysisResult>> getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => AnalysisResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent analysis results
  Future<List<AnalysisResult>> getRecentResults({int count = 5}) async {
    final results = await getResults();
    if (results.length <= count) return results;
    return results.sublist(0, count);
  }

  /// Get a specific analysis result by ID
  Future<AnalysisResult?> getResult(String id) async {
    final results = await getResults();
    try {
      return results.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete an analysis result by ID
  Future<void> deleteResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getResults();

    results.removeWhere((r) => r.id == id);

    final jsonList = results.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Clear all analysis results
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Get total count of analysis results
  Future<int> getCount() async {
    final results = await getResults();
    return results.length;
  }
}
