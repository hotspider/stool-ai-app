import 'package:flutter/material.dart';

import '../tokens.dart';
import 'primary_button.dart';
import 'soft_card.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SoftCard(
        padding: const EdgeInsets.all(AppTokens.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.primaryLight, AppTokens.card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTokens.r16),
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 36, color: AppTokens.primaryDeep),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(title, style: AppTokens.section),
            const SizedBox(height: AppTokens.s8),
            Text(message, style: AppTokens.caption, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.s16),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
