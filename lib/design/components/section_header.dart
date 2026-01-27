import 'package:flutter/material.dart';

import '../tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppText.section,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
