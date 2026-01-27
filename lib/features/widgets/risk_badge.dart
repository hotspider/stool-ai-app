import 'package:flutter/material.dart';

import '../../design/widgets/risk_badge.dart' as design;
import '../models/analyze_response.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool compact;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: compact ? 0.9 : 1,
      alignment: Alignment.centerLeft,
      child: design.RiskBadge(riskLevel: riskLevel),
    );
  }
}
