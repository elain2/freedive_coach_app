import 'package:flutter/material.dart';
import '../models/discipline.dart';
import '../theme/app_theme.dart';

/// Chip-based selector for freediving disciplines
class DisciplineSelector extends StatelessWidget {
  final Discipline? selected;
  final ValueChanged<Discipline> onSelected;
  final bool showAll;
  final bool Function(Discipline)? filter;

  const DisciplineSelector({
    super.key,
    this.selected,
    required this.onSelected,
    this.showAll = true,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    var disciplines = showAll
        ? Discipline.values
        : Discipline.values.where((d) => d.isDepthDiscipline).toList();

    // Apply additional filter if provided
    if (filter != null) {
      disciplines = disciplines.where(filter!).toList();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: disciplines.map((discipline) {
        final isSelected = discipline == selected;
        return GestureDetector(
          onTap: () => onSelected(discipline),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.tealDim : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.line,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              discipline.displayName,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primaryBright : AppColors.muted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Compact discipline chip for display purposes
class DisciplineChip extends StatelessWidget {
  final Discipline discipline;
  final bool showFullName;

  const DisciplineChip({
    super.key,
    required this.discipline,
    this.showFullName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        showFullName ? discipline.fullName : discipline.displayName,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBright,
        ),
      ),
    );
  }
}
