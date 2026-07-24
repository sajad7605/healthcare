import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/models.dart';

class EducationalService {
  final ApiClient apiClient;
  final String defaultVersion;

  EducationalService(
    this.apiClient, {
    this.defaultVersion = ApiEndpoints.defaultVersion,
  });

  Future<List<Video>> listVideos({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.videos(v));
    return (response.data as List)
        .map((video) => Video.fromJson(video as Map<String, dynamic>))
        .toList();
  }

  Future<List<Tip>> listTips({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.tips(v));
    return (response.data as List)
        .map((tip) => Tip.fromJson(tip as Map<String, dynamic>))
        .toList();
  }
}
