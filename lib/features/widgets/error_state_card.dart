import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/widgets/soft_card.dart';

class ErrorStateCard extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ErrorStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 40, color: AppTokens.riskMedium),
          const SizedBox(height: AppTokens.s12),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.s8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
