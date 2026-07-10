import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFAQSection(),
                    const SizedBox(height: 24),
                    _buildGuideSection(context),
                    const SizedBox(height: 24),
                    _buildContactSection(context),
                  ],
                ),
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
          Text('도움말', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      FAQItem(
        question: '다이빙 로그는 어떻게 기록하나요?',
        answer: '홈 화면에서 "새 로그" 버튼을 누르거나 하단 탭의 로그 화면에서 + 버튼을 눌러 새 로그를 작성할 수 있습니다. 음성으로 입력하면 AI가 자동으로 수심, 시간 등을 파싱해줍니다.',
      ),
      FAQItem(
        question: 'AI 폼 분석은 어떻게 사용하나요?',
        answer: '홈 화면에서 "영상 분석"을 누르고 다이빙 영상을 선택하세요. 종목과 분석 모드를 선택한 후 분석을 시작하면 AI가 폼을 분석해 점수와 개선 팁을 알려줍니다.',
      ),
      FAQItem(
        question: 'CO2/O2 테이블 훈련이 무엇인가요?',
        answer: 'CO2 테이블은 이산화탄소 내성을 키우는 훈련으로 휴식 시간이 점점 줄어듭니다. O2 테이블은 저산소 내성을 키우는 훈련으로 숨 참기 시간이 점점 늘어납니다.',
      ),
      FAQItem(
        question: '시뮬레이션 다이브는 무엇인가요?',
        answer: '실제 다이빙과 같은 시간으로 멘탈 훈련을 할 수 있습니다. 목표 수심과 하강/상승 속도를 설정하면 타이머가 실제 다이빙처럼 진행됩니다.',
      ),
      FAQItem(
        question: '데이터는 어디에 저장되나요?',
        answer: '모든 데이터는 기기 내부에 안전하게 저장됩니다. 앱을 삭제하면 데이터도 함께 삭제되니 중요한 데이터는 내보내기 기능을 이용해 백업해주세요.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('자주 묻는 질문', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        ...faqs.map((faq) => _buildFAQCard(faq)),
      ],
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _FAQCard(faq: faq),
    );
  }

  Widget _buildGuideSection(BuildContext context) {
    final guides = [
      GuideItem(
        icon: Icons.mic,
        title: '음성으로 로그 기록하기',
        description: '마이크 버튼을 누르고 자연스럽게 말하세요',
      ),
      GuideItem(
        icon: Icons.videocam,
        title: 'AI 폼 분석 활용법',
        description: '영상 촬영 팁과 분석 결과 해석법',
      ),
      GuideItem(
        icon: Icons.air,
        title: '효과적인 호흡 훈련',
        description: 'CO2/O2 테이블 훈련 가이드',
      ),
      GuideItem(
        icon: Icons.flag,
        title: '목표 설정 가이드',
        description: '달성 가능한 목표 세우는 법',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사용 가이드', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        ...guides.map((guide) => _buildGuideCard(context, guide)),
      ],
    );
  }

  Widget _buildGuideCard(BuildContext context, GuideItem guide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${guide.title} 가이드는 준비 중입니다')),
          );
        },
        child: SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tealDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(guide.icon, size: 20, color: AppColors.primaryBright),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide.title, style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(
                      guide.description,
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('문의하기', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildContactItem(
                context,
                Icons.email_outlined,
                '이메일 문의',
                'support@divingcat.app',
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildContactItem(
                context,
                Icons.chat_bubble_outline,
                '카카오톡 문의',
                '@FreediveCoach',
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildContactItem(
                context,
                Icons.language,
                '공식 웹사이트',
                'www.divingcat.app',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '평일 10:00 - 18:00 (주말/공휴일 제외)',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String title, String value) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $value')),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: AppTextStyles.body),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBright),
          ),
        ],
      ),
    );
  }
}

class _FAQCard extends StatefulWidget {
  final FAQItem faq;

  const _FAQCard({required this.faq});

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: AppTextStyles.body,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                widget.faq.answer,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class GuideItem {
  final IconData icon;
  final String title;
  final String description;

  const GuideItem({required this.icon, required this.title, required this.description});
}
