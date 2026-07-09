import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/models/dive_log.dart';
import 'package:freedive_coach/models/media_attachment.dart';
import 'package:freedive_coach/services/database_service.dart';

void main() {
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService();
    // Use in-memory database for testing
    await dbService.initForTesting();
  });

  tearDown(() async {
    await dbService.close();
  });

  group('DatabaseService', () {
    group('initialization', () {
      test('creates database successfully', () async {
        expect(dbService.isInitialized, true);
      });

      test('creates dive_logs table', () async {
        final tables = await dbService.getTableNames();
        expect(tables, contains('dive_logs'));
      });

      test('creates media_attachments table', () async {
        final tables = await dbService.getTableNames();
        expect(tables, contains('media_attachments'));
      });
    });

    group('insertLog', () {
      test('inserts a new log', () async {
        final log = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
          location: '제주 서귀포',
        );

        await dbService.insertLog(log);
        final logs = await dbService.getAllLogs();

        expect(logs.length, 1);
        expect(logs[0].id, log.id);
        expect(logs[0].depth, 32.0);
        expect(logs[0].location, '제주 서귀포');
      });

      test('inserts log with all fields', () async {
        final log = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
          location: '제주 서귀포',
          duration: const Duration(minutes: 2, seconds: 30),
          mouthfillDepth: 30.0,
          freefallDepth: 25.0,
          weight: 3.5,
          condition: '귀 타이트',
          tags: ['딥', '성공'],
          buddies: ['홍길동'],
          notes: '좋은 다이브',
          rawInput: '오늘 제주 서귀포에서 CWT 32m',
          aiParsed: true,
        );

        await dbService.insertLog(log);
        final logs = await dbService.getAllLogs();

        expect(logs[0].mouthfillDepth, 30.0);
        expect(logs[0].freefallDepth, 25.0);
        expect(logs[0].weight, 3.5);
        expect(logs[0].condition, '귀 타이트');
        expect(logs[0].tags, ['딥', '성공']);
        expect(logs[0].buddies, ['홍길동']);
        expect(logs[0].notes, '좋은 다이브');
        expect(logs[0].aiParsed, true);
      });
    });

    group('updateLog', () {
      test('updates existing log', () async {
        final log = DiveLog(
          id: 'test_123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 30.0,
        );

        await dbService.insertLog(log);

        final updatedLog = log.copyWith(depth: 35.0, location: '부산');
        await dbService.updateLog(updatedLog);

        final result = await dbService.getLogById('test_123');
        expect(result, isNotNull);
        expect(result!.depth, 35.0);
        expect(result.location, '부산');
      });
    });

    group('deleteLog', () {
      test('deletes log by id', () async {
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

        await dbService.insertLog(log1);
        await dbService.insertLog(log2);

        await dbService.deleteLog('to_delete');

        final logs = await dbService.getAllLogs();
        expect(logs.length, 1);
        expect(logs[0].id, 'to_keep');
      });

      test('deletes associated media attachments', () async {
        final log = DiveLog(
          id: 'log_with_media',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final attachment = MediaAttachment(
          id: 'media_1',
          logId: 'log_with_media',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        await dbService.insertLog(log);
        await dbService.insertMediaAttachment(attachment);

        await dbService.deleteLog('log_with_media');

        final attachments = await dbService.getMediaAttachmentsByLogId('log_with_media');
        expect(attachments, isEmpty);
      });
    });

    group('getLogById', () {
      test('returns log by id', () async {
        final log = DiveLog(
          id: 'target_123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        );

        await dbService.insertLog(log);

        final result = await dbService.getLogById('target_123');
        expect(result, isNotNull);
        expect(result!.id, 'target_123');
        expect(result.depth, 32.0);
      });

      test('returns null for non-existent id', () async {
        final result = await dbService.getLogById('non_existent');
        expect(result, isNull);
      });
    });

    group('getAllLogs', () {
      test('returns empty list when no logs', () async {
        final logs = await dbService.getAllLogs();
        expect(logs, isEmpty);
      });

      test('returns logs sorted by dive date descending', () async {
        await dbService.insertLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 5),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.cwt,
        ));

        final logs = await dbService.getAllLogs();
        expect(logs[0].id, '2'); // July 8 - most recent
        expect(logs[1].id, '3'); // July 6
        expect(logs[2].id, '1'); // July 5 - oldest
      });
    });

    group('getLogsByMonth', () {
      test('returns logs for specific month', () async {
        await dbService.insertLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 15),
          discipline: Discipline.fim,
        ));
        await dbService.insertLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 6, 20),
          discipline: Discipline.cnf,
        ));

        final julyLogs = await dbService.getLogsByMonth(2024, 7);
        expect(julyLogs.length, 2);
        expect(julyLogs.every((l) => l.diveDate.month == 7), true);

        final juneLogs = await dbService.getLogsByMonth(2024, 6);
        expect(juneLogs.length, 1);
        expect(juneLogs[0].id, '3');
      });

      test('returns empty list for month with no logs', () async {
        await dbService.insertLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));

        final logs = await dbService.getLogsByMonth(2024, 8);
        expect(logs, isEmpty);
      });
    });

    group('getLogsByDiscipline', () {
      test('returns logs for specific discipline', () async {
        await dbService.insertLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));
        await dbService.insertLog(DiveLog(
          id: '3',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 6),
          discipline: Discipline.cwt,
        ));

        final cwtLogs = await dbService.getLogsByDiscipline(Discipline.cwt);
        expect(cwtLogs.length, 2);
        expect(cwtLogs.every((l) => l.discipline == Discipline.cwt), true);
      });
    });

    group('getLogCount', () {
      test('returns total log count', () async {
        await dbService.insertLog(DiveLog(
          id: 'count_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: 'count_2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        final count = await dbService.getLogCount();
        expect(count, 2);
      });
    });

    group('getMaxDepth', () {
      test('returns maximum depth', () async {
        await dbService.insertLog(DiveLog(
          id: '1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 25.0,
        ));
        await dbService.insertLog(DiveLog(
          id: '2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.cwt,
          depth: 32.0,
        ));

        final maxDepth = await dbService.getMaxDepth();
        expect(maxDepth, 32.0);
      });

      test('returns null when no logs with depth', () async {
        final maxDepth = await dbService.getMaxDepth();
        expect(maxDepth, isNull);
      });
    });

    group('media attachments', () {
      test('inserts media attachment', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final attachment = MediaAttachment(
          id: 'media_1',
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/path/to/thumb.jpg',
          comment: 'Nice dive!',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        await dbService.insertLog(log);
        await dbService.insertMediaAttachment(attachment);

        final attachments = await dbService.getMediaAttachmentsByLogId('log_1');
        expect(attachments.length, 1);
        expect(attachments[0].filePath, '/path/to/photo.jpg');
        expect(attachments[0].comment, 'Nice dive!');
      });

      test('returns attachments sorted by order', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        await dbService.insertLog(log);
        await dbService.insertMediaAttachment(MediaAttachment(
          id: 'media_2',
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
          order: 1,
          createdAt: DateTime(2024, 7, 9),
        ));
        await dbService.insertMediaAttachment(MediaAttachment(
          id: 'media_1',
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        ));

        final attachments = await dbService.getMediaAttachmentsByLogId('log_1');
        expect(attachments[0].id, 'media_1');
        expect(attachments[1].id, 'media_2');
      });

      test('deletes media attachment', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final attachment = MediaAttachment(
          id: 'media_1',
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        await dbService.insertLog(log);
        await dbService.insertMediaAttachment(attachment);
        await dbService.deleteMediaAttachment('media_1');

        final attachments = await dbService.getMediaAttachmentsByLogId('log_1');
        expect(attachments, isEmpty);
      });
    });

    group('clearAllData', () {
      test('removes all logs and attachments', () async {
        await dbService.insertLog(DiveLog(
          id: 'clear_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        ));
        await dbService.insertLog(DiveLog(
          id: 'clear_2',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 7),
          discipline: Discipline.fim,
        ));

        await dbService.clearAllData();

        final logs = await dbService.getAllLogs();
        expect(logs, isEmpty);
      });
    });
  });
}
