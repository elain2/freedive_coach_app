import '../models/breathing_table.dart';

/// Service for generating CO2 and O2 breathing training tables
class TableGenerator {
  static const int defaultRoundCount = 8;

  // CO2 table constants
  static const double co2HoldTimeRatio = 0.5; // Hold time = PB * 50%
  static const int co2InitialRecoverySeconds = 120; // Start with 2 minutes
  static const int co2RecoveryDecreaseSeconds = 15; // Decrease by 15 seconds each round

  // O2 table constants
  static const double o2InitialHoldTimeRatio = 0.4; // Start at PB * 40%
  static const int o2FixedRecoverySeconds = 120; // Fixed 2 minutes recovery
  static const double o2HoldTimeIncreaseRatio = 0.075; // Increase by 7.5% of PB each round

  /// Generate a CO2 table based on personal best
  ///
  /// CO2 Table characteristics:
  /// - Hold time is fixed at 50% of PB
  /// - Recovery time starts at 2 minutes and decreases by 15 seconds each round
  /// - Minimum recovery time is 15 seconds
  static BreathingTable generateCO2Table(Duration personalBest) {
    final holdTime = Duration(
      seconds: (personalBest.inSeconds * co2HoldTimeRatio).round(),
    );

    final rounds = List.generate(defaultRoundCount, (index) {
      final recoverySeconds = co2InitialRecoverySeconds -
          (index * co2RecoveryDecreaseSeconds);
      // Ensure minimum recovery time of 15 seconds
      final adjustedRecoverySeconds = recoverySeconds.clamp(15, co2InitialRecoverySeconds);

      return TableRound(
        roundNumber: index + 1,
        recoveryTime: Duration(seconds: adjustedRecoverySeconds),
        holdTime: holdTime,
      );
    });

    return BreathingTable(
      type: TableType.co2,
      personalBest: personalBest,
      rounds: rounds,
      createdAt: DateTime.now(),
    );
  }

  /// Generate an O2 table based on personal best
  ///
  /// O2 Table characteristics:
  /// - Recovery time is fixed at 2 minutes
  /// - Hold time starts at 40% of PB and increases progressively
  /// - Final round approaches or reaches PB
  static BreathingTable generateO2Table(Duration personalBest) {
    final pbSeconds = personalBest.inSeconds;
    final initialHoldSeconds = (pbSeconds * o2InitialHoldTimeRatio).round();
    final holdIncreaseSeconds = (pbSeconds * o2HoldTimeIncreaseRatio).round();

    final rounds = List.generate(defaultRoundCount, (index) {
      final holdSeconds = initialHoldSeconds + (index * holdIncreaseSeconds);
      // Cap at personal best
      final adjustedHoldSeconds = holdSeconds.clamp(initialHoldSeconds, pbSeconds);

      return TableRound(
        roundNumber: index + 1,
        recoveryTime: const Duration(seconds: o2FixedRecoverySeconds),
        holdTime: Duration(seconds: adjustedHoldSeconds),
      );
    });

    return BreathingTable(
      type: TableType.o2,
      personalBest: personalBest,
      rounds: rounds,
      createdAt: DateTime.now(),
    );
  }

  /// Generate a table based on type and personal best
  static BreathingTable generateTable(TableType type, Duration personalBest) {
    switch (type) {
      case TableType.co2:
        return generateCO2Table(personalBest);
      case TableType.o2:
        return generateO2Table(personalBest);
    }
  }
}
