import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../features/models/analyze_response.dart';
import '../tokens.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(riskLevel);
    final l10n = AppLocalizations.of(context)!;
    final label = _riskLabel(l10n, riskLevel);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption.copyWith(
              color: AppTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return AppTokens.riskHigh;
      case RiskLevel.medium:
        return AppTokens.riskMedium;
      case RiskLevel.low:
        return AppTokens.riskLow;
    }
  }

  String _riskLabel(AppLocalizations l10n, RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return l10n.riskHighLabel;
      case RiskLevel.medium:
        return l10n.riskMediumLabel;
      case RiskLevel.low:
        return l10n.riskLowLabel;
    }
  }
}
