import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analysis_result.dart';
import '../models/discipline.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class AnalysisResultScreen extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildOverallCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildCategoriesCard(),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                    const SizedBox(height: 16),
                    _buildHookCard(context),
                    const SizedBox(height: 16),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, color: AppColors.text, size: 24),
          ),
          Text('분석 결과', style: AppTextStyles.titleSmall),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14405F), Color(0xFF071522)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppBadge(
                text: result.discipline.displayName,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
              ),
              const SizedBox(width: 8),
              AppBadge(
                text: result.mode == AnalysisMode.overview ? '전체 분석' : '구간 분석',
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                textColor: AppColors.text,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.averageScore.toStringAsFixed(1),
                style: AppTextStyles.titleLarge.copyWith(fontSize: 56),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 5',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreLabel(result.averageScore),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBright),
          ),
        ],
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

  Widget _buildSummaryCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('\u{1F431}', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '다이빙 캣 코치 총평',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.overall,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('항목별 점수', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          ...result.categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCategoryRow(category),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryResult category) {
    final percentage = (category.score / 5.0 * 100).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.name,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            Row(
              children: [
                Text(
                  category.score.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($percentage%)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * (category.score / 5.0);
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: barWidth,
                height: 8,
                decoration: BoxDecoration(
                  color: _getScoreColor(category.score),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                category.note,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4.0) return AppColors.primaryBright;
    if (score >= 3.0) return AppColors.amber;
    return AppColors.coral;
  }

  Widget _buildTipsCard() {
    final tips = result.categories
        .where((c) => c.tip.isNotEmpty)
        .map((c) => c.tip)
        .toList();

    if (tips.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u{1F4A1} 개선 팁', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key < tips.length - 1 ? 10 : 0),
                child: _buildTip(entry.key + 1, entry.value),
              )),
        ],
      ),
    );
  }

  Widget _buildTip(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.tealDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHookCard(BuildContext context) {
    if (result.hook.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SNS 공유용 문구',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: result.hook));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('클립보드에 복사되었습니다')),
                        );
                      },
                      child: const Icon(Icons.copy, size: 14, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${result.hook}"',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO: Implement log linking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그 연결 기능 준비 중')),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link, size: 16, color: AppColors.text),
                  const SizedBox(width: 6),
                  Text('로그에 연결', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '완료',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
