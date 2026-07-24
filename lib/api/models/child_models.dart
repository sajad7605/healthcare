import 'auth_models.dart';

class CreateChildRequest {
  final String childName;
  final int childAge;
  final String? avatarUrl;

  CreateChildRequest({
    required this.childName,
    required this.childAge,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'childAge': childAge,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class UpdateChildRequest {
  final String? childName;
  final int? childAge;
  final String? avatarUrl;

  UpdateChildRequest({
    this.childName,
    this.childAge,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (childName != null) 'childName': childName,
      if (childAge != null) 'childAge': childAge,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class ActivityLogRequest {
  final String activityType; 
  final int durationSeconds;
  final List<String>? completedSteps;

  ActivityLogRequest({
    required this.activityType,
    required this.durationSeconds,
    this.completedSteps,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityType': activityType,
      'durationSeconds': durationSeconds,
      if (completedSteps != null) 'completedSteps': completedSteps,
    };
  }
}

class ActivityLogResponse {
  final String id;
  final String childId;
  final String activityType;
  final int durationSeconds;
  final int starsEarned;
  final DateTime timestamp;

  ActivityLogResponse({
    required this.id,
    required this.childId,
    required this.activityType,
    required this.durationSeconds,
    required this.starsEarned,
    required this.timestamp,
  });

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) {
    return ActivityLogResponse(
      id: json['id'] as String,
      childId: json['childId'] as String,
      activityType: json['activityType'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      starsEarned: json['starsEarned'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class KidStats {
  final String childId;
  final int totalStars;
  final int currentStreakDays;
  final int brushingCount;
  final int flossingCount;
  final int mouthwashCount;
  final bool morningBrushingCompletedToday;
  final bool nightBrushingCompletedToday;

  KidStats({
    required this.childId,
    required this.totalStars,
    required this.currentStreakDays,
    required this.brushingCount,
    required this.flossingCount,
    required this.mouthwashCount,
    required this.morningBrushingCompletedToday,
    required this.nightBrushingCompletedToday,
  });

  factory KidStats.fromJson(Map<String, dynamic> json) {
    return KidStats(
      childId: json['childId'] as String? ?? '',
      totalStars: json['totalStars'] as int? ?? 0,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      brushingCount: json['brushingCount'] as int? ?? 0,
      flossingCount: json['flossingCount'] as int? ?? 0,
      mouthwashCount: json['mouthwashCount'] as int? ?? 0,
      morningBrushingCompletedToday: json['morningBrushingCompletedToday'] as bool? ?? false,
      nightBrushingCompletedToday: json['nightBrushingCompletedToday'] as bool? ?? false,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final int targetCount;
  final int currentProgress;
  final int starsReward;
  final String status; 
  final DateTime? createdAt;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetCount,
    required this.currentProgress,
    required this.starsReward,
    required this.status,
    this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      targetCount: json['targetCount'] as int? ?? 0,
      currentProgress: json['currentProgress'] as int? ?? 0,
      starsReward: json['starsReward'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}

class CreateGoalRequest {
  final String title;
  final String? description;
  final int targetCount;
  final int starsReward;

  CreateGoalRequest({
    required this.title,
    this.description,
    required this.targetCount,
    required this.starsReward,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'targetCount': targetCount,
      'starsReward': starsReward,
    };
  }
}

class Reward {
  final String id;
  final String title;
  final String? description;
  final int starsRequired;
  final String status; 

  Reward({
    required this.id,
    required this.title,
    this.description,
    required this.starsRequired,
    required this.status,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      starsRequired: json['starsRequired'] as int? ?? 0,
      status: json['status'] as String? ?? 'available',
    );
  }
}

class CreateRewardRequest {
  final String title;
  final String? description;
  final int starsRequired;

  CreateRewardRequest({
    required this.title,
    this.description,
    required this.starsRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'starsRequired': starsRequired,
    };
  }
}

class ClaimRewardRequest {
  final String rewardId;

  ClaimRewardRequest({
    required this.rewardId,
  });

  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
    };
  }
}

class RewardClaim {
  final String id;
  final Reward reward;
  final String childId;
  final String status; 
  final DateTime claimedAt;
  final DateTime? approvedAt;

  RewardClaim({
    required this.id,
    required this.reward,
    required this.childId,
    required this.status,
    required this.claimedAt,
    this.approvedAt,
  });

  factory RewardClaim.fromJson(Map<String, dynamic> json) {
    return RewardClaim(
      id: json['id'] as String,
      reward: Reward.fromJson(json['reward'] as Map<String, dynamic>),
      childId: json['childId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      claimedAt: DateTime.parse(json['claimedAt'] as String),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
    );
  }
}

class NotificationSettings {
  final String morningReminderTime; 
  final String nightReminderTime; 
  final bool pushNotificationsEnabled;

  NotificationSettings({
    required this.morningReminderTime,
    required this.nightReminderTime,
    required this.pushNotificationsEnabled,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      morningReminderTime: json['morningReminderTime'] as String? ?? '08:00',
      nightReminderTime: json['nightReminderTime'] as String? ?? '21:00',
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningReminderTime': morningReminderTime,
      'nightReminderTime': nightReminderTime,
      'pushNotificationsEnabled': pushNotificationsEnabled,
    };
  }
}

class Badge {
  final String id;
  final String title;
  final String description;
  final String badgeColor;
  final String toothExpression;
  final DateTime unlockedAt;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeColor,
    required this.toothExpression,
    required this.unlockedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      badgeColor: json['badgeColor'] as String? ?? '#FF7675',
      toothExpression: json['toothExpression'] as String? ?? 'happy',
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
    );
  }
}

class TeethPhoto {
  final String id;
  final String title;
  final String photoUrl;
  final DateTime createdAt;

  TeethPhoto({
    required this.id,
    required this.title,
    required this.photoUrl,
    required this.createdAt,
  });

  factory TeethPhoto.fromJson(Map<String, dynamic> json) {
    
    final dateStr = json['uploadedAt'] as String? ?? json['createdAt'] as String?;
    return TeethPhoto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      createdAt: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
    );
  }
}

class ChildDashboardData {
  final ChildProfile child;
  final KidStats stats;
  final List<Goal> activeGoals;
  final List<Reward> availableRewards;
  final NotificationSettings settings;
  final List<ActivityLogResponse> recentActivities;

  ChildDashboardData({
    required this.child,
    required this.stats,
    required this.activeGoals,
    required this.availableRewards,
    required this.settings,
    required this.recentActivities,
  });

  factory ChildDashboardData.fromJson(Map<String, dynamic> jsonMap) {
    final json = (jsonMap.containsKey('isSuccess') && jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic>)
        ? jsonMap['data'] as Map<String, dynamic>
        : (jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic> ? jsonMap['data'] as Map<String, dynamic> : jsonMap);
    
    final childJson = json['childProfile'] as Map<String, dynamic>? ?? 
                      json['child'] as Map<String, dynamic>? ?? {};
    final settingsJson = json['reminderSettings'] as Map<String, dynamic>? ?? 
                         json['settings'] as Map<String, dynamic>? ?? {};
    return ChildDashboardData(
      child: ChildProfile.fromJson(childJson),
      stats: KidStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      activeGoals: (json['activeGoals'] as List? ?? [])
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList(),
      availableRewards: (json['availableRewards'] as List? ?? [])
          .map((r) => Reward.fromJson(r as Map<String, dynamic>))
          .toList(),
      settings: settingsJson.isNotEmpty 
          ? NotificationSettings.fromJson(settingsJson)
          : NotificationSettings(morningReminderTime: '08:00', nightReminderTime: '21:00', pushNotificationsEnabled: true),
      recentActivities: (json['recentActivities'] as List? ?? [])
          .map((a) => ActivityLogResponse.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
