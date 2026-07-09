import 'breathing_table.dart';

/// A completed training session record
class TrainingSession {
  final String id;
  final TableType tableType;
  final Duration personalBest;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalRounds;
  final int completedRounds;
  final bool isCompleted;

  const TrainingSession({
    required this.id,
    required this.tableType,
    required this.personalBest,
    required this.startedAt,
    this.completedAt,
    required this.totalRounds,
    required this.completedRounds,
    required this.isCompleted,
  });

  /// Create a new session from a breathing table
  factory TrainingSession.fromTable(BreathingTable table) {
    return TrainingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableType: table.type,
      personalBest: table.personalBest,
      startedAt: DateTime.now(),
      totalRounds: table.roundCount,
      completedRounds: 0,
      isCompleted: false,
    );
  }

  /// Create a copy with updated values
  TrainingSession copyWith({
    DateTime? completedAt,
    int? completedRounds,
    bool? isCompleted,
  }) {
    return TrainingSession(
      id: id,
      tableType: tableType,
      personalBest: personalBest,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalRounds: totalRounds,
      completedRounds: completedRounds ?? this.completedRounds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Duration of the training session
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Display name for the table type
  String get tableTypeName {
    switch (tableType) {
      case TableType.co2:
        return 'CO\u2082 테이블';
      case TableType.o2:
        return 'O\u2082 테이블';
    }
  }

  /// Format personal best as mm:ss
  String get personalBestFormatted {
    final minutes = personalBest.inMinutes;
    final seconds = personalBest.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableType': tableType.name,
    'personalBestSeconds': personalBest.inSeconds,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'totalRounds': totalRounds,
    'completedRounds': completedRounds,
    'isCompleted': isCompleted,
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'] as String,
    tableType: TableType.values.byName(json['tableType'] as String),
    personalBest: Duration(seconds: json['personalBestSeconds'] as int),
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    totalRounds: json['totalRounds'] as int,
    completedRounds: json['completedRounds'] as int,
    isCompleted: json['isCompleted'] as bool,
  );
}
