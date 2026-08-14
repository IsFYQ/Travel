import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// P1-3.14：分级日志，release 模式不输出敏感信息
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static final _sensitivePattern = RegExp(r'sk-[a-zA-Z0-9]+|api[_-]?key', caseSensitive: false);

  Future<void> init() async {
    if (kReleaseMode) {
      FlutterError.onError = (details) {
        logError('FlutterError', details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        logError('PlatformError', error, stack);
        return true;
      };
    }
  }

  void debug(String message) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
  }

  void info(String message) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('[INFO] $message');
    }
    _writeToFile('INFO', message);
  }

  void logError(String tag, Object error, StackTrace? stack) {
    final msg = _sanitize('$tag: $error\n$stack');
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('[ERROR] $msg');
    }
    _writeToFile('ERROR', msg);
  }

  String _sanitize(String input) {
    if (kReleaseMode) {
      return input.replaceAll(_sensitivePattern, '***');
    }
    return input;
  }

  Future<void> _writeToFile(String level, String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(dir.path, 'logs'));
      if (!await logDir.exists()) await logDir.create(recursive: true);
      final today = DateTime.now();
      final file = File(p.join(
        logDir.path,
        'app_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}.log',
      ));
      final line = '[${DateTime.now().toIso8601String()}][$level] ${_sanitize(message)}\n';
      await file.writeAsString(line, mode: FileMode.append);
      await _cleanOldLogs(logDir);
    } catch (_) {}
  }

  /// 滚动保留最近 7 天
  Future<void> _cleanOldLogs(Directory logDir) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await for (final entity in logDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    }
  }
}
