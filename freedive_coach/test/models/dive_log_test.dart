import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/models/dive_log.dart';
import 'package:freedive_coach/models/media_attachment.dart';

void main() {
  group('DiveLog', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        expect(log.id, '123');
        expect(log.diveDate, DateTime(2024, 7, 8));
        expect(log.discipline, Discipline.cwt);
        expect(log.location, isNull);
        expect(log.depth, isNull);
        expect(log.tags, isEmpty);
        expect(log.media, isEmpty);
      });

      test('creates instance with all fields', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          location: '제주 서귀포',
          depth: 32.0,
          duration: const Duration(minutes: 2, seconds: 30),
          mouthfillDepth: 30.0,
          freefallDepth: 25.0,
          weight: 3.5,
          condition: '귀 타이트',
          tags: ['딥', '성공'],
          buddies: ['홍길동'],
          notes: '좋은 다이브',
        );

        expect(log.location, '제주 서귀포');
        expect(log.depth, 32.0);
        expect(log.duration, const Duration(minutes: 2, seconds: 30));
        expect(log.mouthfillDepth, 30.0);
        expect(log.freefallDepth, 25.0);
        expect(log.weight, 3.5);
        expect(log.condition, '귀 타이트');
        expect(log.tags, ['딥', '성공']);
        expect(log.buddies, ['홍길동']);
        expect(log.notes, '좋은 다이브');
      });
    });

    group('create factory', () {
      test('generates unique id', () {
        final log1 = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final log2 = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        expect(log1.id, isNotEmpty);
        expect(log2.id, isNotEmpty);
      });

      test('sets createdAt to now', () {
        final before = DateTime.now();
        final log = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );
        final after = DateTime.now();

        expect(log.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(log.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('defaults aiParsed to false', () {
        final log = DiveLog.create(
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        expect(log.aiParsed, false);
      });
    });

    group('primaryMetric', () {
      test('returns depth for depth disciplines', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        );

        expect(log.primaryMetric, 32.0);
      });

      test('returns distance for distance disciplines', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.dyn,
          distance: 100.0,
        );

        expect(log.primaryMetric, 100.0);
      });

      test('returns null for time disciplines', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 5),
        );

        expect(log.primaryMetric, isNull);
      });
    });

    group('primaryMetricFormatted', () {
      test('formats depth with unit', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 32.0,
        );

        expect(log.primaryMetricFormatted, '32m');
      });

      test('returns formatted duration for STA', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 5, seconds: 30),
        );

        expect(log.primaryMetricFormatted, '5:30');
      });

      test('returns dash when no value', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        expect(log.primaryMetricFormatted, '-');
      });
    });

    group('durationFormatted', () {
      test('formats duration as mm:ss', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 3, seconds: 45),
        );

        expect(log.durationFormatted, '3:45');
      });

      test('pads seconds with zero', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
          duration: const Duration(minutes: 2, seconds: 5),
        );

        expect(log.durationFormatted, '2:05');
      });

      test('returns dash when no duration', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.sta,
        );

        expect(log.durationFormatted, '-');
      });
    });

    group('diveDateFormatted', () {
      test('formats date in Korean style', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        expect(log.diveDateFormatted, '7월 8일');
      });

      test('handles single digit month and day', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 1, 5),
          diveDate: DateTime(2024, 1, 5),
          discipline: Discipline.cwt,
        );

        expect(log.diveDateFormatted, '1월 5일');
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          depth: 30.0,
        );

        final copied = original.copyWith(
          depth: 35.0,
          location: '제주',
        );

        expect(copied.id, '123'); // unchanged
        expect(copied.depth, 35.0);
        expect(copied.location, '제주');
        expect(copied.discipline, Discipline.cwt); // unchanged
      });

      test('preserves id and createdAt', () {
        final original = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9, 10, 30),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
        );

        final copied = original.copyWith(depth: 40.0);

        expect(copied.id, '123');
        expect(copied.createdAt, DateTime(2024, 7, 9, 10, 30));
      });
    });

    group('JSON serialization', () {
      test('toJson returns correct map', () {
        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9, 10, 30),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          location: '제주',
          depth: 32.0,
          duration: const Duration(minutes: 2, seconds: 30),
          mouthfillDepth: 30.0,
          freefallDepth: 25.0,
          tags: ['딥'],
          aiParsed: true,
        );

        final json = log.toJson();

        expect(json['id'], '123');
        expect(json['createdAt'], '2024-07-09T10:30:00.000');
        expect(json['diveDate'], '2024-07-08T00:00:00.000');
        expect(json['discipline'], 'cwt');
        expect(json['location'], '제주');
        expect(json['depth'], 32.0);
        expect(json['durationSeconds'], 150);
        expect(json['mouthfillDepth'], 30.0);
        expect(json['freefallDepth'], 25.0);
        expect(json['tags'], ['딥']);
        expect(json['aiParsed'], true);
      });

      test('fromJson creates correct instance', () {
        final json = {
          'id': '123',
          'createdAt': '2024-07-09T10:30:00.000',
          'diveDate': '2024-07-08T00:00:00.000',
          'discipline': 'fim',
          'location': '부산',
          'depth': 28.0,
          'durationSeconds': 120,
          'mouthfillDepth': 25.0,
          'freefallDepth': 20.0,
          'tags': ['훈련'],
          'buddies': ['김철수'],
          'aiParsed': false,
          'media': [],
        };

        final log = DiveLog.fromJson(json);

        expect(log.id, '123');
        expect(log.discipline, Discipline.fim);
        expect(log.location, '부산');
        expect(log.depth, 28.0);
        expect(log.duration, const Duration(minutes: 2));
        expect(log.tags, ['훈련']);
        expect(log.buddies, ['김철수']);
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': '123',
          'createdAt': '2024-07-09T10:30:00.000',
          'diveDate': '2024-07-08T00:00:00.000',
          'discipline': 'cwt',
          'location': null,
          'depth': null,
          'durationSeconds': null,
          'tags': null,
          'buddies': null,
          'media': null,
        };

        final log = DiveLog.fromJson(json);

        expect(log.location, isNull);
        expect(log.depth, isNull);
        expect(log.duration, isNull);
        expect(log.tags, isEmpty);
        expect(log.buddies, isEmpty);
        expect(log.media, isEmpty);
      });

      test('round-trip serialization preserves data', () {
        final original = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9, 10, 30),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          location: '제주',
          depth: 32.0,
          duration: const Duration(minutes: 2, seconds: 30),
          mouthfillDepth: 30.0,
          freefallDepth: 25.0,
          weight: 3.5,
          condition: '좋음',
          tags: ['딥', '성공'],
          buddies: ['홍길동'],
          notes: '좋은 다이브',
          aiParsed: true,
        );

        final json = original.toJson();
        final restored = DiveLog.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.createdAt, original.createdAt);
        expect(restored.diveDate, original.diveDate);
        expect(restored.discipline, original.discipline);
        expect(restored.location, original.location);
        expect(restored.depth, original.depth);
        expect(restored.duration, original.duration);
        expect(restored.mouthfillDepth, original.mouthfillDepth);
        expect(restored.freefallDepth, original.freefallDepth);
        expect(restored.weight, original.weight);
        expect(restored.condition, original.condition);
        expect(restored.tags, original.tags);
        expect(restored.buddies, original.buddies);
        expect(restored.notes, original.notes);
        expect(restored.aiParsed, original.aiParsed);
      });

      test('serializes media attachments', () {
        final attachment = MediaAttachment(
          id: 'media_1',
          logId: '123',
          type: MediaType.photo,
          filePath: '/path/to/photo.jpg',
          order: 0,
          createdAt: DateTime(2024, 7, 9),
        );

        final log = DiveLog(
          id: '123',
          createdAt: DateTime(2024, 7, 9),
          diveDate: DateTime(2024, 7, 8),
          discipline: Discipline.cwt,
          media: [attachment],
        );

        final json = log.toJson();
        expect(json['media'], isA<List>());
        expect((json['media'] as List).length, 1);

        final restored = DiveLog.fromJson(json);
        expect(restored.media.length, 1);
        expect(restored.media[0].id, 'media_1');
      });
    });
  });
}
