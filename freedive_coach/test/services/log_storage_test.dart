import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/models/dive_log.dart';
import 'package:freedive_coach/services/log_storage.dart';

void main() {
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LogStorage storage;

  setUp(() async {
    storage = LogStorage();
    await storage.initForTesting();
  });

  tearDown(() async {
    await storage.close();
  });

  group('LogStorage', () {
    group('saveLog', () {
      test('saves a new log', () async {
        final log = DiveLog(
          id: 'save_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        );

        await storage.saveLog(log);
        final logs = await storage.getLogs();

        expect(logs.length, 1);
        expect(logs[0].id, log.id);
        expect(logs[0].depth, 32.0);
      });

      test('updates existing log with same id', () async {
        final log = DiveLog(
          id: 'test_123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 30.0,
        );

        await storage.saveLog(log);

        final updatedLog = log.copyWith(depth: 35.0);
        await storage.saveLog(updatedLog);

        final logs = await storage.getLogs();
        expect(logs.length, 1);
        expect(logs[0].depth, 35.0);
      });

      test('sorts logs by dive date (most recent first)', () async {
        final log1 = DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 5),
          discipline: Discipline.cwt,
        );
        final log2 = DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final log3 = DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.cwt,
        );

        await storage.saveLog(log1);
        await storage.saveLog(log2);
        await storage.saveLog(log3);

        final logs = await storage.getLogs();
        expect(logs[0].id, '2'); // July 8 - most recent
        expect(logs[1].id, '3'); // July 6
        expect(logs[2].id, '1'); // July 5 - oldest
      });
    });

    group('getLogs', () {
      test('returns empty list when no logs', () async {
        final logs = await storage.getLogs();
        expect(logs, isEmpty);
      });

      test('returns all saved logs', () async {
        await storage.saveLog(DiveLog(
          id: 'all_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: 'all_2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        final logs = await storage.getLogs();
        expect(logs.length, 2);
      });
    });

    group('getLog', () {
      test('returns log by id', () async {
        final log = DiveLog(
          id: 'target_123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        );

        await storage.saveLog(log);
        await storage.saveLog(DiveLog(
          id: 'other_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        final result = await storage.getLog('target_123');
        expect(result, isNotNull);
        expect(result!.id, 'target_123');
        expect(result.depth, 32.0);
      });

      test('returns null for non-existent id', () async {
        await storage.saveLog(DiveLog(
          id: 'exists_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));

        final result = await storage.getLog('non_existent');
        expect(result, isNull);
      });
    });

    group('deleteLog', () {
      test('removes log by id', () async {
        final log1 = DiveLog(
          id: 'to_delete',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final log2 = DiveLog(
          id: 'to_keep',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        );

        await storage.saveLog(log1);
        await storage.saveLog(log2);

        await storage.deleteLog('to_delete');

        final logs = await storage.getLogs();
        expect(logs.length, 1);
        expect(logs[0].id, 'to_keep');
      });

      test('does nothing for non-existent id', () async {
        await storage.saveLog(DiveLog(
          id: 'existing_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));

        await storage.deleteLog('non_existent');

        final logs = await storage.getLogs();
        expect(logs.length, 1);
      });
    });

    group('getLogsByMonth', () {
      test('returns logs for specific month', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 15),
          discipline: Discipline.fim,
        ));
        await storage.saveLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 6, 20),
          discipline: Discipline.cnf,
        ));

        final julyLogs = await storage.getLogsByMonth(2024, 7);
        expect(julyLogs.length, 2);
        expect(julyLogs.every((l) => l.diveDate.month == 7), true);

        final juneLogs = await storage.getLogsByMonth(2024, 6);
        expect(juneLogs.length, 1);
        expect(juneLogs[0].id, '3');
      });

      test('returns empty list for month with no logs', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));

        final logs = await storage.getLogsByMonth(2024, 8);
        expect(logs, isEmpty);
      });
    });

    group('getLogsByDiscipline', () {
      test('returns logs for specific discipline', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));
        await storage.saveLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.cwt,
        ));

        final cwtLogs = await storage.getLogsByDiscipline(Discipline.cwt);
        expect(cwtLogs.length, 2);
        expect(cwtLogs.every((l) => l.discipline == Discipline.cwt), true);
      });
    });

    group('getRecentLogs', () {
      test('returns specified number of recent logs', () async {
        for (int i = 1; i <= 5; i++) {
          await storage.saveLog(DiveLog(
            id: '$i',
            createdAt: DateTime(2024, 7, 9),
            diveDate: DateTime(2024, 7, i),
            discipline: Discipline.cwt,
          ));
        }

        final recent = await storage.getRecentLogs(count: 3);
        expect(recent.length, 3);
      });

      test('returns all logs if count exceeds total', () async {
        await storage.saveLog(DiveLog(
          id: 'recent_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: 'recent_2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        final recent = await storage.getRecentLogs(count: 10);
        expect(recent.length, 2);
      });
    });

    group('clearAllLogs', () {
      test('removes all logs', () async {
        await storage.saveLog(DiveLog(
          id: 'clear_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: 'clear_2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        await storage.clearAllLogs();

        final logs = await storage.getLogs();
        expect(logs, isEmpty);
      });
    });

    group('getStats', () {
      test('returns zero stats when no logs', () async {
        final stats = await storage.getStats();

        expect(stats.totalLogs, 0);
        expect(stats.logsByDiscipline, isEmpty);
        expect(stats.maxDepth, isNull);
        expect(stats.maxDistance, isNull);
        expect(stats.maxDuration, isNull);
      });

      test('counts logs by discipline', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.cwt,
        ));
        await storage.saveLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.fim,
        ));

        final stats = await storage.getStats();

        expect(stats.totalLogs, 3);
        expect(stats.logsByDiscipline[Discipline.cwt], 2);
        expect(stats.logsByDiscipline[Discipline.fim], 1);
      });

      test('finds max depth', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 25.0,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.cwt,
          depth: 32.0,
        ));
        await storage.saveLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.fim,
          depth: 28.0,
        ));

        final stats = await storage.getStats();
        expect(stats.maxDepth, 32.0);
      });

      test('finds max distance', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.dyn,
          distance: 80.0,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.dyn,
          distance: 100.0,
        ));

        final stats = await storage.getStats();
        expect(stats.maxDistance, 100.0);
      });

      test('finds max duration', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 3),
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 5, seconds: 30),
        ));

        final stats = await storage.getStats();
        expect(stats.maxDuration, const Duration(minutes: 5, seconds: 30));
      });
    });

    group('getMonthlyStats', () {
      test('returns stats for specific month', () async {
        await storage.saveLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        ));
        await storage.saveLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 15),
          discipline: Discipline.cwt,
          depth: 28.0,
        ));
        await storage.saveLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 6, 20),
          discipline: Discipline.cwt,
          depth: 35.0,
        ));

        final julyStats = await storage.getMonthlyStats(2024, 7);
        expect(julyStats.year, 2024);
        expect(julyStats.month, 7);
        expect(julyStats.diveCount, 2);
        expect(julyStats.maxDepth, 32.0);

        final juneStats = await storage.getMonthlyStats(2024, 6);
        expect(juneStats.diveCount, 1);
        expect(juneStats.maxDepth, 35.0);
      });

      test('returns zero count for month with no logs', () async {
        final stats = await storage.getMonthlyStats(2024, 8);

        expect(stats.diveCount, 0);
        expect(stats.maxDepth, isNull);
      });
    });
  });

  group('MonthlyStats', () {
    test('monthFormatted returns Korean format', () {
      const stats = MonthlyStats(
        year: 2024,
        month: 7,
        diveCount: 5,
      );

      expect(stats.monthFormatted, '7월');
    });

    test('maxDepthFormatted returns formatted depth', () {
      const stats = MonthlyStats(
        year: 2024,
        month: 7,
        diveCount: 5,
        maxDepth: 32.5,
      );

      expect(stats.maxDepthFormatted, '33m');
    });

    test('maxDepthFormatted returns dash when null', () {
      const stats = MonthlyStats(
        year: 2024,
        month: 7,
        diveCount: 0,
      );

      expect(stats.maxDepthFormatted, '-');
    });
  });
}
