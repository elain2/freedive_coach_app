import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/media_attachment.dart';

void main() {
  group('MediaAttachment', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        final attachment = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        expect(attachment.id, '123');
        expect(attachment.logId, 'log_456');
        expect(attachment.type, MediaType.photo);
        expect(attachment.filePath, '/path/to/photo.jpg');
        expect(attachment.order, 0);
        expect(attachment.thumbnailPath, isNull);
        expect(attachment.comment, isNull);
      });

      test('creates instance with optional fields', () {
        final attachment = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.video,
          filePath: '/path/to/video.mp4',
          thumbnailPath: '/path/to/thumb.jpg',
          comment: 'Great dive!',
          order: 1,
          createdAt: DateTime(2024, 7, 9),
        );

        expect(attachment.thumbnailPath, '/path/to/thumb.jpg');
        expect(attachment.comment, 'Great dive!');
      });
    });

    group('create factory', () {
      test('generates unique id', () {
        final attachment1 = MediaAttachment.create(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );

        // Small delay to ensure different timestamp
        final attachment2 = MediaAttachment.create(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/2.jpg',
        );

        expect(attachment1.id, isNotEmpty);
        expect(attachment2.id, isNotEmpty);
      });

      test('sets createdAt to now', () {
        final before = DateTime.now();
        final attachment = MediaAttachment.create(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );
        final after = DateTime.now();

        expect(attachment.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(attachment.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('default order is 0', () {
        final attachment = MediaAttachment.create(
          logId: 'log_1',
          type: MediaType.photo,
          filePath: '/path/1.jpg',
        );

        expect(attachment.order, 0);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        final copied = original.copyWith(
          comment: 'New comment',
          order: 2,
        );

        expect(copied.id, '123'); // unchanged
        expect(copied.comment, 'New comment');
        expect(copied.order, 2);
        expect(copied.createdAt, DateTime(2024, 7, 9)); // unchanged
      });

      test('preserves original values when not specified', () {
        final original = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/thumb.jpg',
          comment: 'Original',
          order: 1,
          createdAt: DateTime(2024, 7, 9),
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.logId, original.logId);
        expect(copied.type, original.type);
        expect(copied.filePath, original.filePath);
        expect(copied.thumbnailPath, original.thumbnailPath);
        expect(copied.comment, original.comment);
        expect(copied.order, original.order);
      });
    });

    group('JSON serialization', () {
      test('toJson returns correct map', () {
        final attachment = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/thumb.jpg',
          comment: 'Test comment',
          order: 1,
          createdAt: DateTime(2024, 7, 9, 10, 30),
        );

        final json = attachment.toJson();

        expect(json['id'], '123');
        expect(json['logId'], 'log_456');
        expect(json['type'], 'photo');
        expect(json['filePath'], '/path/to/photo.jpg');
        expect(json['thumbnailPath'], '/thumb.jpg');
        expect(json['comment'], 'Test comment');
        expect(json['order'], 1);
        expect(json['createdAt'], '2024-07-09T10:30:00.000');
      });

      test('fromJson creates correct instance', () {
        final json = {
          'id': '123',
          'logId': 'log_456',
          'type': 'video',
          'filePath': '/path/to/video.mp4',
          'thumbnailPath': '/thumb.jpg',
          'comment': 'Test comment',
          'order': 2,
          'createdAt': '2024-07-09T10:30:00.000',
        };

        final attachment = MediaAttachment.fromJson(json);

        expect(attachment.id, '123');
        expect(attachment.logId, 'log_456');
        expect(attachment.type, MediaType.video);
        expect(attachment.filePath, '/path/to/video.mp4');
        expect(attachment.thumbnailPath, '/thumb.jpg');
        expect(attachment.comment, 'Test comment');
        expect(attachment.order, 2);
        expect(attachment.createdAt, DateTime(2024, 7, 9, 10, 30));
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': '123',
          'logId': 'log_456',
          'type': 'photo',
          'filePath': '/path/to/photo.jpg',
          'thumbnailPath': null,
          'comment': null,
          'order': 0,
          'createdAt': '2024-07-09T10:30:00.000',
        };

        final attachment = MediaAttachment.fromJson(json);

        expect(attachment.thumbnailPath, isNull);
        expect(attachment.comment, isNull);
      });

      test('round-trip serialization preserves data', () {
        final original = MediaAttachment(
          id: '123',
          logId: 'log_456',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/thumb.jpg',
          comment: 'Test comment',
          order: 1,
          createdAt: DateTime(2024, 7, 9, 10, 30),
        );

        final json = original.toJson();
        final restored = MediaAttachment.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.logId, original.logId);
        expect(restored.type, original.type);
        expect(restored.filePath, original.filePath);
        expect(restored.thumbnailPath, original.thumbnailPath);
        expect(restored.comment, original.comment);
        expect(restored.order, original.order);
        expect(restored.createdAt, original.createdAt);
      });
    });
  });

  group('MediaType', () {
    test('has photo and video values', () {
      expect(MediaType.values, contains(MediaType.photo));
      expect(MediaType.values, contains(MediaType.video));
      expect(MediaType.values.length, 2);
    });
  });
}
