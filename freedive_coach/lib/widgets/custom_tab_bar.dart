import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF0C141D).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTab(0, Icons.home_outlined, Icons.home, '홈'),
            _buildTab(1, Icons.menu_book_outlined, Icons.menu_book, '로그'),
            _buildTab(2, Icons.track_changes_outlined, Icons.track_changes, '코치'),
            _buildTab(3, Icons.air_outlined, Icons.air, '트레이닝'),
            _buildTab(4, Icons.person_outline, Icons.person, '마이'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tealDim : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? AppColors.primaryBright : AppColors.muted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryBright : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
