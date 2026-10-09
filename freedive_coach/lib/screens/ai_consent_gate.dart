import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_consent.dart';
import '../theme/app_theme.dart';

/// 최초 실행 시 AI(Gemini) 데이터 전송 동의를 받은 뒤 [child]를 보여준다.
class AiConsentGate extends StatefulWidget {
  final Widget child;
  const AiConsentGate({super.key, required this.child});

  @override
  State<AiConsentGate> createState() => _AiConsentGateState();
}

class _AiConsentGateState extends State<AiConsentGate> {
  bool _loading = true;
  bool? _consented;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _consented = prefs.getBool(kAiConsentKey);
      _loading = false;
    });
  }

  Future<void> _answer(bool agreed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAiConsentKey, agreed);
    if (!mounted) return;
    setState(() => _consented = agreed);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.bg);
    }
    if (_consented != null) return widget.child;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'AI 기능 데이터 전송 동의',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Freedive Coach의 AI 기능(음성 로그 정리, 폼 분석, 코칭)을 사용하면 다음 데이터가 AI 처리를 위해 제3자 서비스인 Google Gemini API로 전송됩니다.\n\n'
                    '• 음성 입력 및 음성 인식에 사용되는 오디오\n'
                    '• 입력한 텍스트와 다이빙 기록(수심, 시간, 장소 등)\n'
                    '• 폼 분석을 위해 선택한 영상\n\n'
                    '전송된 데이터는 AI 응답을 생성하는 목적으로만 사용되며, 광고나 추적에 사용되지 않습니다. '
                    '동의하지 않아도 앱을 사용할 수 있으나, AI 기능은 제한됩니다. '
                    '동의 여부는 설정 > 개인정보 처리방침에서 확인할 수 있습니다.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 15, height: 1.6),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _answer(true),
                  child: const Text('동의하고 시작'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _answer(false),
                  child: const Text('동의하지 않음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
