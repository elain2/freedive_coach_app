import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum LegalType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalType type;

  const LegalScreen({super.key, required this.type});

  String get title => type == LegalType.privacy ? '개인정보 처리방침' : '이용약관';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: type == LegalType.privacy
                    ? _buildPrivacyPolicy()
                    : _buildTermsOfService(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.muted),
            ),
          ),
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('1. 수집하는 개인정보', '''
Freedive Coach 앱은 서비스 제공을 위해 다음 정보를 수집합니다:

• 다이빙 로그 데이터 (수심, 시간, 장소 등)
• 훈련 기록 데이터
• 폼 분석을 위한 영상 데이터
• 앱 사용 기록

모든 데이터는 사용자의 기기에 로컬로 저장되며, 사용자의 동의 없이 외부 서버로 전송되지 않습니다.
'''),
        _buildSection('2. 개인정보의 이용 목적', '''
수집된 정보는 다음 목적으로 이용됩니다:

• 다이빙 기록 관리 및 통계 제공
• AI 폼 분석 서비스 제공
• 훈련 진행 상황 추적
• 서비스 개선 및 새로운 기능 개발
'''),
        _buildSection('3. 개인정보의 보관 및 파기', '''
• 개인정보는 사용자의 기기에 저장됩니다
• 앱 삭제 시 모든 데이터가 함께 삭제됩니다
• 설정에서 직접 데이터를 삭제할 수 있습니다
'''),
        _buildSection('4. 개인정보의 제3자 제공', '''
Freedive Coach는 사용자의 동의 없이 개인정보를 제3자에게 제공하지 않습니다.

단, 다음의 경우는 예외로 합니다:
• 법령에 의해 요구되는 경우
• 서비스 제공을 위해 필요한 경우 (AI 분석 등)
'''),
        _buildSection('5. 이용자의 권리', '''
이용자는 다음 권리를 가집니다:

• 개인정보 열람 요청
• 개인정보 정정 요청
• 개인정보 삭제 요청
• 처리 정지 요청

권리 행사는 앱 내 설정 또는 고객센터를 통해 가능합니다.
'''),
        _buildSection('6. 연락처', '''
개인정보 관련 문의:
• 이메일: privacy@divingcat.app
• 고객센터: 평일 10:00 - 18:00
'''),
        const SizedBox(height: 20),
        Text(
          '최종 수정일: 2024년 1월 1일',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildTermsOfService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('1. 서비스 개요', '''
Freedive Coach는 프리다이빙 훈련 및 기록 관리를 위한 앱 서비스입니다.

본 서비스는 다음 기능을 제공합니다:
• 다이빙 로그 기록 및 관리
• AI 기반 폼 분석
• 호흡 훈련 (CO2/O2 테이블)
• 시뮬레이션 다이브
• 통계 및 목표 관리
'''),
        _buildSection('2. 이용자의 의무', '''
이용자는 다음 사항을 준수해야 합니다:

• 타인의 정보를 도용하지 않습니다
• 서비스를 불법적인 목적으로 이용하지 않습니다
• 서비스의 정상적인 운영을 방해하지 않습니다
• 관련 법령을 준수합니다
'''),
        _buildSection('3. 서비스 이용 제한', '''
다음의 경우 서비스 이용이 제한될 수 있습니다:

• 본 약관을 위반한 경우
• 불법적인 행위가 확인된 경우
• 서비스 운영을 방해한 경우
'''),
        _buildSection('4. 면책 조항', '''
Freedive Coach는 다음 사항에 대해 책임지지 않습니다:

• 사용자의 귀책 사유로 인한 서비스 장애
• 천재지변 등 불가항력으로 인한 서비스 중단
• 사용자가 서비스를 통해 얻은 정보의 정확성
• 앱에서 제공하는 정보를 바탕으로 한 실제 다이빙 중 발생하는 사고

주의: 본 앱은 훈련 보조 도구이며, 실제 다이빙 시에는 반드시 공인된 교육 기관의 지침을 따르고 안전 수칙을 준수하세요.
'''),
        _buildSection('5. 저작권', '''
Freedive Coach 앱의 모든 콘텐츠에 대한 저작권은 Freedive Coach에 있습니다.

• 앱 디자인 및 UI
• 로고 및 브랜드 자산
• 훈련 프로그램 및 가이드
• AI 분석 알고리즘
'''),
        _buildSection('6. 약관의 변경', '''
본 약관은 필요 시 변경될 수 있으며, 변경 시 앱 내 공지를 통해 안내드립니다.

변경된 약관은 공지 후 7일 후부터 효력이 발생합니다.
'''),
        _buildSection('7. 문의', '''
서비스 이용 관련 문의:
• 이메일: support@divingcat.app
• 고객센터: 평일 10:00 - 18:00
'''),
        const SizedBox(height: 20),
        Text(
          '최종 수정일: 2024년 1월 1일',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 10),
          Text(
            content.trim(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
