import 'package:flutter/material.dart';

import '../design/tokens.dart';

class UiColors {
  static const Color primary = AppColors.primary;
  static const Color primaryDeep = AppColors.primaryDeep;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color background = AppColors.bg;
  static const Color card = AppColors.card;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color divider = AppColors.divider;
  static const Color riskLow = AppColors.riskLow;
  static const Color riskMedium = AppColors.riskMedium;
  static const Color riskHigh = AppColors.riskHigh;
  static const Color shadow = AppColors.shadowColor;
}

class UiSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
}

class UiRadius {
  static const double card = 12;
}

class UiText {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: UiColors.textPrimary,
  );
  static const TextStyle section = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: UiColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: UiColors.textPrimary,
  );
  static const TextStyle hint = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: UiColors.textSecondary,
  );
}

