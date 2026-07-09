import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    _buildVideoCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildScoreCard(),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                    const SizedBox(height: 16),
                    _buildSnsCard(),
                    const SizedBox(height: 16),
                    _buildActions(),
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
          const Icon(Icons.share, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14405F), Color(0xFF071522)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const AppBadge(text: 'CWT', backgroundColor: AppColors.primary, textColor: Colors.white),
              const SizedBox(width: 8),
              AppBadge(
                text: 'AI 분석 완료',
                backgroundColor: Colors.black.withOpacity(0.6),
                textColor: AppColors.text,
              ),
            ],
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.text.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('0:42', style: AppTextStyles.monoSmall.copyWith(color: AppColors.text)),
          ),
        ],
      ),
    );
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
                  '전반적으로 안정적인 다이브예요. 유선형과 이완이 특히 좋아요. 핀킥 리듬만 다듬으면 35m도 무리 없겠어요.',
                  style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('항목별 점수', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          _buildScoreRow('유선형', 92),
          const SizedBox(height: 14),
          _buildScoreRow('핀킥', 78),
          const SizedBox(height: 14),
          _buildScoreRow('입수 자세', 85),
          const SizedBox(height: 14),
          _buildScoreRow('이완', 90),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
            Text('$score', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBright)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBright,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u{1F4A1} 개선 팁', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          _buildTip(1, '프리폴 진입 시 킥을 한 템포 일찍 멈춰보세요'),
          const SizedBox(height: 10),
          _buildTip(2, '핀킥은 무릎 각도를 줄이고 힙에서 시작하는 킥으로'),
          const SizedBox(height: 10),
          _buildTip(3, '턴 직전 시선을 로프에 고정하면 축이 안정돼요'),
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

  Widget _buildSnsCard() {
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
                    const Icon(Icons.copy, size: 14, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"32m에서도 흐트러지지 않는 유선형 — 기록은 이완이 만든다"',
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

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
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
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F86D6), Color(0xFF55ABEC)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '공유하기',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
