import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for handling speech-to-text functionality
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Initialize the speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
    );

    return _isInitialized;
  }

  /// Start listening for speech input
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function()? onListeningStarted,
    void Function()? onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    _isListening = true;
    onListeningStarted?.call();

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onListeningStopped?.call();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'ko_KR',
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    _isListening = false;
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;
    await _speechToText.cancel();
    _isListening = false;
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Dispose resources
  void dispose() {
    _speechToText.stop();
    _isListening = false;
  }
}
