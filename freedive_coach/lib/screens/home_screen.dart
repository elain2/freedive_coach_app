import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/analysis_storage.dart';
import '../services/log_storage.dart';
import '../services/training_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'analysis_result_screen.dart';
import 'analysis_setup_screen.dart';
import 'log_detail_screen.dart';
import 'new_log_screen.dart';
import 'simulation_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _logStorage = LogStorage();
  final _analysisStorage = AnalysisStorage();
  final _trainingStorage = TrainingStorage();
  DiveLog? _recentLog;
  List<AnalysisResult> _recentAnalyses = [];
  int _weekDiveCount = 0;
  double? _weekMaxDepth;
  int _weekTrainingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load recent log
    final logs = await _logStorage.getLogs();
    if (logs.isNotEmpty) {
      setState(() {
        _recentLog = logs.first;
      });
    }

    // Load recent analyses
    final analyses = await _analysisStorage.getRecentResults(count: 3);
    setState(() {
      _recentAnalyses = analyses;
    });

    // Calculate week stats
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLogs = logs.where((log) =>
        log.diveDate.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();

    double? maxDepth;
    for (final log in weekLogs) {
      if (log.depth != null) {
        if (maxDepth == null || log.depth! > maxDepth) {
          maxDepth = log.depth;
        }
      }
    }

    // Calculate week training count
    final trainings = await _trainingStorage.getSessions();
    final weekTrainings = trainings.where((t) =>
        t.startedAt.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();

    setState(() {
      _weekDiveCount = weekLogs.length;
      _weekMaxDepth = maxDepth;
      _weekTrainingCount = weekTrainings.length;
    });
  }

  String _getTodayString() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(logDate).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff < 7) return '$diff일 전';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(),
          const SizedBox(height: 24),
          _buildRecentLogCard(),
          const SizedBox(height: 24),
          _buildTrainingRecommendation(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          if (_recentAnalyses.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildRecentAnalyses(),
          ],
          const SizedBox(height: 24),
          _buildWeekStats(),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요, 다이버님 \u{1F431}',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _getTodayString(),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildRecentLogCard() {
    if (_recentLog == null) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewLogScreen()),
          );
          if (result == true) _loadData();
        },
        child: SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.add_circle_outline, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                '아직 로그가 없어요',
                style: AppTextStyles.sectionTitle.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '첫 다이빙 로그를 작성해보세요',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    final log = _recentLog!;
    final primaryValue = log.primaryMetric?.toStringAsFixed(0) ?? '-';
    final unit = log.discipline.primaryUnit;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
        );
        if (result == true) _loadData();
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '최근 로그 · ${_getRelativeDate(log.diveDate)}',
                  style: AppTextStyles.caption,
                ),
                AppBadge(text: log.discipline.displayName),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          primaryValue,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    if (log.location != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        log.location!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tealDim,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (log.condition != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\u{1F442} ${log.condition}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingRecommendation() {
    return GestureDetector(
      onTap: () {
        // Navigate to training tab
        widget.onTabChange?.call(3);
      },
      child: TealCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.air,
                color: AppColors.primaryBright,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 훈련 추천',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryBright,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CO\u2082 테이블 8라운드',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '예상 12:00',
                    style: AppTextStyles.monoSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.mic,
                '새 로그',
                '음성으로 기록',
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const NewLogScreen()),
                  );
                  if (result == true) _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.videocam,
                '영상 분석',
                'AI 코칭',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.air,
                '호흡 훈련',
                'CO\u2082/O\u2082',
                onTap: () {
                  widget.onTabChange?.call(3);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.play_arrow,
                '시뮬레이션',
                '멘탈 다이브',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SimulationSetupScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBright, size: 24),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnalyses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 분석', style: AppTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
                );
              },
              child: Text(
                '새 분석',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentAnalyses.length,
            itemBuilder: (context, index) {
              final analysis = _recentAnalyses[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _recentAnalyses.length - 1 ? 12 : 0,
                ),
                child: _buildAnalysisCard(analysis),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(AnalysisResult analysis) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: analysis),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(
                  text: analysis.discipline.displayName,
                  backgroundColor: AppColors.tealDim,
                  textColor: Colors.white,
                ),
                Text(
                  _getRelativeDate(analysis.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  analysis.averageScore.toStringAsFixed(1),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 28,
                    color: AppColors.primaryBright,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ 5',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getScoreLabel(analysis.averageScore),
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 4.5) return '훌륭해요!';
    if (score >= 4.0) return '좋아요!';
    if (score >= 3.5) return '괜찮아요';
    if (score >= 3.0) return '조금 더 연습해요';
    return '기초부터 다시!';
  }

  Widget _buildWeekStats() {
    return GestureDetector(
      onTap: () {
        widget.onTabChange?.call(1); // Navigate to log tab
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 주', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: _buildStatItem('다이빙', '$_weekDiveCount', '회')),
                Container(width: 1, height: 32, color: AppColors.line),
                Expanded(
                  child: _buildStatItem(
                    '최고 수심',
                    _weekMaxDepth?.toStringAsFixed(0) ?? '-',
                    'm',
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.line),
                Expanded(child: _buildStatItem('훈련', '$_weekTrainingCount', '회')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(fontSize: 20),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
