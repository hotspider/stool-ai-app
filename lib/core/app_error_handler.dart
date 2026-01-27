import 'package:flutter/foundation.dart';

class AppErrorHandler {
  static void handle(Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('App error: $error');
      if (stack != null) {
        debugPrint('$stack');
      }
    }
  }
}
