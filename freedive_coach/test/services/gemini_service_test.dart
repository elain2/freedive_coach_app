import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/analysis_result.dart';
import 'package:freedive_coach/models/discipline.dart';
import 'package:freedive_coach/services/gemini_service.dart';

void main() {
  group('GeminiService', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    group('buildPrompt', () {
      test('creates prompt for CWT overview mode', () {
        final prompt = service.buildPrompt(
          discipline: Discipline.cwt,
          mode: AnalysisMode.overview,
        );

        expect(prompt, contains('콘스턴트 웨이트 (CWT)'));
        expect(prompt, contains('유선형'));
        expect(prompt, contains('핀 킥'));
        expect(prompt, contains('입수·자세'));
        expect(prompt, contains('이완'));
        expect(prompt, contains('JSON'));
        expect(prompt, contains('overall'));
        expect(prompt, contains('categories'));
      });

      test('creates prompt for segment mode', () {
        final prompt = service.buildPrompt(
          discipline: Discipline.cwt,
          mode: AnalysisMode.segment,
        );

        expect(prompt, contains('한 구간을 조밀하게 추출'));
      });

      test('creates prompt for overview mode', () {
        final prompt = service.buildPrompt(
          discipline: Discipline.cwt,
          mode: AnalysisMode.overview,
        );

        expect(prompt, contains('다이브 전체를 시간순으로 추출'));
      });

      test('creates prompt for FIM with pulling category', () {
        final prompt = service.buildPrompt(
          discipline: Discipline.fim,
          mode: AnalysisMode.overview,
        );

        expect(prompt, contains('프리 이머전 (FIM)'));
        expect(prompt, contains('풀링 테크닉'));
        expect(prompt, contains('다리 자세'));
      });

      test('creates prompt for CNF with kick and stroke', () {
        final prompt = service.buildPrompt(
          discipline: Discipline.cnf,
          mode: AnalysisMode.overview,
        );

        expect(prompt, contains('콘스턴트 노핀 (CNF)'));
        expect(prompt, contains('킥'));
        expect(prompt, contains('스트로크'));
      });
    });

    group('parseResponse', () {
      test('parses valid JSON response', () {
        const jsonResponse = '''
{
  "overall": "전반적으로 좋은 폼입니다.",
  "categories": [
    {"name": "유선형", "score": 4.5, "note": "머리 중립 유지", "tip": "팔을 더 뻗으세요"},
    {"name": "핀 킥", "score": 3.5, "note": "무릎 킥 보임", "tip": "고관절 사용"}
  ],
  "hook": "오늘도 성장 중!"
}
''';

        final result = service.parseResponse(jsonResponse);

        expect(result['overall'], '전반적으로 좋은 폼입니다.');
        expect(result['categories'], isA<List>());
        expect((result['categories'] as List).length, 2);
        expect(result['hook'], '오늘도 성장 중!');
      });

      test('parses JSON wrapped in markdown code block', () {
        const jsonResponse = '''
```json
{
  "overall": "good form",
  "categories": [],
  "hook": "nice"
}
```
''';

        final result = service.parseResponse(jsonResponse);

        expect(result['overall'], 'good form');
      });

      test('throws on invalid JSON', () {
        const invalidResponse = 'This is not JSON';

        expect(
          () => service.parseResponse(invalidResponse),
          throwsA(isA<GeminiParseException>()),
        );
      });
    });

    group('frameCountForDuration', () {
      test('returns 5 frames for <= 30 seconds', () {
        expect(GeminiService.frameCountForDuration(10), 5);
        expect(GeminiService.frameCountForDuration(30), 5);
      });

      test('returns 8 frames for <= 60 seconds', () {
        expect(GeminiService.frameCountForDuration(31), 8);
        expect(GeminiService.frameCountForDuration(60), 8);
      });

      test('returns 10 frames for <= 120 seconds', () {
        expect(GeminiService.frameCountForDuration(61), 10);
        expect(GeminiService.frameCountForDuration(120), 10);
      });

      test('returns 12 frames for > 120 seconds', () {
        expect(GeminiService.frameCountForDuration(121), 12);
        expect(GeminiService.frameCountForDuration(300), 12);
      });
    });

    group('isConfigured', () {
      test('returns false when API key is not set', () {
        final service = GeminiService();
        // Without setting the API key, it should return false
        expect(service.isConfigured, isFalse);
      });
    });

    group('validateFrames', () {
      test('throws when frames is empty', () {
        expect(
          () => service.validateFrames([]),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('throws when frames exceed max', () {
        final frames = List.generate(15, (i) => 'frame_$i');
        expect(
          () => service.validateFrames(frames),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('passes for valid frame count', () {
        final frames = List.generate(10, (i) => 'frame_$i');
        expect(
          () => service.validateFrames(frames),
          returnsNormally,
        );
      });
    });
  });
}
