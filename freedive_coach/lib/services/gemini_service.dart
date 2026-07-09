import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../models/discipline.dart';

/// Exception thrown when Gemini API response cannot be parsed
class GeminiParseException implements Exception {
  final String message;
  GeminiParseException(this.message);

  @override
  String toString() => 'GeminiParseException: $message';
}

/// Exception thrown when input validation fails
class GeminiValidationException implements Exception {
  final String message;
  GeminiValidationException(this.message);

  @override
  String toString() => 'GeminiValidationException: $message';
}

/// Exception thrown when Gemini API call fails
class GeminiApiException implements Exception {
  final int statusCode;
  final String message;
  GeminiApiException(this.statusCode, this.message);

  @override
  String toString() => 'GeminiApiException($statusCode): $message';
}

/// Service for calling Gemini AI API for form analysis
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _defaultModel = 'gemini-2.5-flash';
  static const int _maxFrames = 12;
  static const double _temperature = 0.7;

  String? _apiKey;
  String _model = _defaultModel;

  /// Set the API key for Gemini
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Set the model to use (default: gemini-2.5-flash)
  void setModel(String model) {
    _model = model;
  }

  /// Check if the service is properly configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Determine frame count based on video duration
  static int frameCountForDuration(double durationSeconds) {
    if (durationSeconds <= 30) return 5;
    if (durationSeconds <= 60) return 8;
    if (durationSeconds <= 120) return 10;
    return 12;
  }

  /// Validate frames before sending to API
  void validateFrames(List<String> frames) {
    if (frames.isEmpty) {
      throw GeminiValidationException('프레임이 없어요.');
    }
    if (frames.length > _maxFrames) {
      throw GeminiValidationException('프레임은 최대 $_maxFrames장까지예요.');
    }
  }

  /// Build the prompt for form analysis
  String buildPrompt({
    required Discipline discipline,
    required AnalysisMode mode,
  }) {
    final rubric = Rubric.forDiscipline(discipline);
    if (rubric == null) {
      throw GeminiValidationException('아직 지원하지 않는 종목이에요: ${discipline.displayName}');
    }

    final modeLine = mode == AnalysisMode.segment
        ? '이 프레임들은 다이브의 한 구간을 조밀하게 추출한 것이다. 해당 구간의 기술을 집중적으로 평가하라.'
        : '이 프레임들은 한 번의 다이브 전체를 시간순으로 추출한 것이다. 가능하면 구간(하강/프리폴/턴/상승)별 흐름을 짚어라.';

    final categoriesText = rubric.categories
        .map((c) => '- ${c.label}: ${c.criteria}')
        .join('\n');

    final categoryNames = rubric.categoryLabels.join(', ');

    return '''당신은 AIDA 기준에 정통한 프리다이빙 코치입니다. 다이빙 영상에서 추출한 프레임들을 보고 폼을 평가하세요.

종목: ${rubric.label}
${rubric.context}
$modeLine

평가 항목:
$categoriesText

중요:
- 프레임에서 실제로 보이는 것만 근거로 삼으세요
- 영상만으로 판단 불가한 것은 솔직히 언급하세요
- AIDA 강사처럼 건설적인 코칭 톤으로 한국어로 작성하세요

JSON 스키마:
{
  "overall": "2~3문장 총평 (string)",
  "categories": [
    {"name": "카테고리명", "score": 1-5 (0.5단위), "note": "관찰 내용", "tip": "개선 팁"}
  ],
  "hook": "블로그/쇼츠용 한 줄 카피 (string)"
}

categories 배열에는 다음 항목들을 순서대로 포함하세요: $categoryNames''';
  }

  /// Parse the response from Gemini API
  Map<String, dynamic> parseResponse(String text) {
    // Remove markdown code blocks if present
    var cleaned = text.replaceAll(RegExp(r'```json', caseSensitive: false), '');
    cleaned = cleaned.replaceAll('```', '').trim();

    try {
      return json.decode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Try to extract JSON from the text
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        try {
          return json.decode(match.group(0)!) as Map<String, dynamic>;
        } catch (_) {}
      }
      throw GeminiParseException('Model did not return valid JSON.');
    }
  }

  /// Analyze video frames and return analysis result
  Future<AnalysisResult> analyzeFrames({
    required String requestId,
    required Discipline discipline,
    required AnalysisMode mode,
    required List<String> frames, // base64 encoded JPEG images
  }) async {
    if (!isConfigured) {
      throw GeminiValidationException('API 키가 설정되지 않았습니다.');
    }

    validateFrames(frames);

    final prompt = buildPrompt(discipline: discipline, mode: mode);

    // Build multimodal content parts
    final parts = <Map<String, dynamic>>[
      // Add all frames as inline_data
      ...frames.map((frame) => {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': frame,
            }
          }),
      // Add the text prompt
      {'text': prompt},
    ];

    // Call Gemini API
    final response = await _callGemini(parts);

    // Parse response
    Map<String, dynamic> parsed;
    try {
      parsed = parseResponse(response);
    } catch (e) {
      // One retry
      final retryResponse = await _callGemini(parts);
      parsed = parseResponse(retryResponse);
    }

    // Validate response structure
    if (parsed['categories'] == null ||
        (parsed['categories'] as List).isEmpty) {
      throw GeminiParseException('결과 형식이 올바르지 않아요. 다시 시도해 주세요.');
    }

    // Build AnalysisResult
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final categories = (parsed['categories'] as List)
        .map((c) => CategoryResult.fromJson(c as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      id: id,
      requestId: requestId,
      discipline: discipline,
      mode: mode,
      overall: parsed['overall'] as String? ?? '',
      categories: categories,
      hook: parsed['hook'] as String? ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Make the actual API call to Gemini
  Future<String> _callGemini(List<Map<String, dynamic>> parts) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final body = json.encode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': _temperature,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw GeminiApiException(
        response.statusCode,
        response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiParseException('Gemini returned empty response');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final contentParts = content?['parts'] as List?;
    if (contentParts == null || contentParts.isEmpty) {
      throw GeminiParseException('Gemini returned empty response');
    }

    final text = contentParts[0]['text'] as String?;
    if (text == null || text.isEmpty) {
      throw GeminiParseException('Gemini returned empty response');
    }

    return text;
  }
}
