import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../theme/app_theme.dart';
import 'surface_card.dart';

/// A card displaying a single dive log entry in the timeline
class LogEntryCard extends StatelessWidget {
  final DiveLog log;
  final bool isFirst;
  final VoidCallback? onTap;

  const LogEntryCard({
    super.key,
    required this.log,
    this.isFirst = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasExtras = log.mouthfillDepth != null || log.freefallDepth != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRope(isFirst: isFirst, hasExtras: hasExtras),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log.diveDateFormatted, style: AppTextStyles.caption),
                      AppBadge(text: log.discipline.displayName),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildPrimaryMetric(),
                  const SizedBox(height: 4),
                  if (log.location != null)
                    Text(
                      log.location!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                    ),
                  if (hasExtras) ...[
                    const SizedBox(height: 10),
                    _buildTags(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetric() {
    if (log.discipline.isTimeDiscipline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            log.durationFormatted,
            style: AppTextStyles.titleMedium.copyWith(fontSize: 32),
          ),
        ],
      );
    }

    final value = log.primaryMetric;
    if (value == null) {
      return Text('-', style: AppTextStyles.titleMedium.copyWith(fontSize: 32));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: AppTextStyles.titleMedium.copyWith(fontSize: 32),
        ),
        const SizedBox(width: 4),
        Text(
          log.discipline.primaryUnit,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildTags() {
    final tags = <Widget>[];

    if (log.mouthfillDepth != null) {
      tags.add(_buildTag('마우스필 ${log.mouthfillDepth!.toStringAsFixed(0)}m'));
    }
    if (log.freefallDepth != null) {
      if (tags.isNotEmpty) tags.add(const SizedBox(width: 8));
      tags.add(_buildTag('프리폴 ${log.freefallDepth!.toStringAsFixed(0)}m'));
    }

    return Row(children: tags);
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
}

/// Gap element between log entries in the timeline
class LogRopeGap extends StatelessWidget {
  const LogRopeGap({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Container(
        width: 2,
        height: 16,
        color: AppColors.tealDim,
      ),
    );
  }
}
