import 'dart:io';

import 'package:at_mcp_server/init_at_client.dart';
import 'package:at_mcp_server/mcp_logging_handler.dart';

Future<void> main() async {
  final logHander = MCPLoggingHandler(
    log: (level, message, {logger, meta}) {
      print('TEST: [$level] $message');
    },
  );

  final homeDirectory = Platform.environment['HOME'];
  final atClient = await initAtClient(
    mcpLoggingHandler: logHander,
    homeDirectory: homeDirectory ?? '',
    rootDomain: 'root.atsign.org',
    rootPort: 64,
    namespace: null,
    atsign: '@goldboldassault',
  );

  final keys = await atClient.getAtKeys();
  print(keys);
}
