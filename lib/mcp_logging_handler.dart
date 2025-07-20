import 'package:at_utils/at_logger.dart';
import 'package:dart_mcp/server.dart';
import 'package:logging/logging.dart';

typedef MCPLoggingHandlerCallback =
    void Function(
      LoggingLevel level,
      Object data, {
      String? logger,
      Meta? meta,
    });

class MCPLoggingHandler extends LoggingHandler {
  MCPLoggingHandler({required this.log});

  final MCPLoggingHandlerCallback log;

  @override
  void call(LogRecord record) {
    log(record.level.loggingLevel, record.message, logger: record.loggerName);
  }
}

extension LoggingLevelExtension on Level {
  LoggingLevel get loggingLevel {
    switch (this) {
      case Level.FINEST:
        return LoggingLevel.debug;
      case Level.FINER:
        return LoggingLevel.debug;
      case Level.FINE:
        return LoggingLevel.debug;
      case Level.CONFIG:
        return LoggingLevel.debug;
      case Level.INFO:
        return LoggingLevel.info;
      case Level.WARNING:
        return LoggingLevel.warning;
      case Level.SEVERE:
        return LoggingLevel.alert;
      case Level.SHOUT:
        return LoggingLevel.critical;
      default:
        return LoggingLevel.notice;
    }
  }
}
