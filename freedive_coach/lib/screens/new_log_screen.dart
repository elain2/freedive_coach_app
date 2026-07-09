import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NewLogScreen extends StatelessWidget {
  const NewLogScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVoiceCard(),
                    const SizedBox(height: 20),
                    _buildAISection(),
                    const SizedBox(height: 20),
                    _buildMediaSection(),
                    const SizedBox(height: 20),
                    _buildBottomActions(context),
                    const SizedBox(height: 8),
                    _buildHomeIndicator(),
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
              child: const Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
          ),
          Text('새 로그', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildVoiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('녹음 완료', style: AppTextStyles.caption.copyWith(color: AppColors.coral)),
                ],
              ),
              Text('0:42', style: AppTextStyles.monoSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildWaveform(),
          const SizedBox(height: 16),
          Text(
            '"오늘 제주 서귀포에서 CWT 32m 성공, 마우스필 30m, 프리폴 25m, 귀 좀 타이트했어"',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    final heights = [8, 12, 18, 26, 32, 24, 16, 22, 30, 34, 26, 18, 10, 14, 22, 28, 34, 30, 20, 12, 16, 24, 32, 28, 18, 10, 8, 12, 20, 26, 18, 10];
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: heights.asMap().entries.map((entry) {
          final height = entry.value.toDouble();
          final isPrimary = height > 20;
          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primaryBright : AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI가 정리했어요 \u{1F431}', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildFieldRow('장소', '제주 서귀포', Icons.location_on_outlined),
              _buildDivider(),
              _buildFieldRow('종목', 'CWT', Icons.track_changes),
              _buildDivider(),
              _buildFieldRow('수심', '32m', Icons.arrow_downward),
              _buildDivider(),
              _buildFieldRow('마우스필', '30m', Icons.expand_more),
              _buildDivider(),
              _buildFieldRow('프리폴', '25m', Icons.keyboard_double_arrow_down),
              _buildDivider(),
              _buildFieldRow('컨디션', '귀 타이트', Icons.monitor_heart_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: AppColors.line),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('미디어', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface2,
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 24, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Center(
            child: Text(
              '수정',
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '저장하기',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeIndicator() {
    return Center(
      child: Container(
        width: 134,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.text.withOpacity(0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
