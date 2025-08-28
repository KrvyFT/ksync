import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  File? _logFile;
  final List<String> _logQueue = [];
  bool _isWriting = false;

  Future<void> init() async {
    if (_logFile != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/app_log.txt');
    if (!await _logFile!.exists()) {
      await _logFile!.create();
    }
  }

  void _addToQueue(String level, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp][$level] $message';
    if (error != null) {
      logMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      logMessage += '\nStackTrace: $stackTrace';
    }
    _logQueue.add(logMessage);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isWriting || _logQueue.isEmpty || _logFile == null) return;
    _isWriting = true;

    final logsToWrite = List<String>.from(_logQueue);
    _logQueue.clear();

    try {
      await _logFile!.writeAsString(
        '${logsToWrite.join('\n')}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // If writing fails, re-queue the logs
      _logQueue.insertAll(0, logsToWrite);
    } finally {
      _isWriting = false;
      // If there are still items in the queue, process them
      if (_logQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  void info(String message) {
    _addToQueue('INFO', message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _addToQueue('ERROR', message, error, stackTrace);
  }

  Future<String> getLogs() async {
    await init();
    if (await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return 'No logs found.';
  }

  Future<void> clearLogs() async {
    await init();
    if (await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }
}

// Global instance for easy access
final logger = LoggingService();
