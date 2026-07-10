import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'analysis_setup_screen.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildUploadSection(context),
          const SizedBox(height: 20),
          _buildRecentAnalysis(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI 코치', style: AppTextStyles.titleLarge),
        const SizedBox(height: 2),
        Text(
          '영상을 올리면 자세를 분석해드려요 \u{1F431}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, size: 22, color: AppColors.primaryBright),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('폼 분석 시작', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 2),
                Text(
                  'AI가 자세를 분석해드려요',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnalysis(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 분석', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to analysis history or specific result
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
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
                  child: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppBadge(text: 'CWT'),
                          const SizedBox(width: 8),
                          Text('32m', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('제주 서귀포 · 어제', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.primaryBright),
                          const SizedBox(width: 4),
                          Text(
                            '86점',
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
        ),
      ],
    );
  }
}
