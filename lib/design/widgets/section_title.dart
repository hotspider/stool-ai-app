import 'package:flutter/material.dart';

import '../tokens.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({
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
            style: AppTokens.section,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
