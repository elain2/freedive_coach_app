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
            _buildDepthAlertsSection(),
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
                _profile = _profile.copyWith(targetDepth: _profile.targetDepth - 1);
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
                _profile = _profile.copyWith(targetDepth: _profile.targetDepth + 1);
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
                  if (value > 1) onChanged(value - 1);
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
                  if (value < _profile.targetDepth - 1) onChanged(value + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepthAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('수심 알림', style: AppTextStyles.sectionTitle),
            GestureDetector(
              onTap: _showAddAlertDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primaryBright),
                    const SizedBox(width: 4),
                    Text(
                      '추가',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_profile.depthAlerts.isEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            borderColor: Colors.transparent,
            child: Center(
              child: Text(
                '특정 수심에서 알림을 받으려면 추가하세요',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ),
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            borderColor: Colors.transparent,
            child: Column(
              children: [
                for (int i = 0; i < _profile.depthAlerts.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: AppColors.line),
                    ),
                  _buildAlertItem(_profile.depthAlerts[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertItem(DepthAlert alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.primaryBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${alert.depth}m', style: AppTextStyles.body),
                Row(
                  children: [
                    if (alert.onDescent)
                      _buildDirectionChip('하강', true),
                    if (alert.onDescent && alert.onAscent)
                      const SizedBox(width: 6),
                    if (alert.onAscent)
                      _buildDirectionChip('상승', false),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeAlert(alert),
            child: const Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionChip(String label, bool isDescent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDescent ? Icons.arrow_downward : Icons.arrow_upward,
            size: 10,
            color: AppColors.muted,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _showAddAlertDialog() {
    int selectedDepth = (_profile.targetDepth / 2).round();
    bool onDescent = true;
    bool onAscent = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('수심 알림 추가', style: AppTextStyles.titleSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Depth selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primaryBright,
                    onPressed: () {
                      if (selectedDepth > 1) {
                        setDialogState(() => selectedDepth--);
                      }
                    },
                  ),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedDepth}m',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.primaryBright,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primaryBright,
                    onPressed: () {
                      if (selectedDepth < _profile.targetDepth - 1) {
                        setDialogState(() => selectedDepth++);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Direction toggles
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => onDescent = !onDescent),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: onDescent ? AppColors.tealDim : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: onDescent ? AppColors.primaryBright : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: onDescent ? AppColors.primaryBright : AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '하강',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: onDescent ? AppColors.primaryBright : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => onAscent = !onAscent),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: onAscent ? AppColors.tealDim : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: onAscent ? AppColors.primaryBright : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: onAscent ? AppColors.primaryBright : AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '상승',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: onAscent ? AppColors.primaryBright : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: (!onDescent && !onAscent)
                  ? null
                  : () {
                      _addAlert(DepthAlert(
                        depth: selectedDepth,
                        onDescent: onDescent,
                        onAscent: onAscent,
                      ));
                      Navigator.pop(context);
                    },
              child: Text(
                '추가',
                style: AppTextStyles.body.copyWith(
                  color: (!onDescent && !onAscent) ? AppColors.muted : AppColors.primaryBright,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addAlert(DepthAlert alert) {
    // Check if alert at this depth already exists
    final existingIndex = _profile.depthAlerts.indexWhere((a) => a.depth == alert.depth);
    List<DepthAlert> newAlerts;

    if (existingIndex >= 0) {
      // Update existing alert
      newAlerts = List.from(_profile.depthAlerts);
      newAlerts[existingIndex] = alert;
    } else {
      // Add new alert and sort by depth
      newAlerts = [..._profile.depthAlerts, alert];
      newAlerts.sort((a, b) => a.depth.compareTo(b.depth));
    }

    setState(() {
      _profile = _profile.copyWith(depthAlerts: newAlerts);
    });
  }

  void _removeAlert(DepthAlert alert) {
    setState(() {
      _profile = _profile.copyWith(
        depthAlerts: _profile.depthAlerts.where((a) => a.depth != alert.depth).toList(),
      );
    });
  }

  Widget _buildEstimatedTime() {
    final estimatedTime = _profile.estimatedDiveTime;
    final calculatedTime = _profile.calculatedDiveTime;
    final minutes = estimatedTime.inMinutes;
    final seconds = estimatedTime.inSeconds % 60;
    final isCustom = _profile.isCustomDiveTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('다이브 타임', style: AppTextStyles.sectionTitle),
            if (isCustom)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _profile = _profile.copyWith(clearCustomDiveTime: true);
                  });
                },
                child: Text(
                  '자동 계산',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: isCustom ? AppColors.primaryBright.withValues(alpha: 0.5) : Colors.transparent,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primaryBright,
                    onPressed: () {
                      final newSeconds = estimatedTime.inSeconds - 5;
                      if (newSeconds >= 30) {
                        setState(() {
                          _profile = _profile.copyWith(
                            customDiveTime: Duration(seconds: newSeconds),
                          );
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
                      '$minutes:${seconds.toString().padLeft(2, '0')}',
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
                      final newSeconds = estimatedTime.inSeconds + 5;
                      if (newSeconds <= 600) { // Max 10 minutes
                        setState(() {
                          _profile = _profile.copyWith(
                            customDiveTime: Duration(seconds: newSeconds),
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              if (isCustom) ...[
                const SizedBox(height: 8),
                Text(
                  '자동 계산: ${calculatedTime.inMinutes}:${(calculatedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      ],
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
        GestureDetector(
          onTap: isValid ? _startSimulation : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isValid
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.tealDim],
                    )
                  : null,
              color: isValid ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isValid
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: isValid ? Colors.white : AppColors.muted,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '시뮬레이션 시작',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: isValid ? Colors.white : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _adjustMilestones() {
    // Ensure milestones are within target depth
    if (_profile.mouthfillDepth >= _profile.targetDepth) {
      _profile = _profile.copyWith(mouthfillDepth: _profile.targetDepth - 1);
    }
    if (_profile.freefallStartDepth >= _profile.targetDepth) {
      _profile = _profile.copyWith(freefallStartDepth: _profile.targetDepth - 2);
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
