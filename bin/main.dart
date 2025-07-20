import 'dart:io' as io;

import 'package:at_mcp_server/at_mcp_server.dart';
import 'package:dart_mcp/stdio.dart';

void main() {
  // Create the server and connect it to stdio.
  final _ = AtSignMCPServer(stdioChannel(input: io.stdin, output: io.stdout));
}
