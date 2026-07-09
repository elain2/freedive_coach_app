import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freedive_coach/models/dive_log.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/models/media_attachment.dart';
import 'package:freedive_coach/services/database_service.dart';
import 'package:freedive_coach/services/media_service.dart';

void main() {
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService dbService;
  late MediaService mediaService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.initForTesting();
    mediaService = MediaService(dbService: dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('MediaService', () {
    group('addAttachment', () {
      test('creates attachment record', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        final attachment = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
        );

        expect(attachment.logId, 'log_1');
        expect(attachment.type, MediaType.photo);
        expect(attachment.filePath, '/path/to/photo.jpg');
        expect(attachment.order, 0);
      });

      test('assigns correct order to multiple attachments', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        final second = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
        );
        final third = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.video,
          filePath: '/path/3.mp4',
        );

        expect(second.order, 1);
        expect(third.order, 2);
      });

      test('supports optional comment', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        final attachment = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          comment: 'Nice dive!',
        );

        expect(attachment.comment, 'Nice dive!');
      });
    });

    group('getAttachments', () {
      test('returns attachments for log', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
        );

        final attachments = await mediaService.getAttachments('log_1');

        expect(attachments.length, 2);
      });

      test('returns empty list for log with no attachments', () async {
        final attachments = await mediaService.getAttachments('nonexistent');

        expect(attachments, isEmpty);
      });

      test('returns attachments sorted by order', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
        );

        final attachments = await mediaService.getAttachments('log_1');

        expect(attachments[0].order, 0);
        expect(attachments[1].order, 1);
      });
    });

    group('updateAttachment', () {
      test('updates comment', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        final attachment = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );

        await mediaService.updateAttachment(
          attachment.copyWith(comment: 'Updated comment'),
        );

        final attachments = await mediaService.getAttachments('log_1');
        expect(attachments[0].comment, 'Updated comment');
      });
    });

    group('deleteAttachment', () {
      test('removes attachment record', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        final attachment = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );

        await mediaService.deleteAttachment(attachment.id);

        final attachments = await mediaService.getAttachments('log_1');
        expect(attachments, isEmpty);
      });
    });

    group('reorderAttachments', () {
      test('updates order of attachments', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        final first = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        final second = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
        );
        final third = await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/3.jpg',
        );

        // Reorder: [third, first, second]
        await mediaService.reorderAttachments(
          'log_1',
          [third.id, first.id, second.id],
        );

        final attachments = await mediaService.getAttachments('log_1');
        expect(attachments[0].id, third.id);
        expect(attachments[1].id, first.id);
        expect(attachments[2].id, second.id);
      });
    });

    group('getAttachmentCount', () {
      test('returns count of attachments for log', () async {
        final log = DiveLog(
          id: 'log_1',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        await dbService.insertLog(log);

        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        await mediaService.addAttachment(
          logId: 'log_1',
          type: MediaType.video,
          filePath: '/path/2.mp4',
        );

        final count = await mediaService.getAttachmentCount('log_1');
        expect(count, 2);
      });

      test('returns 0 for log with no attachments', () async {
        final count = await mediaService.getAttachmentCount('nonexistent');
        expect(count, 0);
      });
    });
  });
}
