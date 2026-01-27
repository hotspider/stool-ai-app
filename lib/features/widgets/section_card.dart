import 'package:flutter/material.dart';

import '../../design/widgets/section_title.dart';
import '../../design/widgets/soft_card.dart';
import '../../design/tokens.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, trailing: trailing),
          const SizedBox(height: AppTokens.s12),
          child,
        ],
      ),
    );
  }
}
