import '../models/discipline.dart';
import '../models/parsed_fields.dart';

/// Service for parsing free-form text into structured dive log fields
class TextParsingService {
  // Discipline patterns (no \b for Korean)
  static final _disciplinePatterns = {
    Discipline.cwt: RegExp(r'(CWT|콘스탄트\s*웨이트|콘스탄트(?!\s*노핀))', caseSensitive: false),
    Discipline.cnf: RegExp(r'(CNF|콘스탄트\s*노핀|(?<!다이나믹\s*)노핀)', caseSensitive: false),
    Discipline.fim: RegExp(r'(FIM|프리\s*이머전|프리이머전)', caseSensitive: false),
    Discipline.dyn: RegExp(r'(DYN(?!F)|다이나믹(?!\s*노핀))', caseSensitive: false),
    Discipline.dnf: RegExp(r'(DNF|다이나믹\s*노핀)', caseSensitive: false),
    Discipline.sta: RegExp(r'(STA|스태틱|스테틱)', caseSensitive: false),
  };

  // Depth patterns
  static final _depthPattern = RegExp(
    r'(?:수심\s*)?(\d+(?:\.\d+)?)\s*(?:m|M|미터)',
    caseSensitive: false,
  );

  // Distance pattern (for DYN/DNF)
  static final _distancePattern = RegExp(
    r'(?:거리\s*)?(\d+(?:\.\d+)?)\s*(?:m|M|미터)',
    caseSensitive: false,
  );

  // Mouthfill depth pattern
  static final _mouthfillPattern = RegExp(
    r'(?:마우스필|마필|MF|mf)\s*(\d+(?:\.\d+)?)\s*(?:m|M|미터)?\b',
    caseSensitive: false,
  );

  // Freefall depth pattern
  static final _freefallPattern = RegExp(
    r'(?:프리폴|프리폴링|FF|ff)\s*(\d+(?:\.\d+)?)\s*(?:m|M|미터)?\b',
    caseSensitive: false,
  );

  // Duration patterns
  static final _durationMinSecPattern = RegExp(
    r'(\d+)\s*분\s*(\d+)\s*초',
  );
  static final _durationMinOnlyPattern = RegExp(
    r'(\d+)\s*분(?!\s*\d+\s*초)',
  );
  static final _durationColonPattern = RegExp(
    r'(\d+):(\d{2})\b',
  );

  // Location patterns
  static final _locationWithSuffixPattern = RegExp(
    r'([\w가-힣]+(?:\s+[\w가-힣]+)?)\s*에서',
  );
  static final _commonLocations = [
    '제주', '서귀포', '협재', '부산', '기장', '울산', '강원', '속초',
    '필리핀', '모알보알', '보홀', '다합', '이집트', '태국', '인도네시아',
  ];

  // Condition keywords
  static final _conditionKeywords = [
    '귀', '이퀄', '타이트', '힘들', '컨트랙션', '아프', '불편', '좋았',
  ];

  // Date patterns (no \b for Korean)
  static final _todayPattern = RegExp(r'오늘');
  static final _yesterdayPattern = RegExp(r'어제');
  static final _datePattern = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일');

  /// Parse text and extract dive log fields
  ParsedFields parseText(String text) {
    if (text.trim().isEmpty) {
      return ParsedFields();
    }

    final Map<String, dynamic> fields = {};
    final Map<String, double> confidenceScores = {};

    // Parse discipline
    final discipline = _parseDiscipline(text);
    if (discipline != null) {
      fields['discipline'] = discipline.name;
      confidenceScores['discipline'] = 0.95;
    }

    // Parse depth or distance based on discipline
    final isDistanceDiscipline = discipline == Discipline.dyn || discipline == Discipline.dnf;

    if (isDistanceDiscipline) {
      final distance = _parseDistance(text);
      if (distance != null) {
        fields['distance'] = distance;
        confidenceScores['distance'] = 0.9;
      }
    } else {
      final depth = _parseDepth(text);
      if (depth != null) {
        fields['depth'] = depth;
        confidenceScores['depth'] = 0.95;
      }
    }

    // Parse duration (for STA)
    if (discipline == Discipline.sta || text.contains(RegExp(r'\d+\s*분'))) {
      final duration = _parseDuration(text);
      if (duration != null) {
        fields['durationMinutes'] = duration.inMinutes;
        fields['durationSeconds'] = duration.inSeconds % 60;
        confidenceScores['duration'] = 0.9;
      }
    }

    // Parse mouthfill depth
    final mouthfill = _parseMouthfillDepth(text);
    if (mouthfill != null) {
      fields['mouthfillDepth'] = mouthfill;
      confidenceScores['mouthfillDepth'] = 0.9;
    }

    // Parse freefall depth
    final freefall = _parseFreefallDepth(text);
    if (freefall != null) {
      fields['freefallDepth'] = freefall;
      confidenceScores['freefallDepth'] = 0.9;
    }

    // Parse location
    final location = _parseLocation(text);
    if (location != null) {
      fields['location'] = location;
      confidenceScores['location'] = 0.85;
    }

    // Parse condition
    final condition = _parseCondition(text);
    if (condition != null) {
      fields['condition'] = condition;
      confidenceScores['condition'] = 0.75;
    }

    // Parse date
    final date = _parseDate(text);
    if (date != null) {
      fields['date'] = date;
      confidenceScores['date'] = 0.9;
    }

    return ParsedFields(
      fields: fields,
      confidenceScores: confidenceScores,
    );
  }

  Discipline? _parseDiscipline(String text) {
    // Check DNF before DYN (more specific first)
    if (_disciplinePatterns[Discipline.dnf]!.hasMatch(text)) {
      return Discipline.dnf;
    }

    for (final entry in _disciplinePatterns.entries) {
      if (entry.key == Discipline.dnf) continue; // Already checked
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }
    return null;
  }

  double? _parseDepth(String text) {
    // Exclude mouthfill and freefall patterns
    String cleanText = text;
    cleanText = cleanText.replaceAll(_mouthfillPattern, '');
    cleanText = cleanText.replaceAll(_freefallPattern, '');

    final match = _depthPattern.firstMatch(cleanText);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  double? _parseDistance(String text) {
    final match = _distancePattern.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    // Fallback to depth pattern for DYN/DNF
    final depthMatch = _depthPattern.firstMatch(text);
    if (depthMatch != null) {
      return double.tryParse(depthMatch.group(1)!);
    }
    return null;
  }

  double? _parseMouthfillDepth(String text) {
    final match = _mouthfillPattern.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  double? _parseFreefallDepth(String text) {
    final match = _freefallPattern.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  Duration? _parseDuration(String text) {
    // Try minutes and seconds
    var match = _durationMinSecPattern.firstMatch(text);
    if (match != null) {
      final minutes = int.tryParse(match.group(1)!) ?? 0;
      final seconds = int.tryParse(match.group(2)!) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }

    // Try colon format (3:45)
    match = _durationColonPattern.firstMatch(text);
    if (match != null) {
      final minutes = int.tryParse(match.group(1)!) ?? 0;
      final seconds = int.tryParse(match.group(2)!) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }

    // Try minutes only
    match = _durationMinOnlyPattern.firstMatch(text);
    if (match != null) {
      final minutes = int.tryParse(match.group(1)!) ?? 0;
      return Duration(minutes: minutes);
    }

    return null;
  }

  String? _parseLocation(String text) {
    // Try "에서" pattern
    final suffixMatch = _locationWithSuffixPattern.firstMatch(text);
    if (suffixMatch != null) {
      return suffixMatch.group(1)?.trim();
    }

    // Try common location names
    for (final location in _commonLocations) {
      if (text.contains(location)) {
        // Try to find adjacent location words
        final pattern = RegExp('($location(?:\\s+[가-힣]+)?)', caseSensitive: false);
        final match = pattern.firstMatch(text);
        if (match != null) {
          return match.group(1)?.trim();
        }
      }
    }

    return null;
  }

  String? _parseCondition(String text) {
    final List<String> conditions = [];

    for (final keyword in _conditionKeywords) {
      if (text.contains(keyword)) {
        // Extract context around the keyword
        final pattern = RegExp('([가-힣]*$keyword[가-힣]*(?:\\s+[가-힣]+)?)', caseSensitive: false);
        final match = pattern.firstMatch(text);
        if (match != null) {
          conditions.add(match.group(1)!.trim());
        }
      }
    }

    if (conditions.isEmpty) return null;
    return conditions.join(', ');
  }

  DateTime? _parseDate(String text) {
    final now = DateTime.now();

    // Check "오늘"
    if (_todayPattern.hasMatch(text)) {
      return DateTime(now.year, now.month, now.day);
    }

    // Check "어제"
    if (_yesterdayPattern.hasMatch(text)) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }

    // Check explicit date (7월 8일)
    final dateMatch = _datePattern.firstMatch(text);
    if (dateMatch != null) {
      final month = int.tryParse(dateMatch.group(1)!) ?? now.month;
      final day = int.tryParse(dateMatch.group(2)!) ?? now.day;
      return DateTime(now.year, month, day);
    }

    return null;
  }
}
