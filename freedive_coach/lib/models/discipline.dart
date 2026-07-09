/// Freediving discipline types
enum Discipline {
  cwt,  // Constant Weight
  cnf,  // Constant Weight No Fins
  fim,  // Free Immersion
  dyn,  // Dynamic With Fins
  dnf,  // Dynamic No Fins
  sta,  // Static Apnea
}

extension DisciplineExtension on Discipline {
  /// Short display name (uppercase)
  String get displayName {
    switch (this) {
      case Discipline.cwt:
        return 'CWT';
      case Discipline.cnf:
        return 'CNF';
      case Discipline.fim:
        return 'FIM';
      case Discipline.dyn:
        return 'DYN';
      case Discipline.dnf:
        return 'DNF';
      case Discipline.sta:
        return 'STA';
    }
  }

  /// Full name in Korean
  String get fullName {
    switch (this) {
      case Discipline.cwt:
        return '콘스탄트 웨이트';
      case Discipline.cnf:
        return '콘스탄트 노핀';
      case Discipline.fim:
        return '프리 이머전';
      case Discipline.dyn:
        return '다이나믹';
      case Discipline.dnf:
        return '다이나믹 노핀';
      case Discipline.sta:
        return '스태틱';
    }
  }

  /// Full name in English
  String get fullNameEn {
    switch (this) {
      case Discipline.cwt:
        return 'Constant Weight';
      case Discipline.cnf:
        return 'Constant Weight No Fins';
      case Discipline.fim:
        return 'Free Immersion';
      case Discipline.dyn:
        return 'Dynamic With Fins';
      case Discipline.dnf:
        return 'Dynamic No Fins';
      case Discipline.sta:
        return 'Static Apnea';
    }
  }

  /// Whether this discipline measures depth (vs distance or time)
  bool get isDepthDiscipline {
    switch (this) {
      case Discipline.cwt:
      case Discipline.cnf:
      case Discipline.fim:
        return true;
      case Discipline.dyn:
      case Discipline.dnf:
      case Discipline.sta:
        return false;
    }
  }

  /// Whether this discipline measures distance
  bool get isDistanceDiscipline {
    switch (this) {
      case Discipline.dyn:
      case Discipline.dnf:
        return true;
      case Discipline.cwt:
      case Discipline.cnf:
      case Discipline.fim:
      case Discipline.sta:
        return false;
    }
  }

  /// Whether this discipline measures time only
  bool get isTimeDiscipline {
    return this == Discipline.sta;
  }

  /// Primary metric unit for this discipline
  String get primaryUnit {
    if (isDepthDiscipline) return 'm';
    if (isDistanceDiscipline) return 'm';
    return '';
  }
}
