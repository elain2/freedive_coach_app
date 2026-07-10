import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../models/simulation_profile.dart';
import '../services/simulation_service.dart';
import '../widgets/depth_gauge.dart';

class SimulationRunScreen extends StatefulWidget {
  final SimulationProfile profile;

  const SimulationRunScreen({
    super.key,
    required this.profile,
  });

  @override
  State<SimulationRunScreen> createState() => _SimulationRunScreenState();
}

class _SimulationRunScreenState extends State<SimulationRunScreen> {
  late SimulationService _simulationService;
  bool _hasVibrator = false;
  String? _lastMilestone;

  @override
  void initState() {
    super.initState();
    _initSimulation();
    _initHardware();
  }

  void _initSimulation() {
    _simulationService = SimulationService();
    _simulationService.initialize(widget.profile);

    _simulationService.onMilestone = _onMilestone;
    _simulationService.onSimulationComplete = _onComplete;
    _simulationService.addListener(_onUpdate);
  }

  Future<void> _initHardware() async {
    await WakelockPlus.enable();
    _hasVibrator = await Vibration.hasVibrator() ?? false;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _simulationService.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onMilestone(Milestone milestone) {
    setState(() {
      _lastMilestone = milestone.displayName;
    });

    // Play alert
    SystemSound.play(SystemSoundType.click);
    if (_hasVibrator) {
      Vibration.vibrate(duration: 200);
    }

    // Clear milestone display after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _lastMilestone == milestone.displayName) {
        setState(() => _lastMilestone = null);
      }
    });
  }

  void _onComplete(Duration totalTime) {
    // Play completion sound
    SystemSound.play(SystemSoundType.alert);
    if (_hasVibrator) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }

    // Show completion dialog
    _showCompletionDialog(totalTime);
  }

  void _showCompletionDialog(Duration totalTime) {
    final minutes = totalTime.inMinutes;
    final seconds = totalTime.inSeconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryBright),
            const SizedBox(width: 12),
            Text('시뮬레이션 완료', style: AppTextStyles.titleSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '총 다이브 타임',
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primaryBright,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '목표 수심: ${widget.profile.targetDepth}m',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _simulationService.reset();
            },
            child: Text('다시 하기', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to setup
            },
            child: Text('완료', style: AppTextStyles.body.copyWith(color: AppColors.primaryBright)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.text),
          onPressed: _showExitConfirmation,
        ),
        title: Text('${widget.profile.targetDepth}m 시뮬레이션', style: AppTextStyles.titleSmall),
        actions: [
          if (_simulationService.state != SimulationState.idle)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.muted),
              onPressed: _showResetConfirmation,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Elapsed time
              _buildElapsedTime(),
              const SizedBox(height: 16),
              // Milestone alert
              if (_lastMilestone != null) _buildMilestoneAlert(),
              const SizedBox(height: 16),
              // Depth gauge
              Expanded(
                child: DepthGauge(
                  currentDepth: _simulationService.currentDepth,
                  targetDepth: widget.profile.targetDepth,
                  mouthfillDepth: widget.profile.mouthfillDepth,
                  freefallDepth: widget.profile.freefallStartDepth,
                  phase: _simulationService.phase,
                ),
              ),
              const SizedBox(height: 20),
              // Controls
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElapsedTime() {
    final elapsed = _simulationService.elapsedTime;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final millis = (elapsed.inMilliseconds % 1000) ~/ 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$minutes:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: AppColors.text,
          ),
        ),
        Text(
          '.$millis',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBright.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBright),
      ),
      child: Text(
        _lastMilestone!,
        style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primaryBright),
      ),
    );
  }

  Widget _buildControls() {
    if (_simulationService.state == SimulationState.idle) {
      return _buildStartButton();
    }
    return _buildPlayPauseButton();
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _simulationService.start,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBright,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBright.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    final isRunning = _simulationService.isRunning;

    return GestureDetector(
      onTap: isRunning ? _simulationService.pause : _simulationService.resume,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning ? AppColors.surface : AppColors.primaryBright,
          border: Border.all(color: AppColors.primaryBright, width: 2),
        ),
        child: Icon(
          isRunning ? Icons.pause : Icons.play_arrow,
          size: 40,
          color: isRunning ? AppColors.primaryBright : Colors.white,
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('시뮬레이션 종료', style: AppTextStyles.titleSmall),
        content: Text('시뮬레이션을 종료하시겠습니까?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('종료', style: AppTextStyles.body.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('처음부터 다시', style: AppTextStyles.titleSmall),
        content: Text('시뮬레이션을 처음부터 다시 시작하시겠습니까?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulationService.reset();
            },
            child: Text('다시 시작', style: AppTextStyles.body.copyWith(color: AppColors.primaryBright)),
          ),
        ],
      ),
    );
  }
}
