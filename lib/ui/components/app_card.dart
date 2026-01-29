import 'package:flutter/material.dart';

import '../design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: UiColors.shadow,
      margin: EdgeInsets.zero,
      color: backgroundColor ?? UiColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.card),
        side: const BorderSide(color: UiColors.divider),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(UiSpacing.md),
        child: child,
      ),
    );
  }
}

