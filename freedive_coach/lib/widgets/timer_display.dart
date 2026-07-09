import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/timer_service.dart';

/// Large timer display widget for breathing training
class TimerDisplay extends StatelessWidget {
  final Duration duration;
  final TimerPhase phase;
  final double progress;

  const TimerDisplay({
    super.key,
    required this.duration,
    required this.phase,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 100;

    final phaseColor = phase == TimerPhase.recovery
        ? AppColors.primaryBright
        : const Color(0xFFFF6B6B); // Red for breath hold

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phase indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: phaseColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            phase == TimerPhase.recovery ? '회복' : '숨참기',
            style: AppTextStyles.sectionTitle.copyWith(color: phaseColor),
          ),
        ),
        const SizedBox(height: 24),
        // Timer display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: phaseColor,
                letterSpacing: 2,
              ),
            ),
            Text(
              '.$milliseconds',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: phaseColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Progress bar
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact timer display for smaller contexts
class CompactTimerDisplay extends StatelessWidget {
  final Duration duration;
  final Color? color;

  const CompactTimerDisplay({
    super.key,
    required this.duration,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Text(
      '$minutes:${seconds.toString().padLeft(2, '0')}',
      style: AppTextStyles.monoSmall.copyWith(
        color: color ?? AppColors.text,
        fontSize: 18,
      ),
    );
  }
}
