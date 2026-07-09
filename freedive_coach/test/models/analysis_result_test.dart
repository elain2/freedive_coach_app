import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/analysis_result.dart';
import 'package:freedive_coach/models/discipline.dart';

void main() {
  group('CategoryResult', () {
    test('constructor creates instance with all fields', () {
      final result = CategoryResult(
        name: '유선형',
        score: 4.5,
        note: '머리 중립 유지 잘함',
        tip: '팔을 더 뻗어보세요',
      );

      expect(result.name, '유선형');
      expect(result.score, 4.5);
      expect(result.note, '머리 중립 유지 잘함');
      expect(result.tip, '팔을 더 뻗어보세요');
    });

    test('toJson returns correct map', () {
      final result = CategoryResult(
        name: '핀 킥',
        score: 3.5,
        note: '무릎 킥 보임',
        tip: '고관절 사용 연습',
      );

      final json = result.toJson();

      expect(json['name'], '핀 킥');
      expect(json['score'], 3.5);
      expect(json['note'], '무릎 킥 보임');
      expect(json['tip'], '고관절 사용 연습');
    });

    test('fromJson creates correct instance', () {
      final json = {
        'name': '이완',
        'score': 5.0,
        'note': '전반적으로 이완 좋음',
        'tip': '현재 상태 유지',
      };

      final result = CategoryResult.fromJson(json);

      expect(result.name, '이완');
      expect(result.score, 5.0);
      expect(result.note, '전반적으로 이완 좋음');
      expect(result.tip, '현재 상태 유지');
    });

    test('fromJson handles int score', () {
      final json = {
        'name': '입수',
        'score': 4,
        'note': '덕다이브 양호',
        'tip': '다리 정렬 주의',
      };

      final result = CategoryResult.fromJson(json);

      expect(result.score, 4.0);
    });
  });

  group('AnalysisResult', () {
    test('constructor creates instance with all fields', () {
      final categories = [
        CategoryResult(name: '유선형', score: 4.0, note: 'good', tip: 'keep'),
        CategoryResult(name: '핀 킥', score: 3.5, note: 'ok', tip: 'improve'),
      ];

      final result = AnalysisResult(
        id: 'analysis_1',
        requestId: 'request_1',
        discipline: Discipline.cwt,
        mode: AnalysisMode.overview,
        overall: '전반적으로 좋은 폼입니다.',
        categories: categories,
        hook: '오늘도 성장 중!',
        createdAt: DateTime(2024, 7, 9),
      );

      expect(result.id, 'analysis_1');
      expect(result.requestId, 'request_1');
      expect(result.discipline, Discipline.cwt);
      expect(result.mode, AnalysisMode.overview);
      expect(result.overall, '전반적으로 좋은 폼입니다.');
      expect(result.categories.length, 2);
      expect(result.hook, '오늘도 성장 중!');
    });

    test('averageScore calculates correctly', () {
      final result = AnalysisResult(
        id: 'analysis_1',
        requestId: 'request_1',
        discipline: Discipline.cwt,
        mode: AnalysisMode.overview,
        overall: 'good',
        categories: [
          CategoryResult(name: 'a', score: 4.0, note: '', tip: ''),
          CategoryResult(name: 'b', score: 3.0, note: '', tip: ''),
          CategoryResult(name: 'c', score: 5.0, note: '', tip: ''),
        ],
        hook: 'test',
        createdAt: DateTime.now(),
      );

      expect(result.averageScore, 4.0);
    });

    test('averageScore returns 0 for empty categories', () {
      final result = AnalysisResult(
        id: 'analysis_1',
        requestId: 'request_1',
        discipline: Discipline.cwt,
        mode: AnalysisMode.overview,
        overall: 'good',
        categories: [],
        hook: 'test',
        createdAt: DateTime.now(),
      );

      expect(result.averageScore, 0.0);
    });

    test('toJson returns correct map', () {
      final result = AnalysisResult(
        id: 'analysis_1',
        requestId: 'request_1',
        discipline: Discipline.cwt,
        mode: AnalysisMode.segment,
        overall: 'good form',
        categories: [
          CategoryResult(name: 'test', score: 4.0, note: 'note', tip: 'tip'),
        ],
        hook: 'hook text',
        createdAt: DateTime(2024, 7, 9, 10, 30),
        linkedLogId: 'log_1',
        videoPath: '/path/to/video.mp4',
        thumbnailPath: '/path/to/thumb.jpg',
      );

      final json = result.toJson();

      expect(json['id'], 'analysis_1');
      expect(json['requestId'], 'request_1');
      expect(json['discipline'], 'cwt');
      expect(json['mode'], 'segment');
      expect(json['overall'], 'good form');
      expect(json['categories'], isA<List>());
      expect(json['hook'], 'hook text');
      expect(json['linkedLogId'], 'log_1');
      expect(json['videoPath'], '/path/to/video.mp4');
      expect(json['thumbnailPath'], '/path/to/thumb.jpg');
    });

    test('fromJson creates correct instance', () {
      final json = {
        'id': 'analysis_2',
        'requestId': 'request_2',
        'discipline': 'fim',
        'mode': 'overview',
        'overall': 'excellent',
        'categories': [
          {'name': 'streamline', 'score': 4.5, 'note': 'good', 'tip': 'keep'},
        ],
        'hook': 'nice dive!',
        'createdAt': '2024-07-09T10:30:00.000',
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.id, 'analysis_2');
      expect(result.discipline, Discipline.fim);
      expect(result.mode, AnalysisMode.overview);
      expect(result.categories.length, 1);
      expect(result.categories[0].name, 'streamline');
    });

    test('copyWith creates copy with updated fields', () {
      final original = AnalysisResult(
        id: 'analysis_1',
        requestId: 'request_1',
        discipline: Discipline.cwt,
        mode: AnalysisMode.overview,
        overall: 'good',
        categories: [],
        hook: 'test',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(linkedLogId: 'log_123');

      expect(updated.linkedLogId, 'log_123');
      expect(updated.id, original.id);
      expect(updated.discipline, original.discipline);
    });
  });

  group('AnalysisMode', () {
    test('has overview and segment values', () {
      expect(AnalysisMode.values, contains(AnalysisMode.overview));
      expect(AnalysisMode.values, contains(AnalysisMode.segment));
    });
  });

  group('Rubric', () {
    test('CWT rubric has correct categories', () {
      final rubric = Rubric.forDiscipline(Discipline.cwt);

      expect(rubric, isNotNull);
      expect(rubric!.id, Discipline.cwt);
      expect(rubric.label, '콘스턴트 웨이트 (CWT)');
      expect(rubric.categories.length, 4);
      expect(rubric.categories.map((c) => c.id).toList(),
          ['streamline', 'finning', 'entry', 'relax']);
    });

    test('FIM rubric has correct categories', () {
      final rubric = Rubric.forDiscipline(Discipline.fim);

      expect(rubric, isNotNull);
      expect(rubric!.categories.length, 5);
      expect(rubric.categories.map((c) => c.id).toList(),
          ['streamline', 'pulling', 'entry', 'legs', 'relax']);
    });

    test('CNF rubric has correct categories', () {
      final rubric = Rubric.forDiscipline(Discipline.cnf);

      expect(rubric, isNotNull);
      expect(rubric!.categories.length, 5);
      expect(rubric.categories.map((c) => c.id).toList(),
          ['streamline', 'kick', 'stroke', 'entry', 'relax']);
    });

    test('DYN and STA rubrics are not yet supported', () {
      expect(Rubric.forDiscipline(Discipline.dyn), isNull);
      expect(Rubric.forDiscipline(Discipline.sta), isNull);
    });

    test('supportedDisciplines returns CWT, FIM, CNF', () {
      final supported = Rubric.supportedDisciplines;

      expect(supported, contains(Discipline.cwt));
      expect(supported, contains(Discipline.fim));
      expect(supported, contains(Discipline.cnf));
      expect(supported, isNot(contains(Discipline.dyn)));
      expect(supported, isNot(contains(Discipline.sta)));
    });

    test('categoryLabels returns list of labels', () {
      final rubric = Rubric.forDiscipline(Discipline.cwt);

      expect(rubric!.categoryLabels, ['유선형', '핀 킥', '입수·자세', '이완']);
    });
  });

  group('RubricCategory', () {
    test('constructor creates instance with all fields', () {
      final category = RubricCategory(
        id: 'streamline',
        label: '유선형',
        criteria: '머리 중립, 몸 일직선',
      );

      expect(category.id, 'streamline');
      expect(category.label, '유선형');
      expect(category.criteria, '머리 중립, 몸 일직선');
    });
  });
}
