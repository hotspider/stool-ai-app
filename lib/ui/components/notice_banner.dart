import 'package:flutter/material.dart';

import '../design_tokens.dart';

class NoticeBanner extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color? color;

  const NoticeBanner({
    super.key,
    required this.title,
    required this.items,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final background = (color ?? UiColors.riskHigh).withOpacity(0.08);
    final border = color ?? UiColors.riskHigh;
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(UiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: border),
              const SizedBox(width: UiSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: UiText.section.copyWith(color: border),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpacing.sm),
          ...items
              .where((item) => item.trim().isNotEmpty)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: UiSpacing.xs),
                  child: Text('• $item', style: UiText.body),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

