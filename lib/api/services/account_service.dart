import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/models.dart';

class AccountService {
  final ApiClient apiClient;
  final String defaultVersion;

  AccountService(
    this.apiClient, {
    this.defaultVersion = ApiEndpoints.defaultVersion,
  });

  // --- Account Endpoints ---

  Future<void> loginAccount(
    TokenRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.post(
      ApiEndpoints.login(v),
      data: request.toJson(),
    );
  }

  Future<void> createInitialUser(
    CreateInitialUserRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.post(
      ApiEndpoints.createInitialUser(v),
      data: request.toJson(),
    );
  }

  Future<dynamic> getProfile({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(
      ApiEndpoints.getAccountProfile(v),
    );
    return response.data;
  }

  Future<void> updateProfile(
    UpdateProfileRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.post(
      ApiEndpoints.updateAccountProfile(v),
      data: request.toJson(),
    );
  }

  // --- Role Endpoints ---

  Future<List<RoleSelectDto>> getAllRoles({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.getAllRoles(v));
    return (response.data as List)
        .map((r) => RoleSelectDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<UserSelectDtoPaginated> getRoleUsersList({
    int? pageNumber,
    int? pageSize,
    String? role,
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(
      ApiEndpoints.getRoleUsersList(v),
      queryParameters: {
        if (pageNumber != null) 'PageNumber': pageNumber,
        if (pageSize != null) 'PageSize': pageSize,
        if (role != null) 'role': role,
      },
    );
    return UserSelectDtoPaginated.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleSelectDtoApiResult> getRoleById(
    String id, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.getRoleById(v, id));
    return RoleSelectDtoApiResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleSelectDtoApiResult> createRole(
    RoleDto request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.createRole(v),
      data: request.toJson(),
    );
    return RoleSelectDtoApiResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleSelectDtoApiResult> updateRole(
    String id,
    RoleDto request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.put(
      ApiEndpoints.updateRole(v, id),
      data: request.toJson(),
    );
    return RoleSelectDtoApiResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResult> deleteRole(
    String id, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.delete(ApiEndpoints.deleteRole(v, id));
    return ApiResult.fromJson(response.data as Map<String, dynamic>);
  }

  // --- UserManager Endpoints ---

  Future<void> createUser(
    UserDto request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.post(
      ApiEndpoints.createUser(v),
      data: request.toJson(),
    );
  }

  Future<UserSelectDtoPaginated> getUsers({
    int? userId,
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(
      ApiEndpoints.getUsers(v),
      queryParameters: {
        if (userId != null) 'userId': userId,
      },
    );
    return UserSelectDtoPaginated.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(
    int userId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.delete(
      ApiEndpoints.deleteUser(v),
      queryParameters: {'userId': userId},
    );
  }

  Future<void> addRoleToUser(
    AddUserRoleDto request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.post(
      ApiEndpoints.addRoleToUser(v),
      data: request.toJson(),
    );
  }
}
