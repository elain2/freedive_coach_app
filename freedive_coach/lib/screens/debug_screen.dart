import 'dart:math';
import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../models/dive_log.dart';
import '../services/log_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _logStorage = LogStorage();
  int _logCount = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadLogCount();
  }

  Future<void> _loadLogCount() async {
    final logs = await _logStorage.getLogs();
    setState(() => _logCount = logs.length);
  }

  Future<void> _generateMockLogs(int count) async {
    setState(() => _isGenerating = true);

    final random = Random();
    const disciplines = Discipline.values;
    final locations = [
      '제주 서귀포',
      '제주 협재',
      '부산 기장',
      '필리핀 세부',
      '인도네시아 발리',
      '이집트 다합',
      '태국 코타오',
      '강원 속초',
    ];
    final conditions = [
      '컨디션 좋음',
      '귀 타이트',
      '이퀄 어려움',
      '컨트랙션 빨리 옴',
      '릴렉스 잘됨',
      '프리폴 편안함',
      '턴 부드러움',
      null,
    ];

    for (int i = 0; i < count; i++) {
      final discipline = disciplines[random.nextInt(disciplines.length)];
      final daysAgo = random.nextInt(180); // Last 6 months
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      double? depth;
      double? distance;
      Duration? duration;
      double? mouthfillDepth;
      double? freefallDepth;

      if (discipline.isDepthDiscipline) {
        depth = 15 + random.nextDouble() * 30; // 15-45m
        mouthfillDepth = depth * (0.6 + random.nextDouble() * 0.2); // 60-80% of depth
        freefallDepth = depth * (0.7 + random.nextDouble() * 0.2); // 70-90% of depth
        duration = Duration(
          minutes: 1 + random.nextInt(2),
          seconds: random.nextInt(60),
        );
      } else if (discipline.isDistanceDiscipline) {
        distance = 50 + random.nextDouble() * 100; // 50-150m
        duration = Duration(
          minutes: 1 + random.nextInt(3),
          seconds: random.nextInt(60),
        );
      } else {
        // STA
        duration = Duration(
          minutes: 2 + random.nextInt(4),
          seconds: random.nextInt(60),
        );
      }

      final log = DiveLog.create(
        diveDate: date,
        discipline: discipline,
        location: locations[random.nextInt(locations.length)],
        depth: depth,
        distance: distance,
        duration: duration,
        mouthfillDepth: mouthfillDepth,
        freefallDepth: freefallDepth,
        weight: 2 + random.nextDouble() * 4, // 2-6kg
        condition: conditions[random.nextInt(conditions.length)],
        notes: random.nextBool() ? '테스트 목 데이터 #${i + 1}' : null,
      );

      await _logStorage.saveLog(log);
    }

    await _loadLogCount();
    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count개의 목 데이터가 생성되었습니다')),
      );
    }
  }

  Future<void> _deleteAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('모든 로그 삭제', style: AppTextStyles.titleSmall),
        content: Text(
          '정말로 모든 로그($_logCount개)를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: AppTextStyles.body.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isGenerating = true);

      final logs = await _logStorage.getLogs();
      for (final log in logs) {
        await _logStorage.deleteLog(log.id);
      }

      await _loadLogCount();
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 로그가 삭제되었습니다')),
        );
      }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildGenerateSection(),
                    const SizedBox(height: 20),
                    _buildDangerZone(),
                  ],
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
          Row(
            children: [
              const Icon(Icons.bug_report, size: 18, color: AppColors.coral),
              const SizedBox(width: 8),
              Text('디버그 메뉴', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storage, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 저장된 로그', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(
                  '$_logCount개',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryBright,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          if (_isGenerating)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('목 데이터 생성', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenerateButton('5개', 5)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('10개', 10)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('30개', 30)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenerateButton('50개', 50)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton('100개', 100)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '랜덤한 다이빙 로그를 생성합니다.\n종목, 수심, 날짜, 장소 등이 무작위로 설정됩니다.',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(String label, int count) {
    return GestureDetector(
      onTap: _isGenerating ? null : () => _generateMockLogs(count),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isGenerating ? AppColors.surface2 : AppColors.tealDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: _isGenerating ? AppColors.muted : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, size: 16, color: AppColors.coral),
            const SizedBox(width: 8),
            Text(
              '위험 구역',
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.coral),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isGenerating || _logCount == 0 ? null : _deleteAllLogs,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _logCount == 0 ? AppColors.line : AppColors.coral.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                '모든 로그 삭제',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _logCount == 0 ? AppColors.muted : AppColors.coral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
