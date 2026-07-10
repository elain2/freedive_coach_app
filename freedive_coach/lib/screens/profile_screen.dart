import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';
import 'debug_screen.dart';
import 'stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _logStorage = LogStorage();
  int _totalDives = 0;
  double? _maxDepth;
  Duration? _maxDuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final logs = await _logStorage.getLogs();
      double? maxDepth;
      Duration? maxDuration;

      for (final log in logs) {
        if (log.depth != null) {
          if (maxDepth == null || log.depth! > maxDepth) {
            maxDepth = log.depth;
          }
        }
        if (log.duration != null) {
          if (maxDuration == null || log.duration! > maxDuration) {
            maxDuration = log.duration;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalDives = logs.length;
          _maxDepth = maxDepth;
          _maxDuration = maxDuration;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '-';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 20),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('마이', style: AppTextStyles.titleLarge),
        GestureDetector(
          onTap: () {
            // TODO: Settings screen
          },
          child: const Icon(Icons.settings, size: 22, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      borderColor: Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('\u{1F431}', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('다이버님', style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '프리다이빙을 즐기는 중',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'AIDA 2',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        );
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        borderColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('나의 기록', style: AppTextStyles.sectionTitle),
                Row(
                  children: [
                    Text(
                      '전체 통계',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '총 다이빙',
                      '$_totalDives',
                      '회',
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.line),
                  Expanded(
                    child: _buildStatItem(
                      '최고 수심',
                      _maxDepth?.toStringAsFixed(0) ?? '-',
                      'm',
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.line),
                  Expanded(
                    child: _buildStatItem(
                      '최장 시간',
                      _formatDuration(_maxDuration),
                      '',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                fontSize: 22,
                color: AppColors.primaryBright,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: AppTextStyles.caption),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(Icons.track_changes, '나의 목표', '설정하기', onTap: () {
          // TODO: Goals screen
        }),
        _buildMenuItem(Icons.bar_chart, '상세 통계', '', onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          );
        }),
        _buildMenuItem(Icons.history, '훈련 기록', '', onTap: () {
          // TODO: Training history
        }),
        _buildMenuItem(Icons.notifications_outlined, '알림 설정', '', onTap: () {
          // TODO: Notification settings
        }),
        _buildMenuItem(Icons.help_outline, '도움말', '', onTap: () {
          // TODO: Help screen
        }),
        if (kDebugMode)
          _buildMenuItem(
            Icons.bug_report,
            '디버그 메뉴',
            'DEV',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              );
            },
            isDanger: true,
          ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDanger ? AppColors.coral : AppColors.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: isDanger ? AppColors.coral : null,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Container(
                padding: isDanger
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : EdgeInsets.zero,
                decoration: isDanger
                    ? BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  value,
                  style: AppTextStyles.caption.copyWith(
                    color: isDanger ? AppColors.coral : null,
                    fontWeight: isDanger ? FontWeight.w600 : null,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDanger ? AppColors.coral : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
