import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/media_attachment.dart';
import 'database_service.dart';

/// Service for managing media attachments (photos/videos) for dive logs
class MediaService {
  final DatabaseService _dbService;

  MediaService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  static int _idCounter = 0;

  /// Add a new attachment to a dive log
  Future<MediaAttachment> addAttachment({
    required String logId,
    required MediaType type,
    required String filePath,
    String? thumbnailPath,
    String? comment,
  }) async {
    // Get current count to determine order
    final existingCount = await getAttachmentCount(logId);

    // Use microseconds + counter for unique ID
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

    final attachment = MediaAttachment(
      id: id,
      logId: logId,
      type: type,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      comment: comment,
      order: existingCount,
      createdAt: DateTime.now(),
    );

    await _dbService.insertMediaAttachment(attachment);
    return attachment;
  }

  /// Get all attachments for a dive log
  Future<List<MediaAttachment>> getAttachments(String logId) async {
    return await _dbService.getMediaAttachmentsByLogId(logId);
  }

  /// Get attachment count for a dive log
  Future<int> getAttachmentCount(String logId) async {
    final attachments = await getAttachments(logId);
    return attachments.length;
  }

  /// Update an attachment (e.g., comment)
  Future<void> updateAttachment(MediaAttachment attachment) async {
    await _dbService.updateMediaAttachment(attachment);
  }

  /// Delete an attachment
  Future<void> deleteAttachment(String attachmentId) async {
    await _dbService.deleteMediaAttachment(attachmentId);
  }

  /// Reorder attachments for a dive log
  Future<void> reorderAttachments(String logId, List<String> orderedIds) async {
    final attachments = await getAttachments(logId);

    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final attachment = attachments.firstWhere(
        (a) => a.id == id,
        orElse: () => throw StateError('Attachment not found: $id'),
      );

      if (attachment.order != i) {
        final updated = attachment.copyWith(order: i);
        await _dbService.updateMediaAttachment(updated);
      }
    }
  }

  /// Copy a file to app's media directory
  Future<String> saveMediaFile(String sourcePath, String logId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'media', logId));

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final fileName = path.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final destPath = path.join(mediaDir.path, newFileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    return destPath;
  }

  /// Delete a media file from storage
  Future<void> deleteMediaFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete all media files for a dive log
  Future<void> deleteAllMediaForLog(String logId) async {
    final attachments = await getAttachments(logId);

    for (final attachment in attachments) {
      await deleteMediaFile(attachment.filePath);
      if (attachment.thumbnailPath != null) {
        await deleteMediaFile(attachment.thumbnailPath!);
      }
      await deleteAttachment(attachment.id);
    }

    // Try to delete the log's media directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'media', logId));
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore directory deletion errors
    }
  }

  /// Get the media directory path for a log
  Future<String> getMediaDirectoryPath(String logId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'media', logId);
  }

  /// Check if a file exists
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
}
