import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/simulation_profile.dart';
import '../widgets/surface_card.dart';
import 'simulation_run_screen.dart';

class SimulationSetupScreen extends StatefulWidget {
  const SimulationSetupScreen({super.key});

  @override
  State<SimulationSetupScreen> createState() => _SimulationSetupScreenState();
}

class _SimulationSetupScreenState extends State<SimulationSetupScreen> {
  late SimulationProfile _profile;
  bool _showSafetyWarning = true;

  @override
  void initState() {
    super.initState();
    _profile = SimulationProfile.defaultProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('다이빙 시뮬레이션', style: AppTextStyles.titleSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showSafetyWarning) _buildSafetyWarning(),
            const SizedBox(height: 20),
            _buildDepthSection(),
            const SizedBox(height: 20),
            _buildSpeedSection(),
            const SizedBox(height: 20),
            _buildMilestoneSection(),
            const SizedBox(height: 20),
            _buildEstimatedTime(),
            const SizedBox(height: 32),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryBright, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 시뮬레이션은 타이밍 리허설용입니다.\n실제 다이빙은 버디와 함께 안전하게 진행하세요.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted, size: 16),
            onPressed: () => setState(() => _showSafetyWarning = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('목표 수심', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDepthSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepthSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primaryBright,
          onPressed: () {
            if (_profile.targetDepth > 10) {
              setState(() {
                _profile = _profile.copyWith(targetDepth: _profile.targetDepth - 5);
                _adjustMilestones();
              });
            }
          },
        ),
        Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_profile.targetDepth}m',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontFamily: 'monospace',
              fontSize: 32,
              color: AppColors.primaryBright,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primaryBright,
          onPressed: () {
            if (_profile.targetDepth < 100) {
              setState(() {
                _profile = _profile.copyWith(targetDepth: _profile.targetDepth + 5);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSpeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('속도 설정', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: Colors.transparent,
          child: Column(
            children: [
              _buildSpeedRow('하강 속도', _profile.descentSpeed, (v) {
                setState(() => _profile = _profile.copyWith(descentSpeed: v));
              }),
              const SizedBox(height: 16),
              _buildSpeedRow('프리폴 속도', _profile.freefallSpeed, (v) {
                setState(() => _profile = _profile.copyWith(freefallSpeed: v));
              }),
              const SizedBox(height: 16),
              _buildSpeedRow('상승 속도', _profile.ascentSpeed, (v) {
                setState(() => _profile = _profile.copyWith(ascentSpeed: v));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: AppTextStyles.body),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.muted,
                onPressed: () {
                  if (value > 0.5) onChanged(value - 0.1);
                },
              ),
              Text(
                '${value.toStringAsFixed(1)} m/s',
                style: AppTextStyles.monoSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.muted,
                onPressed: () {
                  if (value < 2.0) onChanged(value + 0.1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneSection() {
    final hasWarning = _profile.isMouthfillWarning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('마일스톤', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: hasWarning ? Colors.orange.withValues(alpha: 0.5) : Colors.transparent,
          child: Column(
            children: [
              _buildMilestoneRow('마우스필 수심', _profile.mouthfillDepth, (v) {
                setState(() => _profile = _profile.copyWith(mouthfillDepth: v));
              }),
              const SizedBox(height: 16),
              _buildMilestoneRow('프리폴 시작', _profile.freefallStartDepth, (v) {
                setState(() => _profile = _profile.copyWith(freefallStartDepth: v));
              }),
              if (hasWarning) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '마우스필이 프리폴보다 깊습니다',
                        style: AppTextStyles.caption.copyWith(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: AppTextStyles.body),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.muted,
                onPressed: () {
                  if (value > 5) onChanged(value - 5);
                },
              ),
              Text(
                '${value}m',
                style: AppTextStyles.monoSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.muted,
                onPressed: () {
                  if (value < _profile.targetDepth - 5) onChanged(value + 5);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTime() {
    final estimatedTime = _profile.estimatedDiveTime;
    final minutes = estimatedTime.inMinutes;
    final seconds = estimatedTime.inSeconds % 60;

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('예상 다이브 타임', style: AppTextStyles.body),
          Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.primaryBright,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final validationError = _profile.validate();
    final isValid = validationError == null;

    return Column(
      children: [
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              validationError,
              style: AppTextStyles.caption.copyWith(color: Colors.red),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? _startSimulation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBright,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surface,
              disabledForegroundColor: AppColors.muted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '시뮬레이션 시작',
              style: AppTextStyles.sectionTitle.copyWith(
                color: isValid ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _adjustMilestones() {
    // Ensure milestones are within target depth
    if (_profile.mouthfillDepth >= _profile.targetDepth) {
      _profile = _profile.copyWith(mouthfillDepth: _profile.targetDepth - 5);
    }
    if (_profile.freefallStartDepth >= _profile.targetDepth) {
      _profile = _profile.copyWith(freefallStartDepth: _profile.targetDepth - 10);
    }
  }

  void _startSimulation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimulationRunScreen(profile: _profile),
      ),
    );
  }
}
