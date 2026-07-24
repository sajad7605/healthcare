import 'dart:io';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/models.dart';

class ChildrenService {
  final ApiClient apiClient;
  final String defaultVersion;

  ChildrenService(
    this.apiClient, {
    this.defaultVersion = ApiEndpoints.defaultVersion,
  });

  Future<List<ChildProfile>> listChildren({
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.children(v));
    return (response.data as List)
        .map((c) => ChildProfile.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ChildProfile> addChild(
    CreateChildRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.children(v),
      data: request.toJson(),
    );
    return ChildProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChildProfile> updateChild(
    String childId,
    UpdateChildRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.put(
      ApiEndpoints.childDetail(v, childId),
      data: request.toJson(),
    );
    return ChildProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteChild(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.delete(ApiEndpoints.childDetail(v, childId));
  }

  Future<ChildDashboardData> getChildDashboard(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childDashboard(v, childId));
    return ChildDashboardData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ActivityLogResponse>> getActivityLogs(
    String childId, {
    int? limit,
    int? offset,
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(
      ApiEndpoints.childActivities(v, childId),
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    return (response.data as List)
        .map((a) => ActivityLogResponse.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityLogResponse> logActivity(
    String childId,
    ActivityLogRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.childActivities(v, childId),
      data: request.toJson(),
    );
    return ActivityLogResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<KidStats> getChildStats(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childStats(v, childId));
    return KidStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NotificationSettings> getReminderSettings(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childSettings(v, childId));
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NotificationSettings> updateReminderSettings(
    String childId,
    NotificationSettings settings, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.put(
      ApiEndpoints.childSettings(v, childId),
      data: settings.toJson(),
    );
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Badge>> getUnlockedBadges(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childBadges(v, childId));
    return (response.data as List)
        .map((b) => Badge.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeethPhoto>> getTeethPhotos(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childPhotos(v, childId));
    return (response.data as List)
        .map((p) => TeethPhoto.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<TeethPhoto> uploadToothPhoto(
    String childId, {
    required File photoFile,
    String? title,
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.postMultipart(
      ApiEndpoints.childPhotos(v, childId),
      data: {
        'Photo': photoFile,
        if (title != null) 'Title': title,
      },
    );
    return TeethPhoto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteToothPhoto(
    String childId,
    String photoId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    await apiClient.delete(ApiEndpoints.childPhotoDetail(v, childId, photoId));
  }

  Future<List<Goal>> listChildGoals(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childGoals(v, childId));
    return (response.data as List)
        .map((g) => Goal.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<Goal> createCustomGoal(
    String childId,
    CreateGoalRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.createGoal(v, childId),
      data: request.toJson(),
    );
    return Goal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Reward>> listChildRewards(
    String childId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.get(ApiEndpoints.childRewards(v, childId));
    return (response.data as List)
        .map((r) => Reward.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Reward> createReward(
    String childId,
    CreateRewardRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.createReward(v, childId),
      data: request.toJson(),
    );
    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RewardClaim> claimReward(
    String childId,
    ClaimRewardRequest request, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(
      ApiEndpoints.claimReward(v, childId),
      data: request.toJson(),
    );
    return RewardClaim.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RewardClaim> approveRewardClaim(
    String claimId, {
    String? version,
  }) async {
    final v = version ?? defaultVersion;
    final response = await apiClient.post(ApiEndpoints.approveRewardClaim(v, claimId));
    return RewardClaim.fromJson(response.data as Map<String, dynamic>);
  }
}
