/// Type of media attachment
enum MediaType {
  photo,
  video,
}

/// A media attachment associated with a dive log
class MediaAttachment {
  final String id;
  final String logId;
  final MediaType type;
  final String filePath;
  final String? thumbnailPath;
  final String? comment;
  final int order;
  final DateTime createdAt;

  const MediaAttachment({
    required this.id,
    required this.logId,
    required this.type,
    required this.filePath,
    this.thumbnailPath,
    this.comment,
    required this.order,
    required this.createdAt,
  });

  /// Create a new attachment with a generated ID
  factory MediaAttachment.create({
    required String logId,
    required MediaType type,
    required String filePath,
    String? thumbnailPath,
    String? comment,
    int order = 0,
  }) {
    return MediaAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      logId: logId,
      type: type,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      comment: comment,
      order: order,
      createdAt: DateTime.now(),
    );
  }

  MediaAttachment copyWith({
    String? logId,
    MediaType? type,
    String? filePath,
    String? thumbnailPath,
    String? comment,
    int? order,
  }) {
    return MediaAttachment(
      id: id,
      logId: logId ?? this.logId,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      comment: comment ?? this.comment,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'logId': logId,
    'type': type.name,
    'filePath': filePath,
    'thumbnailPath': thumbnailPath,
    'comment': comment,
    'order': order,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MediaAttachment.fromJson(Map<String, dynamic> json) => MediaAttachment(
    id: json['id'] as String,
    logId: json['logId'] as String,
    type: MediaType.values.byName(json['type'] as String),
    filePath: json['filePath'] as String,
    thumbnailPath: json['thumbnailPath'] as String?,
    comment: json['comment'] as String?,
    order: json['order'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
