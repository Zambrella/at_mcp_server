import 'package:at_client/at_client.dart';
import 'package:at_mcp_server/mcp_logging_handler.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

Future<AtClient> initAtClient({
  required MCPLoggingHandler mcpLoggingHandler,
  required String rootDomain,
  required int rootPort,
  required String? namespace,
  required String atsign,
  required String homeDirectory,
}) async {
  final keysPath = '$homeDirectory/.atsign/keys/${atsign}_key.atKeys';

  AtSignLogger.defaultLoggingHandler = mcpLoggingHandler;

  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    ..hiveStoragePath = '$homeDirectory/.atsign/storage'
    ..namespace = namespace ?? ''
    ..downloadPath = '$homeDirectory/.atsign/files'
    ..isLocalStoreRequired = true
    ..commitLogPath = '$homeDirectory/.atsign/storage/commitLog'
    ..rootDomain = rootDomain
    ..rootPort = rootPort
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
