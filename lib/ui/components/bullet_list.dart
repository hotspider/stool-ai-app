import 'package:flutter/material.dart';

import '../design_tokens.dart';

class BulletList extends StatelessWidget {
  final List<String> items;
  final TextStyle? style;

  const BulletList({
    super.key,
    required this.items,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? UiText.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .where((item) => item.trim().isNotEmpty)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: UiSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: UiText.body),
                  Expanded(child: Text(item, style: textStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

