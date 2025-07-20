import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_mcp_server/mcp_logging_handler.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

// TODO: Add the option to pass in root port.
Future<AtClient> initAtClient({
  required MCPLoggingHandler mcpLoggingHandler,
  required String rootDomain,
  required String namespace,
  required String atsign,
}) async {
  // TODO: Could pass in home as an argument because MCP client does pass in HOME environment variable
  final homeDirectory = Platform.environment['HOME'];
  final keysPath = '$homeDirectory/.atsign/keys/@${atsign}_key.atKeys';

  AtSignLogger.defaultLoggingHandler = mcpLoggingHandler;

  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    ..hiveStoragePath = '$homeDirectory/.$namespace/storage'
    ..namespace = namespace
    ..downloadPath = '$homeDirectory/.$namespace/files'
    ..isLocalStoreRequired = true
    ..commitLogPath = '$homeDirectory/.$namespace/storage/commitLog'
    ..rootDomain = rootDomain
    ..fetchOfflineNotifications = true
    ..atKeysFilePath = keysPath;

  AtOnboardingService onboardingService = AtOnboardingServiceImpl(
    atsign,
    atOnboardingConfig,
  );

  final onboardingResult = await onboardingService.authenticate();

  if (!onboardingResult) {
    throw Exception('Failed to authenticate');
  }

  final atClient = AtClientManager.getInstance().atClient;

  return atClient;
}
