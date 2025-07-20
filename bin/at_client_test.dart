import 'package:at_mcp_server/init_at_client.dart';
import 'package:at_mcp_server/mcp_logging_handler.dart';

Future<void> main() async {
  final logHander = MCPLoggingHandler(
    log: (level, message, {logger, meta}) {
      print('TEST: [$level] $message');
    },
  );

  final atClient = await initAtClient(
    mcpLoggingHandler: logHander,
    rootDomain: 'root.atsign.org',
    namespace: 'test',
    atsign: 'goldboldassault',
  );

  final keys = await atClient.getAtKeys();
  print(keys);
}
