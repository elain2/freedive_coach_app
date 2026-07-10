import 'dart:math';
import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/analysis_storage.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _logStorage = LogStorage();
  final _analysisStorage = AnalysisStorage();
  int _logCount = 0;
  int _analysisCount = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final logs = await _logStorage.getLogs();
    final analysisCount = await _analysisStorage.getCount();
    setState(() {
      _logCount = logs.length;
      _analysisCount = analysisCount;
    });
  }

  Future<void> _generateMockLogs(int count) async {
    setState(() => _isGenerating = true);

    final random = Random();
    const disciplines = Discipline.values;
    final locations = [
      '제주 서귀포',
      '제주 협재',
      '부산 기장',
      '필리핀 세부',
      '인도네시아 발리',
      '이집트 다합',
      '태국 코타오',
      '강원 속초',
    ];
    final conditions = [
      '컨디션 좋음',
      '귀 타이트',
      '이퀄 어려움',
      '컨트랙션 빨리 옴',
      '릴렉스 잘됨',
      '프리폴 편안함',
      '턴 부드러움',
      null,
    ];

    for (int i = 0; i < count; i++) {
      final discipline = disciplines[random.nextInt(disciplines.length)];
      final daysAgo = random.nextInt(180); // Last 6 months
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      double? depth;
      double? distance;
      Duration? duration;
      double? mouthfillDepth;
      double? freefallDepth;

      if (discipline.isDepthDiscipline) {
        depth = 15 + random.nextDouble() * 30; // 15-45m
        mouthfillDepth = depth * (0.6 + random.nextDouble() * 0.2); // 60-80% of depth
        freefallDepth = depth * (0.7 + random.nextDouble() * 0.2); // 70-90% of depth
        duration = Duration(
          minutes: 1 + random.nextInt(2),
          seconds: random.nextInt(60),
        );
      } else if (discipline.isDistanceDiscipline) {
        distance = 50 + random.nextDouble() * 100; // 50-150m
        duration = Duration(
          minutes: 1 + random.nextInt(3),
          seconds: random.nextInt(60),
        );
      } else {
        // STA
        duration = Duration(
          minutes: 2 + random.nextInt(4),
          seconds: random.nextInt(60),
        );
      }

      final log = DiveLog.create(
        diveDate: date,
        discipline: discipline,
        location: locations[random.nextInt(locations.length)],
        depth: depth,
        distance: distance,
        duration: duration,
        mouthfillDepth: mouthfillDepth,
        freefallDepth: freefallDepth,
        weight: 2 + random.nextDouble() * 4, // 2-6kg
        condition: conditions[random.nextInt(conditions.length)],
        notes: random.nextBool() ? '테스트 목 데이터 #${i + 1}' : null,
      );

      await _logStorage.saveLog(log);
    }

    await _loadCounts();
    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count개의 로그 데이터가 생성되었습니다')),
      );
    }
  }

  Future<void> _generateMockAnalyses(int count) async {
    setState(() => _isGenerating = true);

    final random = Random();
    final supportedDisciplines = Rubric.supportedDisciplines;

    final overallComments = [
      '전반적으로 안정적인 다이브예요. 유선형과 이완이 특히 좋아요.',
      '좋은 다이브였어요! 핀킥 리듬만 다듬으면 더 깊이 갈 수 있어요.',
      '자세가 많이 좋아졌어요. 입수 각도에 조금 더 신경 써보세요.',
      '릴렉스가 잘 되고 있어요. 프리폴 타이밍을 조금 앞당겨보세요.',
      '꾸준히 연습하면 금방 늘 거예요. 기본기가 탄탄해요!',
      '효율적인 킥이에요. 상승 시 페이스 조절에 집중해보세요.',
    ];

    final hooks = [
      '물속에서도 흐트러지지 않는 유선형 — 기록은 이완이 만든다',
      '더 깊이, 더 편안하게 — 오늘도 한계를 넘었다',
      '프리다이빙은 나와의 대화다 — 물이 가르쳐준 것들',
      '호흡 하나로 세상과 연결되는 순간',
      '깊은 바다가 알려준 고요함의 힘',
    ];

    final categoryNotes = {
      'streamline': [
        '유선형이 잘 유지되고 있어요.',
        '머리 위치가 살짝 들려 있어요.',
        '팔이 귀를 잘 감싸고 있어요.',
        '몸이 일직선으로 잘 정렬되어 있어요.',
      ],
      'finning': [
        '킥이 부드럽고 효율적이에요.',
        '무릎이 살짝 굽혀지는 경향이 있어요.',
        '발목 유연성이 좋아요.',
        '킥 리듬이 일정해요.',
      ],
      'entry': [
        '입수 각도가 좋아요.',
        '덕다이브가 매끄러워요.',
        '다리가 수직으로 잘 올라가요.',
        '입수 시 물 저항이 최소화되어 있어요.',
      ],
      'relax': [
        '전반적으로 릴렉스가 잘 되어 있어요.',
        '어깨에 약간 긴장이 보여요.',
        '표정이 편안해 보여요.',
        '손에 힘이 빠져 있어요.',
      ],
      'pulling': [
        '풀링 리듬이 일정해요.',
        '로프를 효율적으로 잡고 있어요.',
        '상체 흔들림이 적어요.',
      ],
      'kick': [
        '킥이 힘차요.',
        '돌핀 킥 타이밍이 좋아요.',
        '에너지 효율이 좋아요.',
      ],
      'stroke': [
        '스트로크가 매끄러워요.',
        '물 잡기가 정확해요.',
        '킥과 스트로크 타이밍이 잘 맞아요.',
      ],
      'legs': [
        '다리가 잘 모여 있어요.',
        '발끝이 잘 펴져 있어요.',
      ],
    };

    final categoryTips = {
      'streamline': [
        '턱을 살짝 더 당겨보세요.',
        '팔을 귀에 더 밀착시켜보세요.',
        '',
      ],
      'finning': [
        '고관절에서 시작하는 킥을 연습해보세요.',
        '킥 진폭을 조금 줄여보세요.',
        '발목 스트레칭을 더 해보세요.',
        '',
      ],
      'entry': [
        '입수 시 시선을 바닥으로 향해보세요.',
        '다리를 더 수직으로 올려보세요.',
        '',
      ],
      'relax': [
        '어깨 힘을 빼는 연습을 해보세요.',
        '호흡 전 릴렉스 루틴을 만들어보세요.',
        '',
      ],
      'pulling': [
        '풀링 시 상체를 고정해보세요.',
        '',
      ],
      'kick': [
        '킥을 더 천천히 해보세요.',
        '',
      ],
      'stroke': [
        '팔꿈치를 더 높이 유지해보세요.',
        '',
      ],
      'legs': [
        '다리를 더 모아보세요.',
        '',
      ],
    };

    for (int i = 0; i < count; i++) {
      final discipline = supportedDisciplines[random.nextInt(supportedDisciplines.length)];
      final rubric = Rubric.forDiscipline(discipline)!;
      final daysAgo = random.nextInt(90);
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      final mode = random.nextBool() ? AnalysisMode.overview : AnalysisMode.segment;

      final categories = rubric.categories.map((cat) {
        final score = 2.5 + random.nextDouble() * 2.5; // 2.5 ~ 5.0
        final roundedScore = (score * 2).round() / 2; // Round to 0.5

        final notes = categoryNotes[cat.id] ?? ['좋아요.'];
        final tips = categoryTips[cat.id] ?? [''];

        return CategoryResult(
          name: cat.label,
          score: roundedScore,
          note: notes[random.nextInt(notes.length)],
          tip: tips[random.nextInt(tips.length)],
        );
      }).toList();

      final analysis = AnalysisResult(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}_$i',
        requestId: 'mock_req_$i',
        discipline: discipline,
        mode: mode,
        overall: overallComments[random.nextInt(overallComments.length)],
        categories: categories,
        hook: hooks[random.nextInt(hooks.length)],
        createdAt: date,
      );

      await _analysisStorage.saveResult(analysis);
    }

    await _loadCounts();
    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count개의 분석 데이터가 생성되었습니다')),
      );
    }
  }

  Future<void> _deleteAllLogs() async {
    final confirmed = await _showDeleteConfirmDialog(
      title: '모든 로그 삭제',
      message: '정말로 모든 로그($_logCount개)를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
    );

    if (confirmed == true) {
      setState(() => _isGenerating = true);

      final logs = await _logStorage.getLogs();
      for (final log in logs) {
        await _logStorage.deleteLog(log.id);
      }

      await _loadCounts();
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 로그가 삭제되었습니다')),
        );
      }
    }
  }

  Future<void> _deleteAllAnalyses() async {
    final confirmed = await _showDeleteConfirmDialog(
      title: '모든 분석 삭제',
      message: '정말로 모든 분석 결과($_analysisCount개)를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
    );

    if (confirmed == true) {
      setState(() => _isGenerating = true);

      await _analysisStorage.clearAll();

      await _loadCounts();
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 분석 결과가 삭제되었습니다')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title, style: AppTextStyles.titleSmall),
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildLogGenerateSection(),
                    const SizedBox(height: 20),
                    _buildAnalysisGenerateSection(),
                    const SizedBox(height: 20),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.muted),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.bug_report, size: 18, color: AppColors.coral),
              const SizedBox(width: 8),
              Text('디버그 메뉴', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusItem(
                icon: Icons.history,
                label: '다이빙 로그',
                count: _logCount,
                color: AppColors.primaryBright,
              ),
              const SizedBox(width: 16),
              _buildStatusItem(
                icon: Icons.analytics,
                label: '분석 결과',
                count: _analysisCount,
                color: AppColors.amber,
              ),
            ],
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
                Text(
                  '$count개',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogGenerateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16, color: AppColors.primaryBright),
            const SizedBox(width: 8),
            Text('로그 목 데이터', style: AppTextStyles.sectionTitle),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenerateButton('5개', () => _generateMockLogs(5))),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('10개', () => _generateMockLogs(10))),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('30개', () => _generateMockLogs(30))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '랜덤한 다이빙 로그를 생성합니다.',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildAnalysisGenerateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, size: 16, color: AppColors.amber),
            const SizedBox(width: 8),
            Text('분석 목 데이터', style: AppTextStyles.sectionTitle),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenerateButton('3개', () => _generateMockAnalyses(3), color: AppColors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('5개', () => _generateMockAnalyses(5), color: AppColors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('10개', () => _generateMockAnalyses(10), color: AppColors.amber)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'CWT, FIM, CNF 종목의 랜덤한 분석 결과를 생성합니다.',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(String label, VoidCallback onTap, {Color color = AppColors.tealDim}) {
    return GestureDetector(
      onTap: _isGenerating ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isGenerating ? AppColors.surface2 : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: _isGenerating ? AppColors.muted : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, size: 16, color: AppColors.coral),
            const SizedBox(width: 8),
            Text(
              '위험 구역',
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.coral),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDeleteButton(
                label: '모든 로그 삭제',
                enabled: _logCount > 0,
                onTap: _deleteAllLogs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDeleteButton(
                label: '모든 분석 삭제',
                enabled: _analysisCount > 0,
                onTap: _deleteAllAnalyses,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isGenerating || !enabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.coral.withValues(alpha: 0.5) : AppColors.line,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: enabled ? AppColors.coral : AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
