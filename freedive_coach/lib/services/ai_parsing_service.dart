import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/discipline.dart';

/// Parsed result from AI
class AIParsedLog {
  final DateTime? date;
  final String? location;
  final Discipline? discipline;
  final double? depth;
  final double? distance;
  final Duration? duration;
  final double? mouthfillDepth;
  final double? freefallDepth;
  final double? weight;
  final String? condition;
  final String? notes;
  final double confidence;

  const AIParsedLog({
    this.date,
    this.location,
    this.discipline,
    this.depth,
    this.distance,
    this.duration,
    this.mouthfillDepth,
    this.freefallDepth,
    this.weight,
    this.condition,
    this.notes,
    this.confidence = 0.0,
  });

  bool get hasAnyData =>
      date != null ||
      location != null ||
      discipline != null ||
      depth != null ||
      distance != null ||
      duration != null ||
      mouthfillDepth != null ||
      freefallDepth != null ||
      weight != null ||
      condition != null ||
      notes != null;
}

/// Service for AI-powered log parsing using Gemini
class AIParsingService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.0-flash';

  String? _apiKey;

  AIParsingService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'];
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Parse natural language input into structured dive log fields
  Future<AIParsedLog> parseLogInput(String input) async {
    if (!isConfigured) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    if (input.trim().isEmpty) {
      return const AIParsedLog();
    }

    final prompt = _buildPrompt(input);

    try {
      final response = await _callGemini(prompt);
      return _parseResponse(response);
    } catch (e) {
      // Fallback to empty result on error
      return const AIParsedLog();
    }
  }

  String _buildPrompt(String input) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return '''
다이빙 로그 텍스트를 JSON으로 변환해주세요.

입력: "$input"

오늘 날짜: $todayStr

다음 JSON 형식으로 응답해주세요 (해당하는 필드만 포함):
{
  "date": "YYYY-MM-DD",
  "location": "장소명",
  "discipline": "CWT|CNF|FIM|DYN|DNF|STA",
  "depth": 숫자(미터),
  "distance": 숫자(미터, DYN/DNF용),
  "duration_minutes": 숫자,
  "duration_seconds": 숫자,
  "mouthfill_depth": 숫자(미터),
  "freefall_depth": 숫자(미터),
  "weight": 숫자(kg),
  "condition": "컨디션 관련 메모",
  "notes": "기타 메모",
  "confidence": 0.0~1.0
}

규칙:
- "오늘"은 $todayStr
- "어제"는 하루 전
- 수심은 "m", "미터" 등에서 추출
- 종목: CWT(콘스탄트웨이트), CNF(노핀), FIM(프리이머전), DYN(다이나믹), DNF(다이나믹노핀), STA(스태틱)
- 마우스필/프리폴 수심 구분
- 귀 아픔, 컨트랙션 등은 condition에
- JSON만 응답하세요
''';
  }

  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1000,
      }
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    return text;
  }

  AIParsedLog _parseResponse(String response) {
    // Extract JSON from response
    String jsonStr = response.trim();

    // Remove markdown code blocks if present
    if (jsonStr.contains('```json')) {
      jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
    } else if (jsonStr.contains('```')) {
      jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      DateTime? date;
      if (data['date'] != null) {
        try {
          date = DateTime.parse(data['date']);
        } catch (_) {}
      }

      Discipline? discipline;
      if (data['discipline'] != null) {
        final discStr = data['discipline'].toString().toLowerCase();
        discipline = Discipline.values.cast<Discipline?>().firstWhere(
          (d) => d?.name.toLowerCase() == discStr,
          orElse: () => null,
        );
      }

      Duration? duration;
      final minutes = data['duration_minutes'] as int?;
      final seconds = data['duration_seconds'] as int?;
      if (minutes != null || seconds != null) {
        duration = Duration(
          minutes: minutes ?? 0,
          seconds: seconds ?? 0,
        );
      }

      return AIParsedLog(
        date: date,
        location: data['location'] as String?,
        discipline: discipline,
        depth: _toDouble(data['depth']),
        distance: _toDouble(data['distance']),
        duration: duration,
        mouthfillDepth: _toDouble(data['mouthfill_depth']),
        freefallDepth: _toDouble(data['freefall_depth']),
        weight: _toDouble(data['weight']),
        condition: data['condition'] as String?,
        notes: data['notes'] as String?,
        confidence: _toDouble(data['confidence']) ?? 0.8,
      );
    } catch (e) {
      return const AIParsedLog();
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
