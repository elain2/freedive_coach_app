import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/models/discipline.dart';

void main() {
  group('Discipline', () {
    group('displayName', () {
      test('CWT returns uppercase abbreviation', () {
        expect(Discipline.cwt.displayName, 'CWT');
      });

      test('CNF returns uppercase abbreviation', () {
        expect(Discipline.cnf.displayName, 'CNF');
      });

      test('FIM returns uppercase abbreviation', () {
        expect(Discipline.fim.displayName, 'FIM');
      });

      test('DYN returns uppercase abbreviation', () {
        expect(Discipline.dyn.displayName, 'DYN');
      });

      test('DNF returns uppercase abbreviation', () {
        expect(Discipline.dnf.displayName, 'DNF');
      });

      test('STA returns uppercase abbreviation', () {
        expect(Discipline.sta.displayName, 'STA');
      });
    });

    group('fullName', () {
      test('CWT returns Korean full name', () {
        expect(Discipline.cwt.fullName, '콘스탄트 웨이트');
      });

      test('STA returns Korean full name', () {
        expect(Discipline.sta.fullName, '스태틱');
      });
    });

    group('fullNameEn', () {
      test('CWT returns English full name', () {
        expect(Discipline.cwt.fullNameEn, 'Constant Weight');
      });

      test('STA returns English full name', () {
        expect(Discipline.sta.fullNameEn, 'Static Apnea');
      });
    });

    group('isDepthDiscipline', () {
      test('CWT is a depth discipline', () {
        expect(Discipline.cwt.isDepthDiscipline, true);
      });

      test('CNF is a depth discipline', () {
        expect(Discipline.cnf.isDepthDiscipline, true);
      });

      test('FIM is a depth discipline', () {
        expect(Discipline.fim.isDepthDiscipline, true);
      });

      test('DYN is not a depth discipline', () {
        expect(Discipline.dyn.isDepthDiscipline, false);
      });

      test('DNF is not a depth discipline', () {
        expect(Discipline.dnf.isDepthDiscipline, false);
      });

      test('STA is not a depth discipline', () {
        expect(Discipline.sta.isDepthDiscipline, false);
      });
    });

    group('isDistanceDiscipline', () {
      test('DYN is a distance discipline', () {
        expect(Discipline.dyn.isDistanceDiscipline, true);
      });

      test('DNF is a distance discipline', () {
        expect(Discipline.dnf.isDistanceDiscipline, true);
      });

      test('CWT is not a distance discipline', () {
        expect(Discipline.cwt.isDistanceDiscipline, false);
      });

      test('STA is not a distance discipline', () {
        expect(Discipline.sta.isDistanceDiscipline, false);
      });
    });

    group('isTimeDiscipline', () {
      test('STA is a time discipline', () {
        expect(Discipline.sta.isTimeDiscipline, true);
      });

      test('CWT is not a time discipline', () {
        expect(Discipline.cwt.isTimeDiscipline, false);
      });

      test('DYN is not a time discipline', () {
        expect(Discipline.dyn.isTimeDiscipline, false);
      });
    });

    group('primaryUnit', () {
      test('depth disciplines return m', () {
        expect(Discipline.cwt.primaryUnit, 'm');
        expect(Discipline.cnf.primaryUnit, 'm');
        expect(Discipline.fim.primaryUnit, 'm');
      });

      test('distance disciplines return m', () {
        expect(Discipline.dyn.primaryUnit, 'm');
        expect(Discipline.dnf.primaryUnit, 'm');
      });

      test('time disciplines return empty string', () {
        expect(Discipline.sta.primaryUnit, '');
      });
    });
  });
}
