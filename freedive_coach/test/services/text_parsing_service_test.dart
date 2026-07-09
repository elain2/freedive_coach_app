import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/services/text_parsing_service.dart';

void main() {
  late TextParsingService service;

  setUp(() {
    service = TextParsingService();
  });

  group('TextParsingService', () {
    group('parseText', () {
      test('parses complete dive log text', () {
        final result = service.parseText(
          '오늘 제주 서귀포에서 CWT 32m 성공, 마우스필 30m, 프리폴 25m',
        );

        expect(result.location, '제주 서귀포');
        expect(result.discipline, Discipline.cwt);
        expect(result.depth, 32.0);
        expect(result.mouthfillDepth, 30.0);
        expect(result.freefallDepth, 25.0);
      });

      test('parses minimal dive log', () {
        final result = service.parseText('CWT 28m');

        expect(result.discipline, Discipline.cwt);
        expect(result.depth, 28.0);
      });

      test('returns empty ParsedFields for empty text', () {
        final result = service.parseText('');

        expect(result.fieldCount, 0);
      });
    });

    group('parseDiscipline', () {
      test('parses CWT', () {
        expect(service.parseText('CWT 30m').discipline, Discipline.cwt);
        expect(service.parseText('cwt 30m').discipline, Discipline.cwt);
        expect(service.parseText('콘스탄트 30m').discipline, Discipline.cwt);
      });

      test('parses CNF', () {
        expect(service.parseText('CNF 25m').discipline, Discipline.cnf);
        expect(service.parseText('노핀 25m').discipline, Discipline.cnf);
      });

      test('parses FIM', () {
        expect(service.parseText('FIM 28m').discipline, Discipline.fim);
        expect(service.parseText('프리이머전 28m').discipline, Discipline.fim);
      });

      test('parses DYN', () {
        expect(service.parseText('DYN 100m').discipline, Discipline.dyn);
        expect(service.parseText('다이나믹 100m').discipline, Discipline.dyn);
      });

      test('parses DNF', () {
        expect(service.parseText('DNF 75m').discipline, Discipline.dnf);
        expect(service.parseText('다이나믹 노핀 75m').discipline, Discipline.dnf);
      });

      test('parses STA', () {
        expect(service.parseText('STA 5분').discipline, Discipline.sta);
        expect(service.parseText('스태틱 5분').discipline, Discipline.sta);
      });
    });

    group('parseDepth', () {
      test('parses depth with m suffix', () {
        expect(service.parseText('32m').depth, 32.0);
        expect(service.parseText('32M').depth, 32.0);
        expect(service.parseText('32미터').depth, 32.0);
      });

      test('parses depth with 수심 prefix', () {
        expect(service.parseText('수심 28m').depth, 28.0);
        expect(service.parseText('수심28m').depth, 28.0);
      });

      test('parses decimal depth', () {
        expect(service.parseText('32.5m').depth, 32.5);
      });

      test('distinguishes depth from distance for DYN', () {
        final result = service.parseText('DYN 거리 100m');
        expect(result.distance, 100.0);
      });
    });

    group('parseLocation', () {
      test('parses location with 에서 suffix', () {
        expect(service.parseText('제주 서귀포에서 CWT').location, '제주 서귀포');
        expect(service.parseText('부산 기장에서 다이빙').location, '부산 기장');
      });

      test('parses location with common keywords', () {
        expect(service.parseText('제주 협재 CWT 30m').location, '제주 협재');
        expect(service.parseText('필리핀 모알보알에서').location, '필리핀 모알보알');
      });
    });

    group('parseTechnique', () {
      test('parses mouthfill depth', () {
        expect(service.parseText('마우스필 30m').mouthfillDepth, 30.0);
        expect(service.parseText('MF 30m').mouthfillDepth, 30.0);
        expect(service.parseText('마필 30m').mouthfillDepth, 30.0);
      });

      test('parses freefall depth', () {
        expect(service.parseText('프리폴 25m').freefallDepth, 25.0);
        expect(service.parseText('FF 25m').freefallDepth, 25.0);
        expect(service.parseText('프리폴링 25m').freefallDepth, 25.0);
      });
    });

    group('parseDuration', () {
      test('parses minutes and seconds', () {
        final result = service.parseText('STA 3분 30초');
        expect(result.duration, const Duration(minutes: 3, seconds: 30));
      });

      test('parses minutes only', () {
        final result = service.parseText('STA 5분');
        expect(result.duration, const Duration(minutes: 5));
      });

      test('parses colon format', () {
        final result = service.parseText('STA 3:45');
        expect(result.duration, const Duration(minutes: 3, seconds: 45));
      });
    });

    group('parseCondition', () {
      test('parses ear condition', () {
        expect(service.parseText('귀 타이트').condition, contains('귀'));
        expect(service.parseText('이퀄 힘들었어').condition, contains('이퀄'));
      });

      test('parses contraction', () {
        expect(service.parseText('컨트랙션 있었음').condition, contains('컨트랙션'));
      });
    });

    group('parseDate', () {
      test('parses today', () {
        final result = service.parseText('오늘 CWT 30m');
        final today = DateTime.now();
        expect(result.date?.day, today.day);
        expect(result.date?.month, today.month);
      });

      test('parses yesterday', () {
        final result = service.parseText('어제 CWT 30m');
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(result.date?.day, yesterday.day);
      });

      test('parses explicit date', () {
        final result = service.parseText('7월 8일 CWT 30m');
        expect(result.date?.month, 7);
        expect(result.date?.day, 8);
      });
    });

    group('confidence scores', () {
      test('assigns high confidence to explicit matches', () {
        final result = service.parseText('CWT 32m');

        expect(result.getConfidence('discipline'), greaterThanOrEqualTo(0.9));
        expect(result.getConfidence('depth'), greaterThanOrEqualTo(0.9));
      });

      test('assigns lower confidence to inferred values', () {
        final result = service.parseText('제주에서 30m');

        // Location from context has slightly lower confidence
        expect(result.getConfidence('location'), lessThan(1.0));
      });
    });

    group('complex inputs', () {
      test('parses multiple pieces of information', () {
        final result = service.parseText(
          '오늘 제주 협재에서 CWT 32m 성공! 마우스필 28m, 프리폴 22m, 귀 약간 타이트했음',
        );

        expect(result.location, '제주 협재');
        expect(result.discipline, Discipline.cwt);
        expect(result.depth, 32.0);
        expect(result.mouthfillDepth, 28.0);
        expect(result.freefallDepth, 22.0);
        expect(result.condition, isNotNull);
      });

      test('handles DYN with distance', () {
        final result = service.parseText('다이나믹 100m 달성, 컨트랙션 3번');

        expect(result.discipline, Discipline.dyn);
        expect(result.distance, 100.0);
      });

      test('handles STA with duration', () {
        final result = service.parseText('스태틱 5분 30초 성공');

        expect(result.discipline, Discipline.sta);
        expect(result.duration, const Duration(minutes: 5, seconds: 30));
      });
    });
  });
}
