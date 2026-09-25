import 'package:flutter/material.dart';
import '../models/training_session.dart';
import '../theme/app_theme.dart';
import '../models/breathing_table.dart';
import '../services/training_storage.dart';
import '../widgets/surface_card.dart';
import 'breathing_setup_screen.dart';
import 'simulation_setup_screen.dart';
import 'training_history_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _trainingStorage = TrainingStorage();
  List<TrainingSession> _recentSessions = [];
  int _weekTrainingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _trainingStorage.getRecentSessions(count: 3);

    // Calculate week training count
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final allSessions = await _trainingStorage.getSessions();
    final weekSessions = allSessions.where((t) =>
        t.startedAt.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();

    if (mounted) {
      setState(() {
        _recentSessions = sessions;
        _weekTrainingCount = weekSessions.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStreakBanner(),
          const SizedBox(height: 20),
          _buildBreathSection(context),
          const SizedBox(height: 20),
          _buildSimulationSection(context),
          const SizedBox(height: 20),
          _buildHistorySection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('트레이닝', style: AppTextStyles.titleLarge),
        const SizedBox(height: 2),
        Text(
          '물 밖에서도 다이빙은 계속돼요 \u{1F431}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    // 실제 훈련 횟수가 없으면 표시하지 않음
    if (_weekTrainingCount == 0) {
      return const SizedBox.shrink();
    }

    final displayText = '이번 주 $_weekTrainingCount회 훈련';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: AppColors.primaryBright),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('호흡 훈련', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildBreathCard(context, 'CO\u2082 테이블', '8라운드', '12:00', Icons.monitor_heart_outlined, TableType.co2)),
            const SizedBox(width: 10),
            Expanded(child: _buildBreathCard(context, 'O\u2082 테이블', '8라운드', '10:30', Icons.favorite_outline, TableType.o2)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreathCard(BuildContext context, String title, String rounds, String duration, IconData icon, TableType tableType) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BreathingSetupScreen(initialType: tableType),
          ),
        );
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        borderColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBright),
            const SizedBox(height: 6),
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text('$rounds · $duration', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('다이빙 시뮬레이션', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SimulationSetupScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.standard),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14405F), Color(0xFF0A2438)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('멘탈 다이브', style: AppTextStyles.sectionTitle),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '타이밍 리허설',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '목표 수심, 속도, 마일스톤을 설정하고\n실제 다이브 전 타이밍을 연습하세요',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '시작',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.text)),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final hasRealData = _recentSessions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('훈련 기록', style: AppTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrainingHistoryScreen()),
                );
              },
              child: Text(
                '전체 보기',
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hasRealData)
          _buildRealHistoryList()
        else
          _buildEmptyHistoryState(),
      ],
    );
  }

  Widget _buildRealHistoryList() {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: Colors.transparent,
      child: Column(
        children: [
          for (int i = 0; i < _recentSessions.length; i++) ...[
            if (i > 0) _buildHistoryDivider(),
            _buildHistoryItem(
              _recentSessions[i].tableTypeName,
              '${_recentSessions[i].completedRounds}/${_recentSessions[i].totalRounds} 라운드 ${_recentSessions[i].isCompleted ? '완료' : '중단'}',
              _formatRelativeTime(_recentSessions[i].startedAt),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      borderColor: Colors.transparent,
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 36,
            color: AppColors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            '아직 훈련 기록이 없어요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '호흡 훈련을 시작해보세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      final hour = date.hour;
      return hour < 12 ? '오늘 오전' : '오늘 오후';
    } else if (sessionDate == yesterday) {
      return '어제';
    } else {
      final diff = today.difference(sessionDate).inDays;
      if (diff < 7) {
        return '$diff일 전';
      }
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildHistoryItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.primaryBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildHistoryDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 14),
      child: Container(height: 1, color: AppColors.line),
    );
  }
}
