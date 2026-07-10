import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

/// Result of frame extraction
class ExtractResult {
  final List<String> frames; // base64 JPEG, no data: prefix
  final String thumbnail; // base64 JPEG
  final double durationSeconds;
  final int frameCount;

  const ExtractResult({
    required this.frames,
    required this.thumbnail,
    required this.durationSeconds,
    required this.frameCount,
  });
}

/// Service for extracting frames from video/images for analysis
class FrameExtractorService {
  static const int maxEdge = 720;
  static const int jpegQuality = 78;

  /// Determine frame count based on video duration
  static int frameCountFor(double durationSeconds) {
    if (durationSeconds <= 30) return 5;
    if (durationSeconds <= 60) return 8;
    if (durationSeconds <= 120) return 10;
    return 12;
  }

  /// Extract base64 from an image file
  /// Resizes to maxEdge if needed
  Future<String> extractFromImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // Decode and resize if needed
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calculate scale factor
    final scale = image.width > maxEdge ? maxEdge / image.width : 1.0;

    final targetWidth = (image.width * scale).round();
    final targetHeight = (image.height * scale).round();

    // Create a new image at target size
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);

    // Convert to JPEG bytes
    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    // Encode to base64
    return base64Encode(byteData.buffer.asUint8List());
  }

  /// Extract frames from multiple image files
  Future<ExtractResult> extractFromImages(
    List<File> imageFiles, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images provided');
    }

    final frames = <String>[];

    for (var i = 0; i < imageFiles.length; i++) {
      final frame = await extractFromImage(imageFiles[i]);
      frames.add(frame);
      onProgress?.call(i + 1, imageFiles.length);
    }

    return ExtractResult(
      frames: frames,
      thumbnail: frames[frames.length ~/ 2],
      durationSeconds: 0,
      frameCount: frames.length,
    );
  }

  /// Read image file and return base64 encoded string
  /// This is a simpler version that doesn't resize
  Future<String> readImageAsBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Extract frames from a video file
  Future<ExtractResult> extractFromVideo(
    File videoFile, {
    int frameCount = 8,
    void Function(int done, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw Exception('웹에서는 동영상 분석을 지원하지 않습니다. 모바일 앱을 이용해주세요.');
    }

    final frames = <String>[];

    // Get video duration (approximate based on file size for now)
    // In a real app, you'd use video_player to get actual duration
    final fileSizeInMb = videoFile.lengthSync() / (1024 * 1024);
    final estimatedDuration = fileSizeInMb * 10; // rough estimate: 10 sec per MB

    // Determine frame count based on estimated duration
    final targetFrames = frameCountFor(estimatedDuration);
    final actualFrameCount = frameCount > 0 ? frameCount : targetFrames;

    // Calculate time positions for each frame
    final positions = <int>[];
    final intervalMs = (estimatedDuration * 1000 / (actualFrameCount + 1)).round();

    for (int i = 1; i <= actualFrameCount; i++) {
      positions.add(intervalMs * i);
    }

    // Extract frames at each position
    for (int i = 0; i < positions.length; i++) {
      try {
        final uint8list = await vt.VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: vt.ImageFormat.JPEG,
          maxWidth: maxEdge,
          quality: jpegQuality,
          timeMs: positions[i],
        );

        if (uint8list != null) {
          frames.add(base64Encode(uint8list));
        }
      } catch (e) {
        // Skip frames that fail to extract
      }
      onProgress?.call(i + 1, positions.length);
    }

    if (frames.isEmpty) {
      // Try to get at least one frame (thumbnail)
      final thumbnail = await vt.VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: maxEdge,
        quality: jpegQuality,
      );
      if (thumbnail != null) {
        frames.add(base64Encode(thumbnail));
      }
    }

    if (frames.isEmpty) {
      throw Exception('동영상에서 프레임을 추출할 수 없습니다');
    }

    return ExtractResult(
      frames: frames,
      thumbnail: frames[0],
      durationSeconds: estimatedDuration,
      frameCount: frames.length,
    );
  }

  /// Get video thumbnail
  Future<Uint8List?> getVideoThumbnail(String videoPath) async {
    if (kIsWeb) {
      return null;
    }
    return await vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: maxEdge,
      quality: jpegQuality,
    );
  }

  /// Check if a file is a video
  static bool isVideo(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext);
  }

  /// Check if a file is an image
  static bool isImage(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].contains(ext);
  }

  /// Convert Uint8List to base64 string
  static String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Resize image bytes to fit within maxEdge while maintaining aspect ratio
  Future<Uint8List> resizeImage(
    Uint8List bytes, {
    int maxWidth = maxEdge,
  }) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    if (image.width <= maxWidth) {
      return bytes;
    }

    final scale = maxWidth / image.width;
    final targetWidth = maxWidth;
    final targetHeight = (image.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);

    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to resize image');
    }

    return byteData.buffer.asUint8List();
  }
}
