import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/training_session.dart';
import '../services/training_storage.dart';
import '../widgets/surface_card.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  final TrainingStorage _storage = TrainingStorage();
  List<TrainingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _storage.getSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('훈련 기록', style: AppTextStyles.titleSmall),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBright))
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.muted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 훈련 기록이 없어요',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '호흡 훈련을 완료하면 여기에 기록됩니다',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    // Group sessions by date
    final groupedSessions = <String, List<TrainingSession>>{};
    for (final session in _sessions) {
      final dateKey = _formatDateKey(session.startedAt);
      groupedSessions.putIfAbsent(dateKey, () => []).add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedSessions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedSessions.keys.elementAt(index);
        final sessions = groupedSessions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 20.0 : 0),
              child: Text(
                dateKey,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ),
            ...sessions.map((session) => _buildSessionCard(session)),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        borderColor: Colors.transparent,
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: session.isCompleted
                    ? AppColors.tealDim
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                session.isCompleted ? Icons.check : Icons.close,
                size: 20,
                color: session.isCompleted
                    ? AppColors.primaryBright
                    : AppColors.muted,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tealDim,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.tableTypeName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBright,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PB ${session.personalBestFormatted}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.isCompleted
                        ? '${session.completedRounds}/${session.totalRounds} 라운드 완료'
                        : '${session.completedRounds}/${session.totalRounds} 라운드 (미완료)',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            // Time
            Text(
              _formatTime(session.startedAt),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return '오늘';
    } else if (sessionDate == yesterday) {
      return '어제';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : hour;
    return '$period $displayHour:$minute';
  }
}
