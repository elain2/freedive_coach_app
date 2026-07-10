import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _logStorage = LogStorage();
  List<DiveLog> _allLogs = [];
  bool _isLoading = true;

  // Stats
  int _totalDives = 0;
  double? _maxDepth;
  double? _maxDistance;
  Duration _totalDuration = Duration.zero;
  Map<Discipline, int> _disciplineCounts = {};
  List<_DepthDataPoint> _depthProgress = [];
  Map<int, int> _monthlyDives = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _logStorage.getLogs();
      _calculateStats(logs);

      setState(() {
        _allLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<DiveLog> logs) {
    _totalDives = logs.length;
    _disciplineCounts = {};
    _depthProgress = [];
    _monthlyDives = {};
    _totalDuration = Duration.zero;
    _maxDepth = null;
    _maxDistance = null;

    // Sort logs by date for progress chart
    final sortedLogs = List<DiveLog>.from(logs)
      ..sort((a, b) => a.diveDate.compareTo(b.diveDate));

    for (final log in sortedLogs) {
      // Discipline counts
      _disciplineCounts[log.discipline] =
          (_disciplineCounts[log.discipline] ?? 0) + 1;

      // Max depth
      if (log.depth != null) {
        if (_maxDepth == null || log.depth! > _maxDepth!) {
          _maxDepth = log.depth;
        }
        _depthProgress.add(_DepthDataPoint(
          date: log.diveDate,
          depth: log.depth!,
        ));
      }

      // Max distance
      if (log.distance != null) {
        if (_maxDistance == null || log.distance! > _maxDistance!) {
          _maxDistance = log.distance;
        }
      }

      // Total duration
      if (log.duration != null) {
        _totalDuration += log.duration!;
      }

      // Monthly dives
      final monthKey = log.diveDate.year * 12 + log.diveDate.month;
      _monthlyDives[monthKey] = (_monthlyDives[monthKey] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _allLogs.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadStats,
                          color: AppColors.primary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCards(),
                                const SizedBox(height: 24),
                                if (_depthProgress.isNotEmpty) ...[
                                  _buildDepthProgressChart(),
                                  const SizedBox(height: 24),
                                ],
                                _buildDisciplineChart(),
                                const SizedBox(height: 24),
                                _buildMonthlyChart(),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          Text('통계', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            '아직 데이터가 없어요',
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '다이빙 로그를 작성하면 통계를 볼 수 있어요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('전체 기록', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.water,
                label: '총 다이빙',
                value: '$_totalDives',
                unit: '회',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.arrow_downward,
                label: '최고 수심',
                value: _maxDepth?.toStringAsFixed(0) ?? '-',
                unit: 'm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.straighten,
                label: '최장 거리',
                value: _maxDistance?.toStringAsFixed(0) ?? '-',
                unit: 'm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.timer,
                label: '총 시간',
                value: _formatTotalDuration(_totalDuration),
                unit: '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTotalDuration(Duration duration) {
    if (duration.inMinutes == 0) return '-';
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Widget _buildDepthProgressChart() {
    if (_depthProgress.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = _depthProgress.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.depth);
    }).toList();

    final maxY = (_maxDepth ?? 30) + 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수심 성장 그래프', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.line,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (_depthProgress.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _depthProgress.length) {
                          return const SizedBox.shrink();
                        }
                        final date = _depthProgress[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_depthProgress.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.bg,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= _depthProgress.length) {
                          return null;
                        }
                        final data = _depthProgress[index];
                        return LineTooltipItem(
                          '${data.depth.toStringAsFixed(0)}m\n${data.date.month}/${data.date.day}',
                          AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisciplineChart() {
    if (_disciplineCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = _disciplineCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.primary,
      AppColors.tealDim,
      AppColors.amber,
      AppColors.coral,
      AppColors.mint,
      AppColors.primaryBright,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('종목별 분포', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: sortedEntries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final discipline = entry.value.key;
                      final count = entry.value.value;
                      final percentage = count / _totalDives * 100;

                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: count.toDouble(),
                        title: '',
                        radius: 25,
                        badgeWidget: percentage > 15
                            ? Text(
                                discipline.displayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 0.5,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final discipline = entry.value.key;
                    final count = entry.value.value;
                    final percentage = (count / _totalDives * 100).toStringAsFixed(0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            discipline.displayName,
                            style: AppTextStyles.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '$count회 ($percentage%)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyDives.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get last 6 months
    final now = DateTime.now();
    final months = <int>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add(date.year * 12 + date.month);
    }

    final maxCount = _monthlyDives.values.fold(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('월별 다이빙', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 2).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthKey = months[group.x.toInt()];
                      final count = _monthlyDives[monthKey] ?? 0;
                      return BarTooltipItem(
                        '$count회',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final monthKey = months[index];
                        final month = monthKey % 12;
                        final displayMonth = month == 0 ? 12 : month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$displayMonth월',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: months.asMap().entries.map((entry) {
                  final index = entry.key;
                  final monthKey = entry.value;
                  final count = _monthlyDives[monthKey] ?? 0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: count > 0 ? AppColors.primary : AppColors.surface2,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DepthDataPoint {
  final DateTime date;
  final double depth;

  _DepthDataPoint({required this.date, required this.depth});
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  fontSize: 24,
                  color: AppColors.primaryBright,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
