import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/breathing_table.dart';
import '../services/table_generator.dart';
import '../widgets/surface_card.dart';
import 'breathing_timer_screen.dart';

class BreathingSetupScreen extends StatefulWidget {
  final TableType initialType;

  const BreathingSetupScreen({
    super.key,
    this.initialType = TableType.co2,
  });

  @override
  State<BreathingSetupScreen> createState() => _BreathingSetupScreenState();
}

class _BreathingSetupScreenState extends State<BreathingSetupScreen> {
  late TableType _selectedType;
  int _pbMinutes = 2;
  int _pbSeconds = 0;
  bool _showSafetyWarning = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Duration get _personalBest => Duration(
    minutes: _pbMinutes,
    seconds: _pbSeconds,
  );

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
        title: Text('호흡 훈련 설정', style: AppTextStyles.titleSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety warning
            if (_showSafetyWarning) _buildSafetyWarning(),
            const SizedBox(height: 20),
            // Table type selection
            _buildTableTypeSelector(),
            const SizedBox(height: 24),
            // PB input
            _buildPBInput(),
            const SizedBox(height: 24),
            // Table preview
            _buildTablePreview(),
            const SizedBox(height: 32),
            // Start button
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C3A3A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안전 수칙',
                  style: AppTextStyles.sectionTitle.copyWith(color: const Color(0xFFFFB74D)),
                ),
                const SizedBox(height: 8),
                Text(
                  '물속에서 절대 혼자 훈련하지 마세요.\n무리한 훈련 시 즉시 중단하세요.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
            onPressed: () => setState(() => _showSafetyWarning = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('훈련 유형', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTypeCard(TableType.co2)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeCard(TableType.o2)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard(TableType type) {
    final isSelected = _selectedType == type;
    final isCO2 = type == TableType.co2;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBright : AppColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCO2 ? Icons.monitor_heart_outlined : Icons.favorite_outline,
              size: 24,
              color: isSelected ? AppColors.primaryBright : AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              isCO2 ? 'CO\u2082 테이블' : 'O\u2082 테이블',
              style: AppTextStyles.sectionTitle.copyWith(
                color: isSelected ? AppColors.text : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCO2 ? '회복 시간 감소' : '숨참기 시간 증가',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPBInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STA PB (정적 숨참기 기록)', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          borderColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes
              _buildNumberPicker(
                value: _pbMinutes,
                label: '분',
                min: 0,
                max: 10,
                onChanged: (v) => setState(() => _pbMinutes = v),
              ),
              const SizedBox(width: 8),
              Text(':', style: AppTextStyles.titleLarge),
              const SizedBox(width: 8),
              // Seconds
              _buildNumberPicker(
                value: _pbSeconds,
                label: '초',
                min: 0,
                max: 59,
                step: 15,
                onChanged: (v) => setState(() => _pbSeconds = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required String label,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          color: AppColors.primaryBright,
          onPressed: () {
            final newValue = value + step;
            if (newValue <= max) onChanged(newValue);
          },
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontFamily: 'monospace',
              fontSize: 32,
            ),
          ),
        ),
        Text(label, style: AppTextStyles.caption),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          color: AppColors.primaryBright,
          onPressed: () {
            final newValue = value - step;
            if (newValue >= min) onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildTablePreview() {
    if (_personalBest.inSeconds < 30) {
      return const SizedBox.shrink();
    }

    final table = TableGenerator.generateTable(_selectedType, _personalBest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('테이블 미리보기', style: AppTextStyles.sectionTitle),
            Text(
              '총 ${_formatDuration(table.totalDuration)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(12),
          borderColor: Colors.transparent,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        '회복',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '숨참기',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: const Color(0xFFFF6B6B)),
                      ),
                    ),
                  ],
                ),
              ),
              // Rounds
              ...table.rounds.map((round) => _buildRoundRow(round)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundRow(TableRound round) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${round.roundNumber}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              _formatDuration(round.recoveryTime),
              textAlign: TextAlign.center,
              style: AppTextStyles.monoSmall,
            ),
          ),
          Expanded(
            child: Text(
              _formatDuration(round.holdTime),
              textAlign: TextAlign.center,
              style: AppTextStyles.monoSmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStartButton() {
    final isValid = _personalBest.inSeconds >= 30;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid ? _startTraining : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.muted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isValid ? '훈련 시작' : 'PB를 30초 이상 입력하세요',
          style: AppTextStyles.sectionTitle.copyWith(
            color: isValid ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }

  void _startTraining() {
    final table = TableGenerator.generateTable(_selectedType, _personalBest);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BreathingTimerScreen(table: table),
      ),
    );
  }
}
