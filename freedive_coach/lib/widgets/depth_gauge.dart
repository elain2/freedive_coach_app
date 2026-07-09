import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/simulation_service.dart';

/// Visual depth gauge for dive simulation
class DepthGauge extends StatelessWidget {
  final double currentDepth;
  final int targetDepth;
  final int? mouthfillDepth;
  final int? freefallDepth;
  final SimulationPhase phase;

  const DepthGauge({
    super.key,
    required this.currentDepth,
    required this.targetDepth,
    this.mouthfillDepth,
    this.freefallDepth,
    this.phase = SimulationPhase.idle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1628), // Surface - darker
            Color(0xFF0D2A4A), // Mid depth
            Color(0xFF071522), // Deep - darkest
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Depth markers
          _buildDepthMarkers(),
          // Milestone indicators
          if (mouthfillDepth != null) _buildMilestoneMarker(mouthfillDepth!, '마우스필', Colors.orange),
          if (freefallDepth != null) _buildMilestoneMarker(freefallDepth!, '프리폴', Colors.cyan),
          _buildMilestoneMarker(targetDepth, '턴', Colors.red),
          // Diver icon
          _buildDiver(),
          // Current depth display
          _buildDepthDisplay(),
        ],
      ),
    );
  }

  Widget _buildDepthMarkers() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(6, (index) {
            final depth = (targetDepth * index / 5).round();
            return Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    '${depth}m',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.line.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMilestoneMarker(int depth, String label, Color color) {
    final position = _depthToPosition(depth.toDouble());

    return Positioned(
      top: position,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              '$label ${depth}m',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiver() {
    final position = _depthToPosition(currentDepth);
    final isDescending = phase == SimulationPhase.descent || phase == SimulationPhase.freefall;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      top: position - 15, // Center the icon
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBright.withOpacity(0.2),
            border: Border.all(color: AppColors.primaryBright, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBright.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isDescending ? Icons.arrow_downward : Icons.arrow_upward,
            color: AppColors.primaryBright,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDepthDisplay() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            '${currentDepth.toStringAsFixed(1)}m',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: AppColors.primaryBright,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _phaseLabel,
            style: AppTextStyles.caption.copyWith(color: _phaseColor),
          ),
        ],
      ),
    );
  }

  double _depthToPosition(double depth) {
    const topPadding = 30.0;
    const bottomPadding = 100.0;
    const totalHeight = 400.0;
    final usableHeight = totalHeight - topPadding - bottomPadding;

    final ratio = depth / targetDepth;
    return topPadding + (ratio * usableHeight);
  }

  String get _phaseLabel {
    switch (phase) {
      case SimulationPhase.idle:
        return '대기';
      case SimulationPhase.descent:
        return '하강 중';
      case SimulationPhase.freefall:
        return '프리폴';
      case SimulationPhase.turn:
        return '턴';
      case SimulationPhase.ascent:
        return '상승 중';
      case SimulationPhase.completed:
        return '완료';
    }
  }

  Color get _phaseColor {
    switch (phase) {
      case SimulationPhase.descent:
      case SimulationPhase.freefall:
        return Colors.cyan;
      case SimulationPhase.turn:
        return Colors.red;
      case SimulationPhase.ascent:
        return Colors.green;
      case SimulationPhase.completed:
        return AppColors.primaryBright;
      default:
        return AppColors.muted;
    }
  }
}
