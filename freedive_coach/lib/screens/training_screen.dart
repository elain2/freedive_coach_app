import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/breathing_table.dart';
import '../widgets/surface_card.dart';
import 'breathing_setup_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStreakBanner(),
          const SizedBox(height: 20),
          _buildBreathSection(context),
          const SizedBox(height: 20),
          _buildSimulationSection(),
          const SizedBox(height: 20),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('트레이닝', style: AppTextStyles.titleLarge),
        const SizedBox(height: 2),
        Text(
          '물 밖에서도 다이빙은 계속돼요 \u{1F431}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: AppColors.primaryBright),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '이번 주 4회 훈련 — 연속 12일째예요!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('호흡 훈련', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildBreathCard(context, 'CO\u2082 테이블', '8라운드', '12:00', Icons.monitor_heart_outlined, TableType.co2)),
            const SizedBox(width: 10),
            Expanded(child: _buildBreathCard(context, 'O\u2082 테이블', '8라운드', '10:30', Icons.favorite_outline, TableType.o2)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreathCard(BuildContext context, String title, String rounds, String duration, IconData icon, TableType tableType) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BreathingSetupScreen(initialType: tableType),
          ),
        );
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBright),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(rounds, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(duration, style: AppTextStyles.monoSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('다이빙 시뮬레이션', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.standard),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14405F), Color(0xFF0A2438)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('멘탈 다이브', style: AppTextStyles.sectionTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBright.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '3분 코스',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  _buildChip('30m'),
                  _buildChip('40m'),
                  _buildChip('50m'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '마지막 세션: 어제 40m',
                    style: AppTextStyles.caption,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBright,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '시작',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.text)),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('훈련 기록', style: AppTextStyles.sectionTitle),
            Text(
              '전체 보기',
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: EdgeInsets.zero,
          borderColor: Colors.transparent,
          child: Column(
            children: [
              _buildHistoryItem('CO\u2082 테이블', '8라운드 완료', '오늘 오전'),
              _buildHistoryDivider(),
              _buildHistoryItem('다이빙 시뮬레이션', '40m 완료', '어제'),
              _buildHistoryDivider(),
              _buildHistoryItem('O\u2082 테이블', '6라운드 완료', '2일 전'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.primaryBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildHistoryDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 14),
      child: Container(height: 1, color: AppColors.line),
    );
  }
}
