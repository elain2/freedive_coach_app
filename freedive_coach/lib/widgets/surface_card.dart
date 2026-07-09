import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: borderColor ?? AppColors.line,
          width: borderWidth ?? 1,
        ),
      ),
      child: child,
    );
  }
}

class TealCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const TealCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.tealDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor ?? AppColors.primaryBright,
        ),
      ),
    );
  }
}
