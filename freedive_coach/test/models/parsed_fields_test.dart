import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/models/parsed_fields.dart';

void main() {
  group('ParsedFields', () {
    group('constructor', () {
      test('creates empty instance', () {
        final parsed = ParsedFields();

        expect(parsed.fields, isEmpty);
        expect(parsed.confidenceScores, isEmpty);
      });

      test('creates instance with fields', () {
        final parsed = ParsedFields(
          fields: {'location': '제주 서귀포', 'depth': 32},
          confidenceScores: {'location': 0.95, 'depth': 0.99},
        );

        expect(parsed.fields['location'], '제주 서귀포');
        expect(parsed.fields['depth'], 32);
        expect(parsed.confidenceScores['location'], 0.95);
      });
    });

    group('getters', () {
      test('location returns string value', () {
        final parsed = ParsedFields(
          fields: {'location': '제주 서귀포'},
        );

        expect(parsed.location, '제주 서귀포');
      });

      test('location returns null when not set', () {
        final parsed = ParsedFields();

        expect(parsed.location, isNull);
      });

      test('discipline returns Discipline enum', () {
        final parsed = ParsedFields(
          fields: {'discipline': 'cwt'},
        );

        expect(parsed.discipline, Discipline.cwt);
      });

      test('discipline handles uppercase', () {
        final parsed = ParsedFields(
          fields: {'discipline': 'CWT'},
        );

        expect(parsed.discipline, Discipline.cwt);
      });

      test('depth returns double value', () {
        final parsed = ParsedFields(
          fields: {'depth': 32},
        );

        expect(parsed.depth, 32.0);
      });

      test('depth handles string value', () {
        final parsed = ParsedFields(
          fields: {'depth': '28'},
        );

        expect(parsed.depth, 28.0);
      });

      test('distance returns double value', () {
        final parsed = ParsedFields(
          fields: {'distance': 100},
        );

        expect(parsed.distance, 100.0);
      });

      test('duration returns Duration', () {
        final parsed = ParsedFields(
          fields: {'durationMinutes': 3, 'durationSeconds': 30},
        );

        expect(parsed.duration, const Duration(minutes: 3, seconds: 30));
      });

      test('duration returns null when not set', () {
        final parsed = ParsedFields();

        expect(parsed.duration, isNull);
      });

      test('mouthfillDepth returns double', () {
        final parsed = ParsedFields(
          fields: {'mouthfillDepth': 25},
        );

        expect(parsed.mouthfillDepth, 25.0);
      });

      test('freefallDepth returns double', () {
        final parsed = ParsedFields(
          fields: {'freefallDepth': 20},
        );

        expect(parsed.freefallDepth, 20.0);
      });

      test('condition returns string', () {
        final parsed = ParsedFields(
          fields: {'condition': '귀 타이트'},
        );

        expect(parsed.condition, '귀 타이트');
      });

      test('date returns DateTime', () {
        final parsed = ParsedFields(
          fields: {'date': '2024-07-08'},
        );

        expect(parsed.date, DateTime(2024, 7, 8));
      });

      test('date handles DateTime object', () {
        final date = DateTime(2024, 7, 8);
        final parsed = ParsedFields(
          fields: {'date': date},
        );

        expect(parsed.date, date);
      });
    });

    group('confidence methods', () {
      test('getConfidence returns score for field', () {
        final parsed = ParsedFields(
          fields: {'location': '제주'},
          confidenceScores: {'location': 0.85},
        );

        expect(parsed.getConfidence('location'), 0.85);
      });

      test('getConfidence returns 0 for unknown field', () {
        final parsed = ParsedFields();

        expect(parsed.getConfidence('location'), 0.0);
      });

      test('isLowConfidence returns true when below threshold', () {
        final parsed = ParsedFields(
          fields: {'location': '제주'},
          confidenceScores: {'location': 0.65},
        );

        expect(parsed.isLowConfidence('location'), true);
      });

      test('isLowConfidence returns false when above threshold', () {
        final parsed = ParsedFields(
          fields: {'location': '제주'},
          confidenceScores: {'location': 0.85},
        );

        expect(parsed.isLowConfidence('location'), false);
      });

      test('lowConfidenceFields returns fields below threshold', () {
        final parsed = ParsedFields(
          fields: {'location': '제주', 'depth': 32, 'condition': '좋음'},
          confidenceScores: {'location': 0.65, 'depth': 0.95, 'condition': 0.50},
        );

        final lowFields = parsed.lowConfidenceFields;
        expect(lowFields, contains('location'));
        expect(lowFields, contains('condition'));
        expect(lowFields, isNot(contains('depth')));
      });
    });

    group('hasField', () {
      test('returns true when field exists', () {
        final parsed = ParsedFields(
          fields: {'location': '제주'},
        );

        expect(parsed.hasField('location'), true);
      });

      test('returns false when field does not exist', () {
        final parsed = ParsedFields();

        expect(parsed.hasField('location'), false);
      });

      test('returns false when field is null', () {
        final parsed = ParsedFields(
          fields: {'location': null},
        );

        expect(parsed.hasField('location'), false);
      });
    });

    group('copyWith', () {
      test('copies with new field', () {
        final original = ParsedFields(
          fields: {'location': '제주'},
          confidenceScores: {'location': 0.9},
        );

        final copied = original.copyWithField('depth', 32, confidence: 0.95);

        expect(copied.location, '제주');
        expect(copied.depth, 32.0);
        expect(copied.getConfidence('depth'), 0.95);
      });

      test('updates existing field', () {
        final original = ParsedFields(
          fields: {'depth': 28},
          confidenceScores: {'depth': 0.8},
        );

        final copied = original.copyWithField('depth', 32, confidence: 0.99);

        expect(copied.depth, 32.0);
        expect(copied.getConfidence('depth'), 0.99);
      });
    });

    group('toJson/fromJson', () {
      test('serializes to JSON', () {
        final parsed = ParsedFields(
          fields: {'location': '제주', 'depth': 32},
          confidenceScores: {'location': 0.9, 'depth': 0.95},
        );

        final json = parsed.toJson();

        expect(json['fields']['location'], '제주');
        expect(json['fields']['depth'], 32);
        expect(json['confidenceScores']['location'], 0.9);
      });

      test('deserializes from JSON', () {
        final json = {
          'fields': {'location': '제주', 'depth': 32},
          'confidenceScores': {'location': 0.9, 'depth': 0.95},
        };

        final parsed = ParsedFields.fromJson(json);

        expect(parsed.location, '제주');
        expect(parsed.depth, 32.0);
        expect(parsed.getConfidence('location'), 0.9);
      });

      test('round-trip preserves data', () {
        final original = ParsedFields(
          fields: {
            'location': '제주 서귀포',
            'discipline': 'cwt',
            'depth': 32,
            'condition': '좋음',
          },
          confidenceScores: {
            'location': 0.9,
            'discipline': 0.99,
            'depth': 0.95,
            'condition': 0.7,
          },
        );

        final json = original.toJson();
        final restored = ParsedFields.fromJson(json);

        expect(restored.location, original.location);
        expect(restored.depth, original.depth);
        expect(restored.getConfidence('location'), original.getConfidence('location'));
      });
    });

    group('fieldCount', () {
      test('returns number of non-null fields', () {
        final parsed = ParsedFields(
          fields: {'location': '제주', 'depth': 32, 'condition': null},
        );

        expect(parsed.fieldCount, 2);
      });

      test('returns 0 for empty fields', () {
        final parsed = ParsedFields();

        expect(parsed.fieldCount, 0);
      });
    });
  });
}
