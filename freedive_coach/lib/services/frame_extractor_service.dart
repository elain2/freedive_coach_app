import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

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
