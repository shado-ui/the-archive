import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _isDebugMode = kDebugMode;

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (_isDebugMode) {
      debugPrint('🔵 DEBUG: $message', wrapWidth: 1024);
      if (error != null) {
        debugPrint('  Error: $error', wrapWidth: 1024);
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace', wrapWidth: 1024);
      }
    }
  }

  static void info(String message) {
    if (_isDebugMode) {
      debugPrint('🟢 INFO: $message', wrapWidth: 1024);
    }
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    if (_isDebugMode) {
      debugPrint('🟡 WARNING: $message', wrapWidth: 1024);
      if (error != null) {
        debugPrint('  Error: $error', wrapWidth: 1024);
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace', wrapWidth: 1024);
      }
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('🔴 ERROR: $message', wrapWidth: 1024);
    if (error != null) {
      debugPrint('  Error: $error', wrapWidth: 1024);
    }
    if (stackTrace != null) {
      debugPrint('  Stack: $stackTrace', wrapWidth: 1024);
    }
  }
}
