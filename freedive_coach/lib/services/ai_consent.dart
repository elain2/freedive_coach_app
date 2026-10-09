import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAiConsentKey = 'ai_data_consent_v1';

class AiConsentException implements Exception {
  @override
  String toString() => 'AI 기능을 사용하려면 데이터 전송 동의가 필요합니다. 설정에서 동의해 주세요.';
}

Future<bool> hasAiConsent() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kAiConsentKey) ?? false;
}

Future<void> setAiConsent(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kAiConsentKey, value);
}

/// 외부 AI(Gemini)로 데이터를 보내기 전에 호출한다.
Future<void> requireAiConsent() async {
  if (!await hasAiConsent()) throw AiConsentException();
}

/// 동의가 없으면 안내 다이얼로그를 띄워 동의를 다시 받는다.
/// 이미 동의했거나 이번에 동의하면 true.
Future<bool> ensureAiConsent(BuildContext context) async {
  if (await hasAiConsent()) return true;
  if (!context.mounted) return false;
  final agreed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('AI 기능 데이터 전송 동의'),
      content: const Text(
        '이 기능은 입력한 영상·음성·텍스트·다이빙 기록을 '
        'Google Gemini API로 전송해 처리합니다. 동의하시겠습니까?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('동의'),
        ),
      ],
    ),
  );
  if (agreed != true) return false;
  await setAiConsent(true);
  return true;
}
