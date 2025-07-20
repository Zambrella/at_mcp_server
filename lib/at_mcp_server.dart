import 'dart:async';

import 'package:at_client/at_client.dart';
import 'package:at_mcp_server/init_at_client.dart';
import 'package:at_mcp_server/mcp_logging_handler.dart';
import 'package:at_utils/at_utils.dart';
import 'package:dart_mcp/server.dart';
import 'package:http/http.dart' as http;

base class AtSignMCPServer extends MCPServer with ToolsSupport, LoggingSupport, ResourcesSupport {
  AtSignMCPServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          title: 'atPlatform MCP Server',
          name: 'A server for interacting the atPlatform and getting information about the atPlatform.',
          version: '0.1.0',
        ),
        instructions:
            'Just list and call the tools or request resources for information about the atPlatform or atSign.',
      ) {
    _mcpLoggingHandler = MCPLoggingHandler(log: log);
    registerTool(_listKeysTool, _listKeys);
    registerTool(_getKeyTool, _getKey);
    addMarkdownDocsResources();
  }

  late final MCPLoggingHandler _mcpLoggingHandler;

  static final markdownDocs = [
    MarkdownDoc(
      filename: 'at_protocol_specification.md',
      title: 'atProtocol Specification',
      description: 'Detailed specification of the atProtocol',
      uri: Uri.parse(
        'https://raw.githubusercontent.com/atsign-foundation/at_protocol/refs/heads/trunk/specification/at_protocol_specification.md',
      ),
    ),
    MarkdownDoc(
      filename: 'at_platform.md',
      title: 'atPlatform',
      description: 'An overview of Atsign\'s core pillars of technology',
      uri: Uri.parse('https://docs.atsign.com/core.md'),
    ),
  ];

  void addMarkdownDocsResources() {
    for (final doc in markdownDocs) {
      final resource = Resource(
        uri: 'file://${doc.filename}',
        name: doc.title,
        description: doc.description,
        mimeType: 'text/markdown',
      );
      addResource(
        resource,
        (ReadResourceRequest request) async {
          return ReadResourceResult(
            contents: [
              TextResourceContents(
                text: await doc.fetchResource(),
                uri: request.uri,
                mimeType: 'text/markdown',
              ),
            ],
          );
        },
      );
    }
  }

  final _listKeysTool = Tool(
    name: 'listKeys',
    description: 'Returns a list of the full names of the keys for the given atsign\'s server',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atsign to list keys for',
        ),
        'rootDomain': Schema.string(
          description: 'The root domain to use',
        ),
        'namespace': Schema.string(
          description: 'The namespace to use',
        ),
      },
      required: ['atsign'],
    ),
  );

  Future<CallToolResult> _listKeys(CallToolRequest request) async {
    // Validate input arguments
    final args = request.arguments;
    final rootDomain = (args?['rootDomain'] as String?) ?? 'root.atsign.org';
    final namespace = (args?['namespace'] as String?) ?? '';

    var atsign = (args?['atsign'] as String?);
    if (atsign == null) {
      log(LoggingLevel.error, 'Atsign is required');
      return CallToolResult(
        content: [
          TextContent(
            text: 'Atsign is required',
          ),
        ],
        isError: true,
      );
    }
    try {
      atsign = AtUtils.fixAtSign(atsign);
    } catch (e) {
      log(LoggingLevel.error, e.toString());
      return CallToolResult(
        content: [
          TextContent(
            text: e.toString(),
          ),
        ],
        isError: true,
      );
    }

    log(LoggingLevel.debug, 'Initializing AtClient');
    final client = await initAtClient(
      mcpLoggingHandler: _mcpLoggingHandler,
      rootDomain: rootDomain,
      namespace: namespace,
      atsign: atsign,
    );
    log(LoggingLevel.debug, 'AtClient initialized');

    log(LoggingLevel.debug, 'Fetching keys');
    final keys = await client.getAtKeys();
    log(LoggingLevel.debug, '${keys.length} Keys fetched');

    return CallToolResult(
      content: keys.map((key) => TextContent(text: key.toString())).toList(),
    );
  }

  final _getKeyTool = Tool(
    name: 'getKey',
    description: 'gets the value of a key',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atsign to list keys for',
        ),
        'rootDomain': Schema.string(
          description: 'The root domain to use',
        ),
        'namespace': Schema.string(
          description: 'The namespace to use',
        ),
        'key': Schema.string(
          description: 'The key to get',
        ),
      },
      required: ['atsign', 'namespace', 'key'],
    ),
  );

  Future<CallToolResult> _getKey(CallToolRequest request) async {
    // Validate input arguments
    final args = request.arguments;
    final rootDomain = (args?['rootDomain'] as String?) ?? 'root.atsign.org';
    final namespace = (args?['namespace'] as String?);
    final key = (args?['key'] as String?);
    if (namespace == null) {
      log(LoggingLevel.error, 'Namespace is required');
      return CallToolResult(
        content: [
          TextContent(
            text: 'Namespace is required',
          ),
        ],
        isError: true,
      );
    }
    final atsign = (args?['atsign'] as String?);
    if (atsign == null) {
      log(LoggingLevel.error, 'Atsign is required');
      return CallToolResult(
        content: [
          TextContent(
            text: 'Atsign is required',
          ),
        ],
        isError: true,
      );
    }
    if (key == null) {
      log(LoggingLevel.error, 'Key is required');
      return CallToolResult(
        content: [
          TextContent(
            text: 'Key is required',
          ),
        ],
        isError: true,
      );
    }

    log(LoggingLevel.debug, 'Initializing AtClient');
    final client = await initAtClient(
      mcpLoggingHandler: _mcpLoggingHandler,
      rootDomain: rootDomain,
      namespace: namespace,
      atsign: atsign.replaceAllMapped(RegExp(r'@'), (match) => ''),
    );
    log(LoggingLevel.debug, 'AtClient initialized');

    log(LoggingLevel.debug, 'Fetching key');
    final atValue = await client.get(AtKey.fromString(key));
    final value = atValue.toString();

    return CallToolResult(
      content: [
        TextContent(
          text: value,
        ),
      ],
    );
  }
}

class MarkdownDoc {
  const MarkdownDoc({
    required this.filename,
    required this.title,
    required this.description,
    required this.uri,
  });

  final String filename;
  final String title;
  final String description;
  final Uri uri;

  Future<String> fetchResource() async {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load resource');
    }
  }
}
