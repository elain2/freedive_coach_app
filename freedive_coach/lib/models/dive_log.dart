import 'discipline.dart';
import 'media_attachment.dart';

/// A freediving dive log entry
class DiveLog {
  // Core fields
  final String id;
  final DateTime createdAt;
  final DateTime diveDate;
  final String? location;
  final Discipline discipline;
  final double? depth;       // meters (for depth disciplines)
  final double? distance;    // meters (for dynamic disciplines)
  final Duration? duration;  // hold time

  // Technique fields
  final double? mouthfillDepth;
  final double? freefallDepth;

  // Detail fields
  final double? weight;      // kg
  final String? equipment;
  final String? condition;
  final int? contractions;
  final List<String> tags;
  final List<String> buddies;
  final String? notes;

  // Meta fields
  final String? rawInput;
  final bool aiParsed;
  final List<MediaAttachment> media;

  const DiveLog({
    required this.id,
    required this.createdAt,
    required this.diveDate,
    this.location,
    required this.discipline,
    this.depth,
    this.distance,
    this.duration,
    this.mouthfillDepth,
    this.freefallDepth,
    this.weight,
    this.equipment,
    this.condition,
    this.contractions,
    this.tags = const [],
    this.buddies = const [],
    this.notes,
    this.rawInput,
    this.aiParsed = false,
    this.media = const [],
  });

  /// Create a new log with a generated ID
  factory DiveLog.create({
    required DateTime diveDate,
    required Discipline discipline,
    String? location,
    double? depth,
    double? distance,
    Duration? duration,
    double? mouthfillDepth,
    double? freefallDepth,
    double? weight,
    String? equipment,
    String? condition,
    int? contractions,
    List<String>? tags,
    List<String>? buddies,
    String? notes,
    String? rawInput,
    bool aiParsed = false,
    List<MediaAttachment>? media,
  }) {
    return DiveLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      diveDate: diveDate,
      location: location,
      discipline: discipline,
      depth: depth,
      distance: distance,
      duration: duration,
      mouthfillDepth: mouthfillDepth,
      freefallDepth: freefallDepth,
      weight: weight,
      equipment: equipment,
      condition: condition,
      contractions: contractions,
      tags: tags ?? [],
      buddies: buddies ?? [],
      notes: notes,
      rawInput: rawInput,
      aiParsed: aiParsed,
      media: media ?? [],
    );
  }

  /// Primary metric value based on discipline type
  double? get primaryMetric {
    if (discipline.isDepthDiscipline) return depth;
    if (discipline.isDistanceDiscipline) return distance;
    return null;
  }

  /// Formatted primary metric with unit
  String get primaryMetricFormatted {
    final value = primaryMetric;
    if (value == null) {
      if (discipline.isTimeDiscipline && duration != null) {
        return durationFormatted;
      }
      return '-';
    }
    return '${value.toStringAsFixed(0)}${discipline.primaryUnit}';
  }

  /// Formatted duration as mm:ss
  String get durationFormatted {
    if (duration == null) return '-';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted dive date
  String get diveDateFormatted {
    return '${diveDate.month}월 ${diveDate.day}일';
  }

  DiveLog copyWith({
    DateTime? diveDate,
    String? location,
    Discipline? discipline,
    double? depth,
    double? distance,
    Duration? duration,
    double? mouthfillDepth,
    double? freefallDepth,
    double? weight,
    String? equipment,
    String? condition,
    int? contractions,
    List<String>? tags,
    List<String>? buddies,
    String? notes,
    String? rawInput,
    bool? aiParsed,
    List<MediaAttachment>? media,
  }) {
    return DiveLog(
      id: id,
      createdAt: createdAt,
      diveDate: diveDate ?? this.diveDate,
      location: location ?? this.location,
      discipline: discipline ?? this.discipline,
      depth: depth ?? this.depth,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      mouthfillDepth: mouthfillDepth ?? this.mouthfillDepth,
      freefallDepth: freefallDepth ?? this.freefallDepth,
      weight: weight ?? this.weight,
      equipment: equipment ?? this.equipment,
      condition: condition ?? this.condition,
      contractions: contractions ?? this.contractions,
      tags: tags ?? this.tags,
      buddies: buddies ?? this.buddies,
      notes: notes ?? this.notes,
      rawInput: rawInput ?? this.rawInput,
      aiParsed: aiParsed ?? this.aiParsed,
      media: media ?? this.media,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'diveDate': diveDate.toIso8601String(),
    'location': location,
    'discipline': discipline.name,
    'depth': depth,
    'distance': distance,
    'durationSeconds': duration?.inSeconds,
    'mouthfillDepth': mouthfillDepth,
    'freefallDepth': freefallDepth,
    'weight': weight,
    'equipment': equipment,
    'condition': condition,
    'contractions': contractions,
    'tags': tags,
    'buddies': buddies,
    'notes': notes,
    'rawInput': rawInput,
    'aiParsed': aiParsed,
    'media': media.map((m) => m.toJson()).toList(),
  };

  factory DiveLog.fromJson(Map<String, dynamic> json) => DiveLog(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    diveDate: DateTime.parse(json['diveDate'] as String),
    location: json['location'] as String?,
    discipline: Discipline.values.byName(json['discipline'] as String),
    depth: (json['depth'] as num?)?.toDouble(),
    distance: (json['distance'] as num?)?.toDouble(),
    duration: json['durationSeconds'] != null
        ? Duration(seconds: json['durationSeconds'] as int)
        : null,
    mouthfillDepth: (json['mouthfillDepth'] as num?)?.toDouble(),
    freefallDepth: (json['freefallDepth'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    equipment: json['equipment'] as String?,
    condition: json['condition'] as String?,
    contractions: json['contractions'] as int?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    buddies: (json['buddies'] as List<dynamic>?)?.cast<String>() ?? [],
    notes: json['notes'] as String?,
    rawInput: json['rawInput'] as String?,
    aiParsed: json['aiParsed'] as bool? ?? false,
    media: (json['media'] as List<dynamic>?)
        ?.map((m) => MediaAttachment.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
  );
}
