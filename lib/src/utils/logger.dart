import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static LogLevel _level = LogLevel.info;

  static void setLevel(LogLevel level) {
    _level = level;
  }

  static void debug(String message) {
    if (_level.index <= LogLevel.debug.index) {
      debugPrint('DEBUG: $message');
    }
  }

  static void info(String message) {
    if (_level.index <= LogLevel.info.index) {
      debugPrint('INFO: $message');
    }
  }

  static void warning(String message) {
    if (_level.index <= LogLevel.warning.index) {
      debugPrint('WARNING: $message');
    }
  }

  static void error(String message) {
    if (_level.index <= LogLevel.error.index) {
      debugPrint('ERROR: $message');
    }
  }
}
