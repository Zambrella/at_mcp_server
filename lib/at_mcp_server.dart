import 'dart:async';
import 'dart:io';

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
    loggingLevel = LoggingLevel.debug;
    _mcpLoggingHandler = MCPLoggingHandler(log: log);
    _homeDirectory = Platform.environment['HOME'] ?? '';
    registerTool(_listKeysTool, _listKeys);
    registerTool(_getKeyTool, _getKey);
    addMarkdownDocsResources();
  }

  late final MCPLoggingHandler _mcpLoggingHandler;
  late final String _homeDirectory;

  static const _kDefaultRootDomain = 'root.atsign.org';
  static const _kDefaultRootPort = 64;
  static const _kDefaultNamespace = '';
  static final _kDefaultSchemaProperties = {
    'atsign': Schema.string(
      description: 'The atsign to list keys for',
    ),
    'rootDomain': Schema.string(
      description: 'The root domain to use',
    ),
    'rootPort': Schema.int(
      description: 'The root port to use',
    ),
    'namespace': Schema.string(
      description: 'The namespace to use',
    ),
  };
  static const _kDefaultRequiredSchemaProperties = ['atsign'];

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
    MarkdownDoc(
      filename: 'at_sign.md',
      title: 'atSign',
      description: 'A unique identifier which serves as the address of the atServer',
      uri: Uri.parse('https://docs.atsign.com/core/atsign.md'),
    ),
    MarkdownDoc(
      filename: 'at_record.md',
      title: 'atRecord',
      description: 'The format atServers use to store and share data.',
      uri: Uri.parse('https://docs.atsign.com/core/atrecord.md'),
    ),
    MarkdownDoc(
      filename: 'infrastructure.md',
      title: 'Infrastructure',
      description: 'How we scale and provide resilience.',
      uri: Uri.parse('https://docs.atsign.com/infrastructure.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_get_started.md',
      title: 'atSDK Get Started',
      description: 'Setup the atSDK for your preferred language',
      uri: Uri.parse('https://docs.atsign.com/sdk/get-started.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_authentication.md',
      title: 'atSDK Authentication',
      description: 'How to authenticate to an atServer',
      uri: Uri.parse('https://docs.atsign.com/sdk/onboarding.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_atKey_reference.md',
      title: 'atSDK atKey Reference',
      description: 'Learn how to create atKeys for your chosen platform',
      uri: Uri.parse('https://docs.atsign.com/sdk/atid-reference.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_crud_operations.md',
      title: 'atSDK CRUD Operations',
      description: 'How to do basic CRUD operations on an atServer',
      uri: Uri.parse('https://docs.atsign.com/sdk/crud-operations.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_notifications.md',
      title: 'atSDK Notifications',
      description: 'How to send and receive real-time messages',
      uri: Uri.parse('https://docs.atsign.com/sdk/events.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_synchronization.md',
      title: 'atSDK Synchronization',
      description: 'How to synchronize data',
      uri: Uri.parse('https://docs.atsign.com/sdk/synchronization/synchronization.md'),
    ),
    MarkdownDoc(
      filename: 'at_sdk_connection_hooks.md',
      title: 'atSDK Connection Hooks',
      description: 'How to handle connection events',
      uri: Uri.parse('https://docs.atsign.com/sdk/synchronization/connection-hooks.md'),
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
    description: r'''
Returns a list of the keys on the given atsign's server.
Key structure: [cached:]<visibility scope>:<record ID><owner’s atSign>
Cached: A marker for whether it is a cached key or not.
Visibility Scope: A marker for who has access to the key.
Record ID: A unique string used to represent the atRecord.
Owner's atSign: The owner (i.e. creator's) atSign for that particular atRecord. The shared by atSign of an atRecord is synonymous to the owner atSign of an atRecord.
''',
    inputSchema: Schema.object(
      properties: {
        ..._kDefaultSchemaProperties,
        'regexp': Schema.string(
          description: r'''
Optional regular expression to filter keys. E.g. `^.*\.wavi@.+$` Returns all atKeys which end with ".wavi" in the record identifier part
''',
        ),
        'sharedBy': Schema.string(
          description: 'Optional atsign to filter keys shared by',
        ),
        'sharedWith': Schema.string(
          description: 'Optional atsign to filter keys shared with',
        ),
      },
      required: [
        ..._kDefaultRequiredSchemaProperties,
      ],
    ),
  );

  Future<CallToolResult> _listKeys(CallToolRequest request) async {
    // Validate input arguments
    final args = request.arguments;
    final rootDomain = (args?['rootDomain'] as String?) ?? _kDefaultRootDomain;
    final rootPort = (args?['rootPort'] as int?) ?? _kDefaultRootPort;
    final namespace = (args?['namespace'] as String?) ?? _kDefaultNamespace;

    var sharedWith = (args?['sharedWith'] as String?);
    var sharedBy = (args?['sharedBy'] as String?);
    var regexp = (args?['regexp'] as String?);
    if (sharedWith == '') {
      sharedWith = null;
    }
    if (sharedBy == '') {
      sharedBy = null;
    }
    if (regexp == '') {
      regexp = null;
    }

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
      homeDirectory: _homeDirectory,
      rootPort: rootPort,
      rootDomain: rootDomain,
      namespace: namespace,
      atsign: atsign,
    );
    log(LoggingLevel.debug, 'AtClient initialized');

    log(LoggingLevel.debug, 'Fetching keys');
    final keys = await client.getAtKeys(
      regex: regexp,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
    );
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
        ..._kDefaultSchemaProperties,
        'key': Schema.string(
          description: 'The key to get',
        ),
      },
      required: [
        ..._kDefaultRequiredSchemaProperties,
        'key',
      ],
    ),
  );

  Future<CallToolResult> _getKey(CallToolRequest request) async {
    // Validate input arguments
    final args = request.arguments;
    final rootDomain = (args?['rootDomain'] as String?) ?? _kDefaultRootDomain;
    final rootPort = (args?['rootPort'] as int?) ?? _kDefaultRootPort;
    final namespace = (args?['namespace'] as String?) ?? _kDefaultNamespace;
    final key = (args?['key'] as String?);

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

    if (key == null || key.isEmpty) {
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
      homeDirectory: _homeDirectory,
      rootDomain: rootDomain,
      rootPort: rootPort,
      namespace: namespace,
      atsign: atsign,
    );
    log(LoggingLevel.debug, 'AtClient initialized');

    log(LoggingLevel.debug, 'Fetching key');
    late final AtKey atKey;
    try {
      atKey = AtKey.fromString(key);
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
    final atValue = await client.get(atKey);
    final isBinary = atValue.metadata?.isBinary ?? false;
    if (isBinary) {
      log(LoggingLevel.warning, 'Key contains binary data');
      return CallToolResult(
        content: [
          TextContent(
            text: 'Binary data is not supported at this time',
          ),
        ],
        isError: true,
      );
    } else {
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
