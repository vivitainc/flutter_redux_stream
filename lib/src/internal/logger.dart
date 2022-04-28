import 'package:logger/logger.dart';

final _criticalLogger =
    Logger(printer: PrettyPrinter(methodCount: 20, errorMethodCount: 20));

final _debugLogger = Logger();

final _infoLogger = Logger();

const _tag = '[redux_stream]';

///
/// print critical log.
///
void logCritical(String message) {
  _criticalLogger.e('$_tag $message');
}

///
/// print debug with stack trace.
///
void logDebugStack(String message) {
  _debugLogger.d('$_tag $message');
}

///
/// print debug log.
///
void logDebug(String message) {
  _infoLogger.d('$_tag $message');
}

///
/// print info log.
///
void logInfo(String message) {
  print('$_tag $message'); // ignore: avoid_print
}

/// print error
void logError(
  String message,
  dynamic e,
  StackTrace? stackTrace,
) {
  _infoLogger.e('$_tag $message', e, stackTrace);
}
