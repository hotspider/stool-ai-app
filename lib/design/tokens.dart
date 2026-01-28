import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4FAF9A);
  static const Color secondary = Color(0xFF7CC6B6);
  static const Color primaryDeep = Color(0xFF3E9D88);
  static const Color primaryLight = Color(0xFFEAF6F3);
  static const Color bg = Color(0xFFF9FAFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadowColor = Color(0x14000000);
  static const Color riskLow = Color(0xFF6CC3A0);
  static const Color riskMedium = Color(0xFFF2C94C);
  static const Color riskHigh = Color(0xFFEB5757);
}

class AppRadius {
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r24 = 24;
}

class AppSpace {
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
}

class AppShadow {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadowColor,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

class AppText {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}

class AppTokens {
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color primaryDeep = AppColors.primaryDeep;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color bg = AppColors.bg;
  static const Color card = AppColors.card;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color divider = AppColors.divider;
  static const Color shadowColor = AppColors.shadowColor;
  static const Color riskLow = AppColors.riskLow;
  static const Color riskMedium = AppColors.riskMedium;
  static const Color riskHigh = AppColors.riskHigh;

  static const double r16 = AppRadius.r16;
  static const double r12 = AppRadius.r12;
  static const double r24 = AppRadius.r24;

  static const double s6 = AppSpace.s6;
  static const double s8 = AppSpace.s8;
  static const double s12 = AppSpace.s12;
  static const double s16 = AppSpace.s16;
  static const double s20 = AppSpace.s20;
  static const double s24 = AppSpace.s24;

  static const List<BoxShadow> shadowSoft = AppShadow.soft;

  static const TextStyle title = AppText.title;
  static const TextStyle section = AppText.section;
  static const TextStyle body = AppText.body;
  static const TextStyle caption = AppText.caption;
}
