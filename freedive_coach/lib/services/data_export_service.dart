import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/dive_log.dart';
import '../models/training_session.dart';
import '../models/analysis_result.dart';
import 'log_storage.dart';
import 'training_storage.dart';
import 'analysis_storage.dart';

enum ExportFormat { json, csv }

class DataExportService {
  final LogStorage _logStorage = LogStorage();
  final TrainingStorage _trainingStorage = TrainingStorage();
  final AnalysisStorage _analysisStorage = AnalysisStorage();

  /// Export all data to JSON format
  Future<String> exportToJson() async {
    final logs = await _logStorage.getLogs();
    final trainings = await _trainingStorage.getSessions();
    final analyses = await _analysisStorage.getResults();

    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'diveLogs': logs.map((l) => l.toJson()).toList(),
      'trainingSessions': trainings.map((t) => t.toJson()).toList(),
      'analysisResults': analyses.map((a) => a.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export dive logs to CSV format
  Future<String> exportLogsToCSV() async {
    final logs = await _logStorage.getLogs();

    final buffer = StringBuffer();

    // Header
    buffer.writeln('ID,Date,Discipline,Depth(m),Distance(m),Duration(sec),Location,MouthfillDepth,FreefallDepth,Weight,Condition,Notes');

    // Data rows
    for (final log in logs) {
      buffer.writeln([
        log.id,
        log.diveDate.toIso8601String(),
        log.discipline.name,
        log.depth?.toString() ?? '',
        log.distance?.toString() ?? '',
        log.duration?.inSeconds.toString() ?? '',
        _escapeCSV(log.location ?? ''),
        log.mouthfillDepth?.toString() ?? '',
        log.freefallDepth?.toString() ?? '',
        log.weight?.toString() ?? '',
        _escapeCSV(log.condition ?? ''),
        _escapeCSV(log.notes ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Export training sessions to CSV format
  Future<String> exportTrainingsToCSV() async {
    final trainings = await _trainingStorage.getSessions();

    final buffer = StringBuffer();

    // Header
    buffer.writeln('ID,Date,TableType,PersonalBest(sec),TotalRounds,CompletedRounds,IsCompleted');

    // Data rows
    for (final training in trainings) {
      buffer.writeln([
        training.id,
        training.startedAt.toIso8601String(),
        training.tableType.name,
        training.personalBest.inSeconds.toString(),
        training.totalRounds.toString(),
        training.completedRounds.toString(),
        training.isCompleted.toString(),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Save and share JSON export file
  Future<void> shareJsonExport() async {
    final jsonData = await exportToJson();
    await _shareFile(jsonData, 'divingcat_backup.json', 'application/json');
  }

  /// Save and share CSV export files
  Future<void> shareCSVExport() async {
    final logsCSV = await exportLogsToCSV();
    await _shareFile(logsCSV, 'divingcat_logs.csv', 'text/csv');
  }

  /// Import data from JSON
  Future<ImportResult> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      int logsImported = 0;
      int trainingsImported = 0;
      int analysesImported = 0;

      // Import dive logs
      if (data['diveLogs'] != null) {
        final logsList = data['diveLogs'] as List;
        for (final logJson in logsList) {
          try {
            final log = DiveLog.fromJson(logJson as Map<String, dynamic>);
            await _logStorage.saveLog(log);
            logsImported++;
          } catch (e) {
            // Skip invalid entries
          }
        }
      }

      // Import training sessions
      if (data['trainingSessions'] != null) {
        final trainingsList = data['trainingSessions'] as List;
        for (final trainingJson in trainingsList) {
          try {
            final training = TrainingSession.fromJson(trainingJson as Map<String, dynamic>);
            await _trainingStorage.saveSession(training);
            trainingsImported++;
          } catch (e) {
            // Skip invalid entries
          }
        }
      }

      // Import analysis results
      if (data['analysisResults'] != null) {
        final analysesList = data['analysisResults'] as List;
        for (final analysisJson in analysesList) {
          try {
            final analysis = AnalysisResult.fromJson(analysisJson as Map<String, dynamic>);
            await _analysisStorage.saveResult(analysis);
            analysesImported++;
          } catch (e) {
            // Skip invalid entries
          }
        }
      }

      return ImportResult(
        success: true,
        logsImported: logsImported,
        trainingsImported: trainingsImported,
        analysesImported: analysesImported,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Helper to escape CSV values
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Helper to share a file
  Future<void> _shareFile(String content, String filename, String mimeType) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'DivingCat Data Export',
    );
  }
}

class ImportResult {
  final bool success;
  final int logsImported;
  final int trainingsImported;
  final int analysesImported;
  final String? error;

  const ImportResult({
    required this.success,
    this.logsImported = 0,
    this.trainingsImported = 0,
    this.analysesImported = 0,
    this.error,
  });

  int get totalImported => logsImported + trainingsImported + analysesImported;
}
