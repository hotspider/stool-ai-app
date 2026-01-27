import 'package:flutter/material.dart';

import '../tokens.dart';
import 'animated_entry.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s16),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedEntry(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadow.soft,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
