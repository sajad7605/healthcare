import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/app_config.dart';

class AppConfigService {
  final ApiClient apiClient;
  final String defaultVersion;

  AppConfigService(
    this.apiClient, {
    this.defaultVersion = ApiEndpoints.defaultVersion,
  });

  /// Retrieve general app configurations (Splash Message, MOTD, Support Phone, App Version)
  Future<AppConfig> getConfig({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.config(v));
    return AppConfig.fromJson(response.data as Map<String, dynamic>);
  }
}
