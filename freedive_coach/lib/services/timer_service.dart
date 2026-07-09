import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/breathing_table.dart';

/// Timer states for the breathing training
enum TimerState {
  idle,       // Not started
  running,    // Timer is counting down
  paused,     // Timer is paused
  completed,  // All rounds finished
}

/// Current phase within a round
enum TimerPhase {
  recovery,   // Rest/breathing phase
  breathHold, // Holding breath phase
}

/// Callback types for timer events
typedef OnPhaseChange = void Function(TimerPhase phase, int round);
typedef OnTick = void Function(Duration remaining);
typedef OnRoundComplete = void Function(int round);
typedef OnTrainingComplete = void Function();

/// Service for managing breathing training timer with deterministic state machine
class TimerService extends ChangeNotifier {
  BreathingTable? _table;
  TimerState _state = TimerState.idle;
  TimerPhase _phase = TimerPhase.recovery;
  int _currentRound = 1;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;

  // Callbacks
  OnPhaseChange? onPhaseChange;
  OnTick? onTick;
  OnRoundComplete? onRoundComplete;
  OnTrainingComplete? onTrainingComplete;

  // Getters
  TimerState get state => _state;
  TimerPhase get phase => _phase;
  int get currentRound => _currentRound;
  Duration get remainingTime => _remainingTime;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isCompleted => _state == TimerState.completed;
  BreathingTable? get table => _table;

  /// Current round data
  TableRound? get currentRoundData {
    if (_table == null || _currentRound > _table!.roundCount) return null;
    return _table!.rounds[_currentRound - 1];
  }

  /// Total duration for current phase
  Duration get currentPhaseDuration {
    final round = currentRoundData;
    if (round == null) return Duration.zero;
    return _phase == TimerPhase.recovery ? round.recoveryTime : round.holdTime;
  }

  /// Progress ratio (0.0 to 1.0) for current phase
  double get progress {
    final total = currentPhaseDuration;
    if (total == Duration.zero) return 0;
    return 1 - (_remainingTime.inMilliseconds / total.inMilliseconds);
  }

  /// Initialize timer with a breathing table
  void initialize(BreathingTable table) {
    _table = table;
    _state = TimerState.idle;
    _phase = TimerPhase.recovery;
    _currentRound = 1;
    _remainingTime = table.rounds.first.recoveryTime;
    notifyListeners();
  }

  /// Start the timer
  void start() {
    if (_table == null || _state == TimerState.completed) return;
    if (_state == TimerState.idle) {
      _phase = TimerPhase.recovery;
      _remainingTime = currentRoundData!.recoveryTime;
      onPhaseChange?.call(_phase, _currentRound);
    }
    _state = TimerState.running;
    _startTicking();
    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    if (_state != TimerState.running) return;
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  /// Resume from paused state
  void resume() {
    if (_state != TimerState.paused) return;
    _state = TimerState.running;
    _startTicking();
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _timer?.cancel();
    if (_table != null) {
      _state = TimerState.idle;
      _phase = TimerPhase.recovery;
      _currentRound = 1;
      _remainingTime = _table!.rounds.first.recoveryTime;
    } else {
      _state = TimerState.idle;
      _phase = TimerPhase.recovery;
      _currentRound = 1;
      _remainingTime = Duration.zero;
    }
    notifyListeners();
  }

  /// Stop and clean up
  void stop() {
    _timer?.cancel();
    _table = null;
    _state = TimerState.idle;
    _phase = TimerPhase.recovery;
    _currentRound = 1;
    _remainingTime = Duration.zero;
    notifyListeners();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTick);
  }

  void _onTick(Timer timer) {
    if (_state != TimerState.running) return;

    // Decrease remaining time by 100ms
    final newRemaining = _remainingTime - const Duration(milliseconds: 100);

    if (newRemaining <= Duration.zero) {
      _remainingTime = Duration.zero;
      _transitionPhase();
    } else {
      _remainingTime = newRemaining;
      onTick?.call(_remainingTime);
      notifyListeners();
    }
  }

  void _transitionPhase() {
    if (_phase == TimerPhase.recovery) {
      // Transition to breath hold
      _phase = TimerPhase.breathHold;
      _remainingTime = currentRoundData!.holdTime;
      onPhaseChange?.call(_phase, _currentRound);
    } else {
      // Breath hold finished, check if more rounds
      onRoundComplete?.call(_currentRound);

      if (_currentRound >= _table!.roundCount) {
        // Training complete
        _timer?.cancel();
        _state = TimerState.completed;
        onTrainingComplete?.call();
      } else {
        // Move to next round
        _currentRound++;
        _phase = TimerPhase.recovery;
        _remainingTime = currentRoundData!.recoveryTime;
        onPhaseChange?.call(_phase, _currentRound);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
