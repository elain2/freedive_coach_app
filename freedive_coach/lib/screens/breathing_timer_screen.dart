import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../models/breathing_table.dart';
import '../models/training_session.dart';
import '../services/timer_service.dart';
import '../widgets/timer_display.dart';
import '../widgets/round_indicator.dart';
import 'breathing_complete_screen.dart';

class BreathingTimerScreen extends StatefulWidget {
  final BreathingTable table;

  const BreathingTimerScreen({
    super.key,
    required this.table,
  });

  @override
  State<BreathingTimerScreen> createState() => _BreathingTimerScreenState();
}

class _BreathingTimerScreenState extends State<BreathingTimerScreen>
    with WidgetsBindingObserver {
  late TimerService _timerService;
  late TrainingSession _session;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasVibrator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTimer();
    _initHardware();
  }

  void _initTimer() {
    _timerService = TimerService();
    _timerService.initialize(widget.table);
    _session = TrainingSession.fromTable(widget.table);

    _timerService.onPhaseChange = _onPhaseChange;
    _timerService.onRoundComplete = _onRoundComplete;
    _timerService.onTrainingComplete = _onTrainingComplete;
    _timerService.addListener(_onTimerUpdate);
  }

  Future<void> _initHardware() async {
    // Enable wakelock
    await WakelockPlus.enable();

    // Check for vibration support
    _hasVibrator = await Vibration.hasVibrator() ?? false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _timerService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause on phone call or app background (optional behavior)
    // Currently keeping timer running in background per spec
    if (state == AppLifecycleState.paused) {
      // Timer continues in background
    } else if (state == AppLifecycleState.resumed) {
      // Refresh UI
      setState(() {});
    }
  }

  void _onTimerUpdate() {
    if (mounted) setState(() {});
  }

  void _onPhaseChange(TimerPhase phase, int round) {
    _playAlert();
  }

  void _onRoundComplete(int round) {
    _session = _session.copyWith(completedRounds: round);
  }

  void _onTrainingComplete() {
    _session = _session.copyWith(
      completedAt: DateTime.now(),
      completedRounds: widget.table.roundCount,
      isCompleted: true,
    );
    _playCompleteSound();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BreathingCompleteScreen(session: _session),
      ),
    );
  }

  Future<void> _playAlert() async {
    // Play system sound
    await SystemSound.play(SystemSoundType.click);

    // Vibrate
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 300);
    }
  }

  Future<void> _playCompleteSound() async {
    // Play completion sound
    await SystemSound.play(SystemSoundType.alert);

    if (_hasVibrator) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }
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
        title: Text(
          widget.table.type == TableType.co2 ? 'CO\u2082 테이블' : 'O\u2082 테이블',
          style: AppTextStyles.titleSmall,
        ),
        actions: [
          if (_timerService.state != TimerState.idle)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.muted),
              onPressed: _showResetConfirmation,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Round indicator
            RoundIndicator(
              currentRound: _timerService.currentRound,
              totalRounds: widget.table.roundCount,
            ),
            const Spacer(flex: 1),
            // Timer display
            TimerDisplay(
              duration: _timerService.remainingTime,
              phase: _timerService.phase,
              progress: _timerService.progress,
            ),
            const Spacer(flex: 2),
            // Control buttons
            _buildControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_timerService.state == TimerState.idle) {
      return _buildStartButton();
    }
    return _buildPlayPauseButtons();
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _timerService.start,
      child: Container(
        width: 120,
        height: 120,
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
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button
        GestureDetector(
          onTap: _timerService.isRunning ? _timerService.pause : _timerService.resume,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerService.isRunning
                  ? AppColors.surface
                  : AppColors.primaryBright,
              border: Border.all(
                color: AppColors.primaryBright,
                width: 2,
              ),
            ),
            child: Icon(
              _timerService.isRunning ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: _timerService.isRunning
                  ? AppColors.primaryBright
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('훈련 종료', style: AppTextStyles.titleSmall),
        content: Text(
          '훈련을 종료하시겠습니까?\n진행 상황이 저장되지 않습니다.',
          style: AppTextStyles.body,
        ),
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
            child: Text('종료', style: AppTextStyles.body.copyWith(color: const Color(0xFFFF6B6B))),
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
        content: Text(
          '처음부터 다시 시작하시겠습니까?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _timerService.reset();
            },
            child: Text('다시 시작', style: AppTextStyles.body.copyWith(color: AppColors.primaryBright)),
          ),
        ],
      ),
    );
  }
}
