import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'new_log_screen.dart';

class LogTimelineScreen extends StatelessWidget {
  const LogTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildMonthChip(),
              const SizedBox(height: 16),
              _buildTimeline(),
            ],
          ),
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: _buildFab(context),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('로그', style: AppTextStyles.titleMedium),
        Row(
          children: [
            _buildIconButton(Icons.bar_chart),
            const SizedBox(width: 10),
            _buildIconButton(Icons.tune),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(icon, size: 16, color: AppColors.muted),
    );
  }

  Widget _buildMonthChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '7월',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryBright,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(' · ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          Text('다이빙 8회', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          Text(' · ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          Text('최고 32m', style: AppTextStyles.monoSmall),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildLogEntry(
          date: '7월 6일',
          discipline: 'CWT',
          depth: '32',
          location: '제주 서귀포',
          mouthfill: '30m',
          freefall: '25m',
          isFirst: true,
        ),
        _buildRopeGap(),
        _buildLogEntry(
          date: '7월 4일',
          discipline: 'FIM',
          depth: '28',
          location: '제주 서귀포',
          isFirst: false,
        ),
        _buildRopeGap(),
        _buildLogEntry(
          date: '7월 2일',
          discipline: 'CWT',
          depth: '30',
          location: '부산 기장',
          mouthfill: '28m',
          freefall: '22m',
          isFirst: false,
        ),
      ],
    );
  }

  Widget _buildLogEntry({
    required String date,
    required String discipline,
    required String depth,
    required String location,
    String? mouthfill,
    String? freefall,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRope(isFirst: isFirst, hasExtras: mouthfill != null),
        const SizedBox(width: 12),
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date, style: AppTextStyles.caption),
                    AppBadge(text: discipline),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      depth,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 32),
                    ),
                    const SizedBox(width: 4),
                    Text('m', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(location, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                if (mouthfill != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTag('마우스필 $mouthfill'),
                      const SizedBox(width: 8),
                      _buildTag('프리폴 ${freefall ?? '-'}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(fontSize: 11)),
    );
  }

  Widget _buildRope({required bool isFirst, required bool hasExtras}) {
    final height = hasExtras ? 197.0 : 131.0;
    return SizedBox(
      width: 16,
      height: height,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isFirst ? AppColors.primaryBright : AppColors.tealDim,
              shape: BoxShape.circle,
              border: Border.all(
                color: isFirst ? AppColors.primaryBright : AppColors.primary,
                width: 2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: AppColors.tealDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRopeGap() {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Container(
        width: 2,
        height: 16,
        color: AppColors.tealDim,
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewLogScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '새 로그',
              style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
