import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/log_entry_card.dart';
import 'log_detail_screen.dart';
import 'new_log_screen.dart';
import 'stats_screen.dart';

class LogTimelineScreen extends StatefulWidget {
  const LogTimelineScreen({super.key});

  @override
  State<LogTimelineScreen> createState() => _LogTimelineScreenState();
}

class _LogTimelineScreenState extends State<LogTimelineScreen> {
  final _logStorage = LogStorage();
  List<DiveLog> _logs = [];
  List<DiveLog> _filteredLogs = [];
  MonthlyStats? _monthlyStats;
  bool _isLoading = true;
  Discipline? _filterDiscipline;

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
        _applyFilter();
        _monthlyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_filterDiscipline == null) {
      _filteredLogs = _logs;
    } else {
      _filteredLogs = _logs.where((log) => log.discipline == _filterDiscipline).toList();
    }
  }

  void _showStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedDiscipline: _filterDiscipline,
        onDisciplineSelected: (discipline) {
          Navigator.pop(context);
          setState(() {
            _filterDiscipline = discipline;
            _applyFilter();
          });
        },
        onClearFilters: () {
          Navigator.pop(context);
          setState(() {
            _filterDiscipline = null;
            _applyFilter();
          });
        },
      ),
    );
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
                else if (_filteredLogs.isEmpty)
                  _buildEmptyState()
                else
                  _buildTimeline(),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
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
        Row(
          children: [
            Text('로그', style: AppTextStyles.titleMedium),
            if (_filterDiscipline != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterDiscipline!.displayName,
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _filterDiscipline = null;
                          _applyFilter();
                        });
                      },
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.bar_chart, onTap: _showStats),
            const SizedBox(width: 10),
            _buildIconButton(
              Icons.tune,
              onTap: _showFilters,
              isActive: _filterDiscipline != null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColors.tealDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.line),
        ),
        child: Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.muted),
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
              color: isCurrentMonth ? AppColors.muted.withValues(alpha: 0.3) : AppColors.muted,
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
    final isFiltered = _filterDiscipline != null && _logs.isNotEmpty;

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
              child: Icon(
                isFiltered ? Icons.filter_alt_off : Icons.water,
                size: 32,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? '${_filterDiscipline!.displayName} 기록이 없어요'
                  : '$_selectedMonth월 기록이 없어요',
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? '필터를 해제하거나 다른 종목을 선택해보세요'
                  : '아래 버튼을 눌러 새 로그를 작성해보세요',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _filterDiscipline = null;
                    _applyFilter();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tealDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '필터 해제',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        for (int i = 0; i < _filteredLogs.length; i++) ...[
          LogEntryCard(
            log: _filteredLogs[i],
            isFirst: i == 0,
            onTap: () => _openLogDetail(_filteredLogs[i]),
          ),
          if (i < _filteredLogs.length - 1) const SizedBox(height: 12),
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
              color: AppColors.primary.withValues(alpha: 0.3),
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

class _FilterSheet extends StatelessWidget {
  final Discipline? selectedDiscipline;
  final ValueChanged<Discipline?> onDisciplineSelected;
  final VoidCallback onClearFilters;

  const _FilterSheet({
    required this.selectedDiscipline,
    required this.onDisciplineSelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('필터', style: AppTextStyles.titleSmall),
                if (selectedDiscipline != null)
                  GestureDetector(
                    onTap: onClearFilters,
                    child: Text(
                      '초기화',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '종목',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Discipline.values.map((discipline) {
                final isSelected = selectedDiscipline == discipline;
                return GestureDetector(
                  onTap: () => onDisciplineSelected(discipline),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tealDim : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.line,
                      ),
                    ),
                    child: Text(
                      discipline.displayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
