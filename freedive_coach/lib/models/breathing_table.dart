/// Type of breathing training table
enum TableType {
  co2, // Fixed hold time, decreasing recovery
  o2,  // Fixed recovery time, increasing hold time
}

/// A single round in a breathing table
class TableRound {
  final int roundNumber;
  final Duration recoveryTime;
  final Duration holdTime;

  const TableRound({
    required this.roundNumber,
    required this.recoveryTime,
    required this.holdTime,
  });

  Map<String, dynamic> toJson() => {
    'roundNumber': roundNumber,
    'recoverySeconds': recoveryTime.inSeconds,
    'holdSeconds': holdTime.inSeconds,
  };

  factory TableRound.fromJson(Map<String, dynamic> json) => TableRound(
    roundNumber: json['roundNumber'] as int,
    recoveryTime: Duration(seconds: json['recoverySeconds'] as int),
    holdTime: Duration(seconds: json['holdSeconds'] as int),
  );
}

/// A complete breathing training table
class BreathingTable {
  final TableType type;
  final Duration personalBest;
  final List<TableRound> rounds;
  final DateTime createdAt;

  const BreathingTable({
    required this.type,
    required this.personalBest,
    required this.rounds,
    required this.createdAt,
  });

  /// Total estimated duration of the training
  Duration get totalDuration {
    return rounds.fold(
      Duration.zero,
      (total, round) => total + round.recoveryTime + round.holdTime,
    );
  }

  /// Number of rounds in the table
  int get roundCount => rounds.length;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'personalBestSeconds': personalBest.inSeconds,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory BreathingTable.fromJson(Map<String, dynamic> json) => BreathingTable(
    type: TableType.values.byName(json['type'] as String),
    personalBest: Duration(seconds: json['personalBestSeconds'] as int),
    rounds: (json['rounds'] as List)
        .map((r) => TableRound.fromJson(r as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
