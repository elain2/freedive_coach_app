import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedive_coach/services/frame_extractor_service.dart';

void main() {
  group('FrameExtractorService', () {
    group('frameCountFor', () {
      test('returns 5 for <= 30 seconds', () {
        expect(FrameExtractorService.frameCountFor(10), 5);
        expect(FrameExtractorService.frameCountFor(30), 5);
      });

      test('returns 8 for <= 60 seconds', () {
        expect(FrameExtractorService.frameCountFor(31), 8);
        expect(FrameExtractorService.frameCountFor(60), 8);
      });

      test('returns 10 for <= 120 seconds', () {
        expect(FrameExtractorService.frameCountFor(61), 10);
        expect(FrameExtractorService.frameCountFor(120), 10);
      });

      test('returns 12 for > 120 seconds', () {
        expect(FrameExtractorService.frameCountFor(121), 12);
        expect(FrameExtractorService.frameCountFor(300), 12);
      });
    });

    group('isVideo', () {
      test('returns true for video extensions', () {
        expect(FrameExtractorService.isVideo('video.mp4'), isTrue);
        expect(FrameExtractorService.isVideo('video.MOV'), isTrue);
        expect(FrameExtractorService.isVideo('video.avi'), isTrue);
        expect(FrameExtractorService.isVideo('video.mkv'), isTrue);
        expect(FrameExtractorService.isVideo('video.webm'), isTrue);
      });

      test('returns false for non-video extensions', () {
        expect(FrameExtractorService.isVideo('image.jpg'), isFalse);
        expect(FrameExtractorService.isVideo('image.png'), isFalse);
        expect(FrameExtractorService.isVideo('document.pdf'), isFalse);
      });
    });

    group('isImage', () {
      test('returns true for image extensions', () {
        expect(FrameExtractorService.isImage('photo.jpg'), isTrue);
        expect(FrameExtractorService.isImage('photo.JPEG'), isTrue);
        expect(FrameExtractorService.isImage('photo.png'), isTrue);
        expect(FrameExtractorService.isImage('photo.gif'), isTrue);
        expect(FrameExtractorService.isImage('photo.webp'), isTrue);
        expect(FrameExtractorService.isImage('photo.heic'), isTrue);
      });

      test('returns false for non-image extensions', () {
        expect(FrameExtractorService.isImage('video.mp4'), isFalse);
        expect(FrameExtractorService.isImage('document.pdf'), isFalse);
      });
    });

    group('bytesToBase64', () {
      test('converts bytes to base64 string', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
        final base64 = FrameExtractorService.bytesToBase64(bytes);
        expect(base64, 'SGVsbG8=');
      });

      test('handles empty bytes', () {
        final bytes = Uint8List.fromList([]);
        final base64 = FrameExtractorService.bytesToBase64(bytes);
        expect(base64, '');
      });
    });

    group('ExtractResult', () {
      test('constructor creates instance with all fields', () {
        final result = ExtractResult(
          frames: ['frame1', 'frame2', 'frame3'],
          thumbnail: 'frame2',
          durationSeconds: 45.0,
          frameCount: 3,
        );

        expect(result.frames.length, 3);
        expect(result.thumbnail, 'frame2');
        expect(result.durationSeconds, 45.0);
        expect(result.frameCount, 3);
      });
    });
  });
}
