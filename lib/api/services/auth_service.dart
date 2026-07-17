import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/models.dart';

class AuthService {
  final ApiClient apiClient;
  final String defaultVersion;

  AuthService(
    this.apiClient, {
    this.defaultVersion = ApiEndpoints.defaultVersion,
  });

  /// Register parent and child
  Future<ParentRegisterResponse> registerParent(
    ParentRegisterRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.registerParent(v),
      data: request.toJson(),
    );
    return ParentRegisterResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Login parent or child
  Future<LoginResponse> loginUser(
    LoginRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.loginParent(v),
      data: request.toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    
    // Automatically configure the token in the ApiClient on successful login
    if (loginResponse.token.isNotEmpty) {
      apiClient.setAuthToken(loginResponse.token);
    }
    
    return loginResponse;
  }

  /// Retrieve the parent profile
  Future<ParentProfile> getParentProfile({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(
      ApiEndpoints.getParentProfile(v),
    );
    return ParentProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
