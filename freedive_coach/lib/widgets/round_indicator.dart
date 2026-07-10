import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget to display round progress (e.g., "3 / 8")
class RoundIndicator extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final bool showDots;

  const RoundIndicator({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '라운드 ',
              style: AppTextStyles.caption,
            ),
            Text(
              '$currentRound',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primaryBright,
                fontSize: 24,
              ),
            ),
            Text(
              ' / $totalRounds',
              style: AppTextStyles.body.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        if (showDots) ...[
          const SizedBox(height: 12),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalRounds, (index) {
              final roundNumber = index + 1;
              final isCompleted = roundNumber < currentRound;
              final isCurrent = roundNumber == currentRound;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: isCurrent ? 12 : 8,
                  height: isCurrent ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primaryBright
                        : isCurrent
                            ? AppColors.primaryBright.withValues(alpha: 0.5)
                            : AppColors.surface,
                    border: Border.all(
                      color: isCompleted || isCurrent
                          ? AppColors.primaryBright
                          : AppColors.line,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Horizontal bar style round indicator
class RoundProgressBar extends StatelessWidget {
  final int currentRound;
  final int totalRounds;

  const RoundProgressBar({
    super.key,
    required this.currentRound,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '진행률',
              style: AppTextStyles.caption,
            ),
            Text(
              '$currentRound / $totalRounds 라운드',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: currentRound / totalRounds,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBright),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
