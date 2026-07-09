/// Dive simulation profile with all parameters
class SimulationProfile {
  final String id;
  final String name;
  final int targetDepth;        // Target depth in meters
  final double descentSpeed;    // Descent speed in m/s
  final double ascentSpeed;     // Ascent speed in m/s
  final int freefallStartDepth; // Freefall start depth in meters
  final double freefallSpeed;   // Freefall speed in m/s
  final int mouthfillDepth;     // Mouthfill depth in meters
  final DateTime createdAt;

  const SimulationProfile({
    required this.id,
    required this.name,
    required this.targetDepth,
    required this.descentSpeed,
    required this.ascentSpeed,
    required this.freefallStartDepth,
    required this.freefallSpeed,
    required this.mouthfillDepth,
    required this.createdAt,
  });

  /// Default profile for beginners
  factory SimulationProfile.defaultProfile() {
    return SimulationProfile(
      id: 'default',
      name: '기본 프로필',
      targetDepth: 30,
      descentSpeed: 1.0,
      ascentSpeed: 1.0,
      freefallStartDepth: 20,
      freefallSpeed: 1.3,
      mouthfillDepth: 25,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate estimated dive time
  Duration get estimatedDiveTime {
    // Descent: active kick to freefall start + freefall to target
    final activeDescentDepth = freefallStartDepth;
    final freefallDepth = targetDepth - freefallStartDepth;

    final activeDescentTime = activeDescentDepth / descentSpeed;
    final freefallTime = freefallDepth / freefallSpeed;
    final ascentTime = targetDepth / ascentSpeed;

    final totalSeconds = activeDescentTime + freefallTime + ascentTime;
    return Duration(seconds: totalSeconds.round());
  }

  /// Validate profile parameters
  String? validate() {
    if (targetDepth <= 0) return '목표 수심은 0보다 커야 합니다';
    if (freefallStartDepth >= targetDepth) return '프리폴 시작 수심은 목표 수심보다 작아야 합니다';
    if (mouthfillDepth > targetDepth) return '마우스필 수심은 목표 수심 이하여야 합니다';
    if (descentSpeed <= 0 || ascentSpeed <= 0 || freefallSpeed <= 0) {
      return '속도는 0보다 커야 합니다';
    }
    return null;
  }

  /// Check if mouthfill depth is valid (should be before freefall ideally)
  bool get isMouthfillWarning => mouthfillDepth > freefallStartDepth;

  SimulationProfile copyWith({
    String? id,
    String? name,
    int? targetDepth,
    double? descentSpeed,
    double? ascentSpeed,
    int? freefallStartDepth,
    double? freefallSpeed,
    int? mouthfillDepth,
    DateTime? createdAt,
  }) {
    return SimulationProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDepth: targetDepth ?? this.targetDepth,
      descentSpeed: descentSpeed ?? this.descentSpeed,
      ascentSpeed: ascentSpeed ?? this.ascentSpeed,
      freefallStartDepth: freefallStartDepth ?? this.freefallStartDepth,
      freefallSpeed: freefallSpeed ?? this.freefallSpeed,
      mouthfillDepth: mouthfillDepth ?? this.mouthfillDepth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetDepth': targetDepth,
    'descentSpeed': descentSpeed,
    'ascentSpeed': ascentSpeed,
    'freefallStartDepth': freefallStartDepth,
    'freefallSpeed': freefallSpeed,
    'mouthfillDepth': mouthfillDepth,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SimulationProfile.fromJson(Map<String, dynamic> json) => SimulationProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    targetDepth: json['targetDepth'] as int,
    descentSpeed: (json['descentSpeed'] as num).toDouble(),
    ascentSpeed: (json['ascentSpeed'] as num).toDouble(),
    freefallStartDepth: json['freefallStartDepth'] as int,
    freefallSpeed: (json['freefallSpeed'] as num).toDouble(),
    mouthfillDepth: json['mouthfillDepth'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Milestone types during simulation
enum MilestoneType {
  mouthfill,  // Mouthfill depth reached
  freefall,   // Freefall start
  turn,       // Bottom/turn point
  surface,    // Surface reached
}

/// A milestone event during simulation
class Milestone {
  final MilestoneType type;
  final int depth;
  final Duration timeFromStart;

  const Milestone({
    required this.type,
    required this.depth,
    required this.timeFromStart,
  });

  String get displayName {
    switch (type) {
      case MilestoneType.mouthfill:
        return '마우스필';
      case MilestoneType.freefall:
        return '프리폴';
      case MilestoneType.turn:
        return '턴';
      case MilestoneType.surface:
        return '수면';
    }
  }
}
