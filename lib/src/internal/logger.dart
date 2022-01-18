import 'package:logger/logger.dart';

final _criticalLogger =
    Logger(printer: PrettyPrinter(methodCount: 20, errorMethodCount: 20));

final _debugLogger = Logger();

final _infoLogger = Logger();

///
/// print critical log.
///
void logCritical(String message) {
  _criticalLogger.e(message);
}

///
/// print debug with stack trace.
///
void logDebugStack(String message) {
  _debugLogger.d(message);
}

///
/// print debug log.
///
void logDebug(String message) {
  _infoLogger.d(message);
}

///
/// print info log.
///
void logInfo(String message) {
  print(message); // ignore: avoid_print
}

/// print error
void logError(
  String message,
  dynamic e,
  StackTrace? stackTrace,
) {
  _infoLogger.e(message, e, stackTrace);
}
