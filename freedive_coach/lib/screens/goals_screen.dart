import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discipline.dart';
import '../theme/app_theme.dart';
import '../widgets/surface_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  static const String _goalsKey = 'user_goals';

  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_goalsKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final jsonList = jsonDecode(jsonString) as List;
        setState(() {
          _goals = jsonList.map((json) => Goal.fromJson(json)).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _goals.map((g) => g.toJson()).toList();
    await prefs.setString(_goalsKey, jsonEncode(jsonList));
  }

  void _addGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddGoalSheet(
        onAdd: (goal) {
          setState(() {
            _goals.add(goal);
          });
          _saveGoals();
        },
      ),
    );
  }

  void _toggleGoalComplete(int index) {
    setState(() {
      _goals[index] = _goals[index].copyWith(
        isCompleted: !_goals[index].isCompleted,
        completedAt: _goals[index].isCompleted ? null : DateTime.now(),
      );
    });
    _saveGoals();
  }

  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
    _saveGoals();
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
                  : _goals.isEmpty
                      ? _buildEmptyState()
                      : _buildGoalsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
          Text('나의 목표', style: AppTextStyles.titleSmall),
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_outlined, size: 36, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Text(
              '아직 목표가 없어요',
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 목표를 추가해서\n프리다이빙 실력을 키워보세요',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _addGoal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '목표 추가하기',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    final activeGoals = _goals.where((g) => !g.isCompleted).toList();
    final completedGoals = _goals.where((g) => g.isCompleted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeGoals.isNotEmpty) ...[
            Text('진행 중', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            ...activeGoals.map((goal) => _buildGoalCard(goal, _goals.indexOf(goal))),
          ],
          if (completedGoals.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('완료됨', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            ...completedGoals.map((goal) => _buildGoalCard(goal, _goals.indexOf(goal))),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(goal.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.coral,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _deleteGoal(index),
        child: SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleGoalComplete(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: goal.isCompleted ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: goal.isCompleted ? AppColors.primary : AppColors.muted,
                      width: 2,
                    ),
                  ),
                  child: goal.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppBadge(
                          text: goal.discipline.displayName,
                          backgroundColor: AppColors.tealDim,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          text: goal.typeLabel,
                          backgroundColor: AppColors.surface2,
                          textColor: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goal.description,
                      style: AppTextStyles.body.copyWith(
                        decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                        color: goal.isCompleted ? AppColors.muted : AppColors.text,
                      ),
                    ),
                    if (goal.targetValue != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '목표: ${goal.targetValue}${goal.unit}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryBright),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final Function(Goal) onAdd;

  const _AddGoalSheet({required this.onAdd});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  Discipline _selectedDiscipline = Discipline.cwt;
  GoalType _selectedType = GoalType.depth;
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 설명을 입력해주세요')),
      );
      return;
    }

    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      discipline: _selectedDiscipline,
      type: _selectedType,
      description: _descriptionController.text,
      targetValue: _targetController.text.isNotEmpty
          ? double.tryParse(_targetController.text)
          : null,
      createdAt: DateTime.now(),
    );

    widget.onAdd(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('새 목표 추가', style: AppTextStyles.titleSmall),
          const SizedBox(height: 20),

          Text('종목', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Discipline.values.map((d) {
              final isSelected = d == _selectedDiscipline;
              return GestureDetector(
                onTap: () => setState(() => _selectedDiscipline = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tealDim : AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.line,
                    ),
                  ),
                  child: Text(
                    d.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('목표 유형', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GoalType.values.map((t) {
              final isSelected = t == _selectedType;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tealDim : AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.line,
                    ),
                  ),
                  child: Text(
                    t.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('목표 설명', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: '예: 40m 도달하기',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('목표 수치 (선택)', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          TextField(
            controller: _targetController,
            style: AppTextStyles.body,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: _selectedType.hintText,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixText: _selectedType.unit,
              suffixStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
          ),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '목표 추가',
                  style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum GoalType {
  depth,
  duration,
  distance,
  technique,
  training,
}

extension GoalTypeExtension on GoalType {
  String get label {
    switch (this) {
      case GoalType.depth:
        return '수심';
      case GoalType.duration:
        return '시간';
      case GoalType.distance:
        return '거리';
      case GoalType.technique:
        return '테크닉';
      case GoalType.training:
        return '훈련';
    }
  }

  String get unit {
    switch (this) {
      case GoalType.depth:
        return 'm';
      case GoalType.duration:
        return '분';
      case GoalType.distance:
        return 'm';
      case GoalType.technique:
      case GoalType.training:
        return '';
    }
  }

  String get hintText {
    switch (this) {
      case GoalType.depth:
        return '목표 수심';
      case GoalType.duration:
        return '목표 시간';
      case GoalType.distance:
        return '목표 거리';
      case GoalType.technique:
      case GoalType.training:
        return '목표 횟수';
    }
  }
}

class Goal {
  final String id;
  final Discipline discipline;
  final GoalType type;
  final String description;
  final double? targetValue;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;

  const Goal({
    required this.id,
    required this.discipline,
    required this.type,
    required this.description,
    this.targetValue,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
  });

  String get typeLabel => type.label;
  String get unit => type.unit;

  Goal copyWith({
    String? id,
    Discipline? discipline,
    GoalType? type,
    String? description,
    double? targetValue,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      discipline: discipline ?? this.discipline,
      type: type ?? this.type,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'discipline': discipline.name,
    'type': type.name,
    'description': description,
    'targetValue': targetValue,
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    discipline: Discipline.values.firstWhere(
      (d) => d.name == json['discipline'],
      orElse: () => Discipline.cwt,
    ),
    type: GoalType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => GoalType.depth,
    ),
    description: json['description'] as String,
    targetValue: json['targetValue'] as double?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}
