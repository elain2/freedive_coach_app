import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const String _settingsKey = 'notification_settings';

  bool _isLoading = true;
  bool _trainingReminder = true;
  bool _goalReminder = true;
  bool _weeklyReport = true;
  bool _appUpdates = false;
  TimeOfDay _trainingTime = const TimeOfDay(hour: 9, minute: 0);
  List<int> _trainingDays = [1, 3, 5]; // Mon, Wed, Fri

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        setState(() {
          _trainingReminder = json['trainingReminder'] as bool? ?? true;
          _goalReminder = json['goalReminder'] as bool? ?? true;
          _weeklyReport = json['weeklyReport'] as bool? ?? true;
          _appUpdates = json['appUpdates'] as bool? ?? false;
          _trainingTime = TimeOfDay(
            hour: json['trainingHour'] as int? ?? 9,
            minute: json['trainingMinute'] as int? ?? 0,
          );
          _trainingDays = (json['trainingDays'] as List?)?.cast<int>() ?? [1, 3, 5];
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = {
      'trainingReminder': _trainingReminder,
      'goalReminder': _goalReminder,
      'weeklyReport': _weeklyReport,
      'appUpdates': _appUpdates,
      'trainingHour': _trainingTime.hour,
      'trainingMinute': _trainingTime.minute,
      'trainingDays': _trainingDays,
    };
    await prefs.setString(_settingsKey, jsonEncode(json));
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _trainingTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _trainingTime = picked;
      });
      _saveSettings();
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_trainingDays.contains(day)) {
        _trainingDays.remove(day);
      } else {
        _trainingDays.add(day);
        _trainingDays.sort();
      }
    });
    _saveSettings();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
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
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainToggles(),
                          if (_trainingReminder) ...[
                            const SizedBox(height: 24),
                            _buildTrainingSchedule(),
                          ],
                          const SizedBox(height: 24),
                          _buildOtherSettings(),
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
          Text('알림 설정', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildMainToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('알림', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildToggleItem(
                icon: Icons.fitness_center,
                title: '훈련 리마인더',
                description: '설정한 시간에 훈련 알림을 받아요',
                value: _trainingReminder,
                onChanged: (value) {
                  setState(() => _trainingReminder = value);
                  _saveSettings();
                },
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildToggleItem(
                icon: Icons.flag,
                title: '목표 리마인더',
                description: '목표 달성 현황을 알려드려요',
                value: _goalReminder,
                onChanged: (value) {
                  setState(() => _goalReminder = value);
                  _saveSettings();
                },
              ),
              const Divider(color: AppColors.line, height: 24),
              _buildToggleItem(
                icon: Icons.bar_chart,
                title: '주간 리포트',
                description: '매주 훈련 요약을 받아요',
                value: _weeklyReport,
                onChanged: (value) {
                  setState(() => _weeklyReport = value);
                  _saveSettings();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingSchedule() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('훈련 알림 시간', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _selectTime,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: AppColors.muted),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('알림 시간', style: AppTextStyles.body),
                    ),
                    Text(
                      _formatTime(_trainingTime),
                      style: AppTextStyles.body.copyWith(color: AppColors.primaryBright),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
              const Divider(color: AppColors.line, height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: AppColors.muted),
                      const SizedBox(width: 14),
                      Text('알림 요일', style: AppTextStyles.body),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1;
                      final isSelected = _trainingDays.contains(dayNum);
                      return GestureDetector(
                        onTap: () => _toggleDay(dayNum),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tealDim : AppColors.surface2,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              days[index],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? Colors.white : AppColors.muted,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기타', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: _buildToggleItem(
            icon: Icons.system_update,
            title: '앱 업데이트 알림',
            description: '새로운 기능이 추가되면 알려드려요',
            value: _appUpdates,
            onChanged: (value) {
              setState(() => _appUpdates = value);
              _saveSettings();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}
