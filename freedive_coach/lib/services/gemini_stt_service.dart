import 'dart:convert';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for speech-to-text using Gemini API
class GeminiSttService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.0-flash';

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _apiKey;
  String? _recordingPath;
  bool _isRecording = false;
  bool _isInitialized = false;

  bool get isRecording => _isRecording;

  /// Set the API key for Gemini
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Check if the service is properly configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Initialize the recorder
  Future<bool> _initialize() async {
    if (_isInitialized) return true;

    try {
      await _recorder.openRecorder();
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if recording is available
  Future<bool> checkPermission() async {
    try {
      await _initialize();
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    if (!await _initialize()) return false;

    final appDir = await getApplicationDocumentsDirectory();
    final recordDir = Directory('${appDir.path}/recordings');
    if (!await recordDir.exists()) {
      await recordDir.create(recursive: true);
    }

    _recordingPath = '${recordDir.path}/stt_${DateTime.now().millisecondsSinceEpoch}.aac';

    try {
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
        sampleRate: 16000,
        numChannels: 1,
      );
      _isRecording = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop recording and transcribe using Gemini
  Future<String?> stopAndTranscribe() async {
    if (!_isRecording || _recordingPath == null) return null;

    try {
      await _recorder.stopRecorder();
      _isRecording = false;

      final transcription = await _transcribeAudio(_recordingPath!);

      // Clean up recording file
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }

      return transcription;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording without transcribing
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
    } catch (e) {
      // Ignore errors
    }
    _isRecording = false;

    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Transcribe audio file using Gemini API
  Future<String?> _transcribeAudio(String audioPath) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    final bytes = await file.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final url = '$_baseUrl/$_model:generateContent?key=$_apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/aac',
                  'data': base64Audio,
                }
              },
              {
                'text': '''이 오디오는 한국어 프리다이빙 로그 음성 입력입니다.
음성을 텍스트로 변환해주세요. 다음 규칙을 따르세요:

1. 들리는 그대로 자연스럽게 텍스트로 변환
2. 숫자와 단위는 그대로 유지 (예: "30미터", "2분 30초")
3. 프리다이빙 용어는 정확히 표기 (CWT, CNF, FIM, 마우스필, 프리폴, 컨트랙션 등)
4. 문장 부호 최소화, 자연스러운 말투 유지

텍스트만 출력하고 다른 설명은 하지 마세요.'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    final content = candidates[0]['content'];
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      return null;
    }

    return parts[0]['text'] as String?;
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}
