import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 20),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('마이', style: AppTextStyles.titleLarge),
        const Icon(Icons.settings, size: 22, color: AppColors.muted),
      ],
    );
  }

  Widget _buildProfileCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      borderColor: Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('\u{1F431}', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('다이버님', style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '프리다이빙 2년차',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'AIDA 2',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나의 기록', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatItem('총 다이빙', '127', '회')),
              Container(width: 1, height: 40, color: AppColors.line),
              Expanded(child: _buildStatItem('최고 수심', '35', 'm')),
              Container(width: 1, height: 40, color: AppColors.line),
              Expanded(child: _buildStatItem('최장 시간', '3:24', '')),
            ],
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
              style: AppTextStyles.titleSmall.copyWith(
                fontSize: 22,
                color: AppColors.primaryBright,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: AppTextStyles.caption),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(Icons.track_changes, '나의 목표', '40m CWT'),
        _buildMenuItem(Icons.calendar_today, '훈련 스케줄', '주 4회'),
        _buildMenuItem(Icons.emoji_events, '뱃지 & 업적', '12개 획득'),
        _buildMenuItem(Icons.notifications_outlined, '알림 설정', ''),
        _buildMenuItem(Icons.help_outline, '도움말', ''),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: AppTextStyles.body),
          ),
          if (value.isNotEmpty)
            Text(value, style: AppTextStyles.caption),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}
