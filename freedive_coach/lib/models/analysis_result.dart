import 'discipline.dart';

/// Analysis mode: overview (full dive) or segment (focused section)
enum AnalysisMode { overview, segment }

/// Result for a single evaluation category
class CategoryResult {
  final String name;
  final double score; // 1-5, 0.5 step
  final String note;
  final String tip;

  const CategoryResult({
    required this.name,
    required this.score,
    required this.note,
    required this.tip,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'note': note,
        'tip': tip,
      };

  factory CategoryResult.fromJson(Map<String, dynamic> json) => CategoryResult(
        name: json['name'] as String,
        score: (json['score'] as num).toDouble(),
        note: json['note'] as String,
        tip: json['tip'] as String,
      );
}

/// Complete analysis result from AI
class AnalysisResult {
  final String id;
  final String requestId;
  final Discipline discipline;
  final AnalysisMode mode;
  final String overall;
  final List<CategoryResult> categories;
  final String hook;
  final DateTime createdAt;
  final String? linkedLogId;
  final String? videoPath;
  final String? thumbnailPath;

  const AnalysisResult({
    required this.id,
    required this.requestId,
    required this.discipline,
    required this.mode,
    required this.overall,
    required this.categories,
    required this.hook,
    required this.createdAt,
    this.linkedLogId,
    this.videoPath,
    this.thumbnailPath,
  });

  /// Calculate average score across all categories
  double get averageScore {
    if (categories.isEmpty) return 0.0;
    final total = categories.fold<double>(0, (sum, c) => sum + c.score);
    return total / categories.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'discipline': discipline.name,
        'mode': mode.name,
        'overall': overall,
        'categories': categories.map((c) => c.toJson()).toList(),
        'hook': hook,
        'createdAt': createdAt.toIso8601String(),
        'linkedLogId': linkedLogId,
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String,
        requestId: json['requestId'] as String,
        discipline: Discipline.values.firstWhere(
          (d) => d.name == json['discipline'],
          orElse: () => Discipline.cwt,
        ),
        mode: AnalysisMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => AnalysisMode.overview,
        ),
        overall: json['overall'] as String,
        categories: (json['categories'] as List)
            .map((c) => CategoryResult.fromJson(c as Map<String, dynamic>))
            .toList(),
        hook: json['hook'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        linkedLogId: json['linkedLogId'] as String?,
        videoPath: json['videoPath'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
      );

  AnalysisResult copyWith({
    String? id,
    String? requestId,
    Discipline? discipline,
    AnalysisMode? mode,
    String? overall,
    List<CategoryResult>? categories,
    String? hook,
    DateTime? createdAt,
    String? linkedLogId,
    String? videoPath,
    String? thumbnailPath,
  }) =>
      AnalysisResult(
        id: id ?? this.id,
        requestId: requestId ?? this.requestId,
        discipline: discipline ?? this.discipline,
        mode: mode ?? this.mode,
        overall: overall ?? this.overall,
        categories: categories ?? this.categories,
        hook: hook ?? this.hook,
        createdAt: createdAt ?? this.createdAt,
        linkedLogId: linkedLogId ?? this.linkedLogId,
        videoPath: videoPath ?? this.videoPath,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );
}

/// Evaluation rubric for a discipline
class Rubric {
  final Discipline id;
  final String label;
  final String context;
  final List<RubricCategory> categories;

  const Rubric({
    required this.id,
    required this.label,
    required this.context,
    required this.categories,
  });

  /// Get list of category labels
  List<String> get categoryLabels => categories.map((c) => c.label).toList();

  /// Get disciplines that have rubrics defined
  static List<Discipline> get supportedDisciplines => [
        Discipline.cwt,
        Discipline.fim,
        Discipline.cnf,
      ];

  /// Get rubric for a discipline, returns null if not supported
  static Rubric? forDiscipline(Discipline discipline) {
    return _rubrics[discipline];
  }

  static final Map<Discipline, Rubric> _rubrics = {
    Discipline.cwt: const Rubric(
      id: Discipline.cwt,
      label: '콘스턴트 웨이트 (CWT)',
      context:
          'AIDA 기준 핀 착용 수직 다이빙. 프레임에서 실제로 보이는 것만 근거로 삼고, 이퀄라이징·컨트랙션·내성처럼 영상으로 판단 불가한 것은 점수에 반영하지 말고 평가에서 뺀다.',
      categories: [
        RubricCategory(
          id: 'streamline',
          label: '유선형',
          criteria:
              '머리 중립(턱 살짝 당김), 양팔을 뻗어 상완이 귀를 감싸는지, 몸이 일직선인지, 불필요한 아치나 꺾임.',
        ),
        RubricCategory(
          id: 'finning',
          label: '핀 킥',
          criteria:
              '고관절에서 시작하는 길고 부드러운 킥 vs 무릎 위주 자전거 킥, 발목 신전(포인 발), 진폭·리듬, 좌우 대칭.',
        ),
        RubricCategory(
          id: 'entry',
          label: '입수·자세',
          criteria: '덕다이브의 몸 접기와 다리 수직 정렬, 또는 하강/프리폴 자세와 라인 정렬.',
        ),
        RubricCategory(
          id: 'relax',
          label: '이완',
          criteria: '어깨·목·손·얼굴의 긴장 신호와 전반적인 평온함.',
        ),
      ],
    ),
    Discipline.fim: const Rubric(
      id: Discipline.fim,
      label: '프리 이머전 (FIM)',
      context:
          'AIDA 기준 로프를 잡고 당겨서 하강·상승하는 수직 다이빙. 핀을 사용하지 않음. 프레임에서 실제로 보이는 것만 근거로 삼고, 이퀄라이징·컨트랙션·내성처럼 영상으로 판단 불가한 것은 점수에 반영하지 말고 평가에서 뺀다.',
      categories: [
        RubricCategory(
          id: 'streamline',
          label: '유선형',
          criteria:
              '머리 중립(턱 살짝 당김), 몸이 로프와 일직선인지, 다리가 정렬되어 있는지, 불필요한 아치나 꺾임.',
        ),
        RubricCategory(
          id: 'pulling',
          label: '풀링 테크닉',
          criteria:
              '한 손씩 번갈아 당기는 리듬과 효율, 팔 동작의 부드러움, 로프를 놓는 타이밍, 몸 흔들림 최소화.',
        ),
        RubricCategory(
          id: 'entry',
          label: '입수·자세',
          criteria: '덕다이브의 몸 접기와 다리 수직 정렬, 로프를 잡는 첫 동작의 매끄러움.',
        ),
        RubricCategory(
          id: 'legs',
          label: '다리 자세',
          criteria: '다리가 모여 있고 발끝이 펴져 있는지, 불필요한 킥이나 움직임 없이 안정적인지.',
        ),
        RubricCategory(
          id: 'relax',
          label: '이완',
          criteria: '어깨·목·손·얼굴의 긴장 신호와 전반적인 평온함.',
        ),
      ],
    ),
    Discipline.cnf: const Rubric(
      id: Discipline.cnf,
      label: '콘스턴트 노핀 (CNF)',
      context:
          'AIDA 기준 핀 없이 맨발로 수영하는 수직 다이빙. 프레임에서 실제로 보이는 것만 근거로 삼고, 이퀄라이징·컨트랙션·내성처럼 영상으로 판단 불가한 것은 점수에 반영하지 말고 평가에서 뺀다.',
      categories: [
        RubricCategory(
          id: 'streamline',
          label: '유선형',
          criteria:
              '머리 중립(턱 살짝 당김), 양팔을 뻗어 상완이 귀를 감싸는지, 몸이 일직선인지, 불필요한 아치나 꺾임.',
        ),
        RubricCategory(
          id: 'kick',
          label: '킥',
          criteria:
              '평영 킥(브레스트 킥) 또는 돌핀 킥의 효율성, 무릎 굽힘 각도, 발목 유연성, 추진력 대비 에너지 소모.',
        ),
        RubricCategory(
          id: 'stroke',
          label: '스트로크',
          criteria:
              '팔 동작의 타이밍과 효율, 물 잡기(캐치)의 정확성, 리커버리 동작의 매끄러움, 킥과의 조화.',
        ),
        RubricCategory(
          id: 'entry',
          label: '입수·자세',
          criteria: '덕다이브의 몸 접기와 다리 수직 정렬, 하강 시작 자세.',
        ),
        RubricCategory(
          id: 'relax',
          label: '이완',
          criteria: '어깨·목·손·얼굴의 긴장 신호와 전반적인 평온함.',
        ),
      ],
    ),
  };
}

/// Single evaluation category in a rubric
class RubricCategory {
  final String id;
  final String label;
  final String criteria;

  const RubricCategory({
    required this.id,
    required this.label,
    required this.criteria,
  });
}
