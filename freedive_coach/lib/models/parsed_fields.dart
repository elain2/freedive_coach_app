import 'discipline.dart';

/// Parsed fields extracted from text input with confidence scores
class ParsedFields {
  static const double lowConfidenceThreshold = 0.7;

  final Map<String, dynamic> fields;
  final Map<String, double> confidenceScores;

  ParsedFields({
    Map<String, dynamic>? fields,
    Map<String, double>? confidenceScores,
  })  : fields = fields ?? {},
        confidenceScores = confidenceScores ?? {};

  // ==================== Field Getters ====================

  String? get location => fields['location'] as String?;

  Discipline? get discipline {
    final value = fields['discipline'];
    if (value == null) return null;
    if (value is Discipline) return value;
    if (value is String) {
      try {
        return Discipline.values.byName(value.toLowerCase());
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? get depth {
    final value = fields['depth'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? get distance {
    final value = fields['distance'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Duration? get duration {
    final minutes = fields['durationMinutes'];
    final seconds = fields['durationSeconds'];
    if (minutes == null && seconds == null) return null;

    final mins = minutes is num ? minutes.toInt() : 0;
    final secs = seconds is num ? seconds.toInt() : 0;
    return Duration(minutes: mins, seconds: secs);
  }

  double? get mouthfillDepth {
    final value = fields['mouthfillDepth'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? get freefallDepth {
    final value = fields['freefallDepth'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? get weight {
    final value = fields['weight'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? get condition => fields['condition'] as String?;

  String? get notes => fields['notes'] as String?;

  DateTime? get date {
    final value = fields['date'];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ==================== Confidence Methods ====================

  double getConfidence(String fieldName) {
    return confidenceScores[fieldName] ?? 0.0;
  }

  bool isLowConfidence(String fieldName) {
    return getConfidence(fieldName) < lowConfidenceThreshold;
  }

  List<String> get lowConfidenceFields {
    return confidenceScores.entries
        .where((e) => e.value < lowConfidenceThreshold)
        .map((e) => e.key)
        .toList();
  }

  // ==================== Utility Methods ====================

  bool hasField(String fieldName) {
    return fields.containsKey(fieldName) && fields[fieldName] != null;
  }

  int get fieldCount {
    return fields.entries.where((e) => e.value != null).length;
  }

  ParsedFields copyWithField(String fieldName, dynamic value, {double? confidence}) {
    final newFields = Map<String, dynamic>.from(fields);
    newFields[fieldName] = value;

    final newConfidence = Map<String, double>.from(confidenceScores);
    if (confidence != null) {
      newConfidence[fieldName] = confidence;
    }

    return ParsedFields(
      fields: newFields,
      confidenceScores: newConfidence,
    );
  }

  // ==================== Serialization ====================

  Map<String, dynamic> toJson() => {
    'fields': fields,
    'confidenceScores': confidenceScores,
  };

  factory ParsedFields.fromJson(Map<String, dynamic> json) => ParsedFields(
    fields: Map<String, dynamic>.from(json['fields'] as Map? ?? {}),
    confidenceScores: Map<String, double>.from(
      (json['confidenceScores'] as Map? ?? {}).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    ),
  );
}
