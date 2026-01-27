import 'package:flutter/widgets.dart';
import 'package:app/l10n/app_localizations.dart';

class LocaleHelper {
  static final Set<String> _supportedLanguageCodes = AppLocalizations
      .supportedLocales
      .map((locale) => locale.languageCode)
      .toSet();

  static String currentLanguageCode({Locale? locale}) {
    final resolvedLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    final code = resolvedLocale.languageCode;
    return _supportedLanguageCodes.contains(code) ? code : 'en';
  }
}
