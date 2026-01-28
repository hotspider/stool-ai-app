import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/l10n/app_localizations.dart';

import 'core/app_error_handler.dart';
import 'design/app_theme.dart';
import 'features/app_router.dart';
import 'features/services/storage_service.dart';

Future<void> main() async {
  FlutterError.onError = (details) {
    AppErrorHandler.handle(details.exception, details.stack);
  };
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await StorageService.init();
    runApp(const HealthApp());
  }, (error, stack) {
    AppErrorHandler.handle(error, stack);
  });
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return const Locale('en');
        }
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
    );
  }
}
