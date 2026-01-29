import 'package:flutter/material.dart';

import '../design_tokens.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? tag;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: UiColors.primaryDeep),
        const SizedBox(width: UiSpacing.sm),
        Expanded(child: Text(title, style: UiText.section)),
        if (tag != null && tag!.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UiSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: UiColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: UiColors.divider),
            ),
            child: Text(tag!, style: UiText.hint),
          ),
      ],
    );
  }
}

