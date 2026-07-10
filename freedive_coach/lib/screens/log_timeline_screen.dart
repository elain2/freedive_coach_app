import 'package:flutter/material.dart';
import '../models/dive_log.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/log_entry_card.dart';
import 'log_detail_screen.dart';
import 'new_log_screen.dart';

class LogTimelineScreen extends StatefulWidget {
  const LogTimelineScreen({super.key});

  @override
  State<LogTimelineScreen> createState() => _LogTimelineScreenState();
}

class _LogTimelineScreenState extends State<LogTimelineScreen> {
  final _logStorage = LogStorage();
  List<DiveLog> _logs = [];
  MonthlyStats? _monthlyStats;
  bool _isLoading = true;

  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _logStorage.getLogsByMonth(_selectedYear, _selectedMonth);
      final stats = await _logStorage.getMonthlyStats(_selectedYear, _selectedMonth);

      setState(() {
        _logs = logs;
        _monthlyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _loadLogs();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return; // Can't go to future
    }

    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _loadLogs();
  }

  Future<void> _openNewLog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewLogScreen()),
    );
    if (result == true) {
      _loadLogs();
    }
  }

  Future<void> _openLogDetail(DiveLog log) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
    );
    if (result == true) {
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadLogs,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMonthSelector(),
                const SizedBox(height: 16),
                if (_isLoading)
                  _buildLoading()
                else if (_logs.isEmpty)
                  _buildEmptyState()
                else
                  _buildTimeline(),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: _buildFab(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('로그', style: AppTextStyles.titleMedium),
        Row(
          children: [
            _buildIconButton(Icons.bar_chart, onTap: () {
              // TODO: Show stats
            }),
            const SizedBox(width: 10),
            _buildIconButton(Icons.tune, onTap: () {
              // TODO: Show filters
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 16, color: AppColors.muted),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedYear == now.year && _selectedMonth == now.month;

    return Row(
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.chevron_left, size: 16, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_selectedMonth월',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_monthlyStats != null) ...[
                  Text(' · ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                  Text(
                    '다이빙 ${_monthlyStats!.diveCount}회',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                  ),
                  if (_monthlyStats!.maxDepth != null) ...[
                    Text(' · ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                    Text('최고 ${_monthlyStats!.maxDepthFormatted}', style: AppTextStyles.monoSmall),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isCurrentMonth ? null : _nextMonth,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: isCurrentMonth ? AppColors.muted.withOpacity(0.3) : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.water,
                size: 32,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_selectedMonth월 기록이 없어요',
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '아래 버튼을 눌러 새 로그를 작성해보세요',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        for (int i = 0; i < _logs.length; i++) ...[
          LogEntryCard(
            log: _logs[i],
            isFirst: i == 0,
            onTap: () => _openLogDetail(_logs[i]),
          ),
          if (i < _logs.length - 1) const LogRopeGap(),
        ],
      ],
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _openNewLog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '새 로그',
              style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
