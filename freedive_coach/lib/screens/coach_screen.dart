import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../services/analysis_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'analysis_result_screen.dart';
import 'analysis_setup_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _analysisStorage = AnalysisStorage();
  List<AnalysisResult> _recentAnalyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    final results = await _analysisStorage.getRecentResults(count: 10);
    if (mounted) {
      setState(() {
        _recentAnalyses = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAnalyses,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildRecentAnalysis(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI 코치', style: AppTextStyles.titleLarge),
            const SizedBox(height: 2),
            Text(
              '영상을 올리면 자세를 분석해드려요 \u{1F431}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
            );
            _loadAnalyses(); // Refresh after returning
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, size: 22, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAnalysis(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 분석', style: AppTextStyles.sectionTitle),
            if (_recentAnalyses.isNotEmpty)
              Text(
                '${_recentAnalyses.length}개',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          _buildLoadingState()
        else if (_recentAnalyses.isEmpty)
          _buildEmptyState(context)
        else
          ..._recentAnalyses.map((analysis) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnalysisCard(context, analysis),
              )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
        );
        _loadAnalyses();
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(24),
        borderColor: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tealDim,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.videocam_outlined, color: AppColors.primaryBright, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 분석 결과가 없어요',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '다이빙 영상을 올려서\nAI 폼 분석을 받아보세요!',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '분석 시작하기',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, AnalysisResult analysis) {
    final scorePercent = (analysis.averageScore / 5 * 100).round();
    final dateStr = _formatDate(analysis.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: analysis),
          ),
        );
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF14405F), Color(0xFF071522)],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.play_arrow, size: 20, color: Colors.white),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        analysis.mode == AnalysisMode.overview ? '전체' : '구간',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppBadge(text: analysis.discipline.displayName),
                      const SizedBox(width: 8),
                      Text(
                        analysis.mode == AnalysisMode.overview ? '전체 분석' : '구간 분석',
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.primaryBright),
                      const SizedBox(width: 4),
                      Text(
                        '${analysis.averageScore.toStringAsFixed(1)}/5 ($scorePercent점)',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
