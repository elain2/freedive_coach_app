import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/training_session.dart';
import '../services/training_storage.dart';
import '../widgets/surface_card.dart';

class BreathingCompleteScreen extends StatefulWidget {
  final TrainingSession session;

  const BreathingCompleteScreen({
    super.key,
    required this.session,
  });

  @override
  State<BreathingCompleteScreen> createState() => _BreathingCompleteScreenState();
}

class _BreathingCompleteScreenState extends State<BreathingCompleteScreen> {
  final TrainingStorage _storage = TrainingStorage();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    await _storage.saveSession(widget.session);
    if (mounted) {
      setState(() => _isSaved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealDim,
                ),
                child: const Icon(
                  Icons.check,
                  size: 50,
                  color: AppColors.primaryBright,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                '훈련 완료!',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '잘하셨어요 \u{1F431}',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              // Summary card
              _buildSummaryCard(),
              const Spacer(flex: 2),
              // Buttons
              _buildButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final session = widget.session;
    final duration = session.duration;

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      borderColor: Colors.transparent,
      child: Column(
        children: [
          // Table type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              session.tableTypeName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '라운드',
                  '${session.completedRounds}/${session.totalRounds}',
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.line),
              Expanded(
                child: _buildStatItem(
                  'PB',
                  session.personalBestFormatted,
                ),
              ),
              if (duration != null) ...[
                Container(width: 1, height: 40, color: AppColors.line),
                Expanded(
                  child: _buildStatItem(
                    '소요 시간',
                    _formatDuration(duration),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Save status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSaved ? Icons.check_circle : Icons.hourglass_empty,
                size: 16,
                color: _isSaved ? AppColors.primaryBright : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                _isSaved ? '기록 저장됨' : '저장 중...',
                style: AppTextStyles.caption.copyWith(
                  color: _isSaved ? AppColors.primaryBright : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontSize: 20,
            color: AppColors.primaryBright,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Done button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Pop back to training screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBright,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '완료',
              style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Train again button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Pop to setup screen (2 screens back)
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.line),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '다시 훈련하기',
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}
