import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/analyze_response.dart';
import 'models/result_payload.dart';
import '../core/image/image_source_service.dart';
import 'pages/app_shell.dart';
import 'pages/history_detail_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/preview_page.dart';
import 'pages/privacy_page.dart';
import 'pages/result_page.dart';
import 'pages/settings_page.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/preview',
        builder: (context, state) {
          final selection = state.extra is ImageSelection
              ? state.extra as ImageSelection
              : null;
          return PreviewPage(selection: selection);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/result',
        builder: (context, state) {
          if (state.extra is ResultPayload) {
            final payload = state.extra as ResultPayload;
            return ResultPage(
              initialAnalysis: payload.analysis,
              initialAdvice: payload.advice,
              initialStructured: payload.structured,
              validationWarning: payload.validationWarning,
            );
          }
          final analysis = state.extra is AnalyzeResponse
              ? state.extra as AnalyzeResponse
              : null;
          return ResultPage(initialAnalysis: analysis);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history/:id',
        builder: (context, state) {
          final recordId = state.pathParameters['id'] ?? '';
          return HistoryDetailPage(recordId: recordId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
    ],
  );
}
