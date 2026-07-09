import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/simulation_profile.dart';

/// Simulation phases
enum SimulationPhase {
  idle,           // Not started
  descent,        // Active descent (kicking)
  freefall,       // Passive freefall
  turn,           // At the bottom, turning
  ascent,         // Ascending to surface
  completed,      // Simulation finished
}

/// Simulation state
enum SimulationState {
  idle,
  running,
  paused,
  completed,
}

/// Callback types
typedef OnDepthChange = void Function(double depth, SimulationPhase phase);
typedef OnMilestone = void Function(Milestone milestone);
typedef OnSimulationComplete = void Function(Duration totalTime);

/// Service for running dive simulation
class SimulationService extends ChangeNotifier {
  SimulationProfile? _profile;
  SimulationState _state = SimulationState.idle;
  SimulationPhase _phase = SimulationPhase.idle;

  double _currentDepth = 0;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;

  // Milestones tracking
  final Set<MilestoneType> _passedMilestones = {};

  // Callbacks
  OnDepthChange? onDepthChange;
  OnMilestone? onMilestone;
  OnSimulationComplete? onSimulationComplete;

  // Getters
  SimulationState get state => _state;
  SimulationPhase get phase => _phase;
  double get currentDepth => _currentDepth;
  Duration get elapsedTime => _elapsedTime;
  SimulationProfile? get profile => _profile;
  bool get isRunning => _state == SimulationState.running;
  bool get isPaused => _state == SimulationState.paused;
  bool get isCompleted => _state == SimulationState.completed;

  /// Progress ratio (0.0 to 1.0) based on depth
  double get depthProgress {
    if (_profile == null) return 0;
    if (_phase == SimulationPhase.ascent || _phase == SimulationPhase.completed) {
      // During ascent, progress goes from 1.0 back to 0.0
      return _currentDepth / _profile!.targetDepth;
    }
    return _currentDepth / _profile!.targetDepth;
  }

  /// Current speed based on phase
  double get currentSpeed {
    if (_profile == null) return 0;
    switch (_phase) {
      case SimulationPhase.descent:
        return _profile!.descentSpeed;
      case SimulationPhase.freefall:
        return _profile!.freefallSpeed;
      case SimulationPhase.ascent:
        return _profile!.ascentSpeed;
      default:
        return 0;
    }
  }

  /// Initialize with a profile
  void initialize(SimulationProfile profile) {
    _profile = profile;
    _state = SimulationState.idle;
    _phase = SimulationPhase.idle;
    _currentDepth = 0;
    _elapsedTime = Duration.zero;
    _passedMilestones.clear();
    notifyListeners();
  }

  /// Start the simulation
  void start() {
    if (_profile == null || _state == SimulationState.completed) return;

    if (_state == SimulationState.idle) {
      _phase = SimulationPhase.descent;
      _currentDepth = 0;
      _elapsedTime = Duration.zero;
      _passedMilestones.clear();
    }

    _state = SimulationState.running;
    _startTicking();
    notifyListeners();
  }

  /// Pause the simulation
  void pause() {
    if (_state != SimulationState.running) return;
    _timer?.cancel();
    _state = SimulationState.paused;
    notifyListeners();
  }

  /// Resume from paused state
  void resume() {
    if (_state != SimulationState.paused) return;
    _state = SimulationState.running;
    _startTicking();
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _timer?.cancel();
    if (_profile != null) {
      _state = SimulationState.idle;
      _phase = SimulationPhase.idle;
      _currentDepth = 0;
      _elapsedTime = Duration.zero;
      _passedMilestones.clear();
    }
    notifyListeners();
  }

  /// Stop and clean up
  void stop() {
    _timer?.cancel();
    _profile = null;
    _state = SimulationState.idle;
    _phase = SimulationPhase.idle;
    _currentDepth = 0;
    _elapsedTime = Duration.zero;
    _passedMilestones.clear();
    notifyListeners();
  }

  void _startTicking() {
    _timer?.cancel();
    // Update every 50ms for smooth animation
    _timer = Timer.periodic(const Duration(milliseconds: 50), _onTick);
  }

  void _onTick(Timer timer) {
    if (_state != SimulationState.running || _profile == null) return;

    const tickDuration = Duration(milliseconds: 50);
    _elapsedTime += tickDuration;

    // Calculate depth change based on current phase
    final tickSeconds = tickDuration.inMilliseconds / 1000.0;

    switch (_phase) {
      case SimulationPhase.descent:
        _currentDepth += _profile!.descentSpeed * tickSeconds;
        _checkDescentMilestones();
        break;

      case SimulationPhase.freefall:
        _currentDepth += _profile!.freefallSpeed * tickSeconds;
        _checkFreefallMilestones();
        break;

      case SimulationPhase.turn:
        // Brief pause at bottom, then start ascent
        _phase = SimulationPhase.ascent;
        break;

      case SimulationPhase.ascent:
        _currentDepth -= _profile!.ascentSpeed * tickSeconds;
        if (_currentDepth <= 0) {
          _currentDepth = 0;
          _completeSimulation();
        }
        break;

      default:
        break;
    }

    onDepthChange?.call(_currentDepth, _phase);
    notifyListeners();
  }

  void _checkDescentMilestones() {
    final profile = _profile!;

    // Check mouthfill milestone
    if (!_passedMilestones.contains(MilestoneType.mouthfill) &&
        _currentDepth >= profile.mouthfillDepth) {
      _passedMilestones.add(MilestoneType.mouthfill);
      final milestone = Milestone(
        type: MilestoneType.mouthfill,
        depth: profile.mouthfillDepth,
        timeFromStart: _elapsedTime,
      );
      onMilestone?.call(milestone);
    }

    // Check freefall start
    if (_currentDepth >= profile.freefallStartDepth) {
      if (!_passedMilestones.contains(MilestoneType.freefall)) {
        _passedMilestones.add(MilestoneType.freefall);
        final milestone = Milestone(
          type: MilestoneType.freefall,
          depth: profile.freefallStartDepth,
          timeFromStart: _elapsedTime,
        );
        onMilestone?.call(milestone);
      }
      _phase = SimulationPhase.freefall;
    }
  }

  void _checkFreefallMilestones() {
    final profile = _profile!;

    // Check turn point (target depth)
    if (_currentDepth >= profile.targetDepth) {
      _currentDepth = profile.targetDepth.toDouble();
      _passedMilestones.add(MilestoneType.turn);
      final milestone = Milestone(
        type: MilestoneType.turn,
        depth: profile.targetDepth,
        timeFromStart: _elapsedTime,
      );
      onMilestone?.call(milestone);
      _phase = SimulationPhase.turn;
    }
  }

  void _completeSimulation() {
    _timer?.cancel();
    _phase = SimulationPhase.completed;
    _state = SimulationState.completed;

    _passedMilestones.add(MilestoneType.surface);
    final milestone = Milestone(
      type: MilestoneType.surface,
      depth: 0,
      timeFromStart: _elapsedTime,
    );
    onMilestone?.call(milestone);
    onSimulationComplete?.call(_elapsedTime);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
