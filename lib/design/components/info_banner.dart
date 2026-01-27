import 'package:flutter/material.dart';

import '../tokens.dart';

class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onClose;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTokens.primaryLight;
    final iconTint = iconColor ?? AppTokens.primaryDeep;
    final labelColor = textColor ?? AppTokens.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconTint),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(
              message,
              style: AppText.caption.copyWith(color: labelColor),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: AppSpace.s8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
