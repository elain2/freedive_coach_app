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
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildRecentAnalysis(context),
        ],
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnalysisSetupScreen()),
            );
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
