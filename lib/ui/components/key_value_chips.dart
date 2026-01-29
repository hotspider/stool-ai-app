import 'package:flutter/material.dart';

import '../design_tokens.dart';

class KeyValueChips extends StatelessWidget {
  final List<String> labels;

  const KeyValueChips({
    super.key,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = labels
        .where((label) => label.trim().isNotEmpty)
        .take(4)
        .toList();
    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: UiSpacing.sm,
      runSpacing: UiSpacing.sm,
      children: filtered
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: UiColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: UiColors.divider),
              ),
              child: Text(
                label,
                style: UiText.hint.copyWith(color: UiColors.primaryDeep),
              ),
            ),
          )
          .toList(),
    );
  }
}

