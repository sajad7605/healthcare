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

  Future<ParentRegisterResponse> registerParent(
    ParentRegisterRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.registerParent(v),
      data: request.toJson(),
    );
    final registerResponse = ParentRegisterResponse.fromJson(response.data as Map<String, dynamic>);
    
    if (registerResponse.token.isNotEmpty) {
      apiClient.setAuthToken(registerResponse.token);
    }
    
    return registerResponse;
  }

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
    
    if (loginResponse.token.isNotEmpty) {
      apiClient.setAuthToken(loginResponse.token);
    }
    
    return loginResponse;
  }

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
