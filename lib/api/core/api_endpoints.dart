class ApiEndpoints {
  static const String defaultVersion = '1';

  // --- Auth & Account ---
  static String login(String version) => '/api/v$version/Account/Login';
  static String createInitialUser(String version) => '/api/v$version/Account/CreateInitialUser';
  static String getAccountProfile(String version) => '/api/v$version/Account/GetProfile';
  static String updateAccountProfile(String version) => '/api/v$version/Account/UpdateProfile';

  // --- Parent Authentication ---
  static String registerParent(String version) => '/api/v$version/auth/register';
  static String loginParent(String version) => '/api/v$version/auth/login';
  static String getParentProfile(String version) => '/api/v$version/parent/profile';

  // --- Children Management ---
  static String children(String version) => '/api/v$version/parent/children';
  static String childDetail(String version, String childId) => '/api/v$version/parent/children/$childId';
  static String childDashboard(String version, String childId) => '/api/v$version/kids/$childId/dashboard';
  static String childSettings(String version, String childId) => '/api/v$version/kids/$childId/settings';
  static String childBadges(String version, String childId) => '/api/v$version/kids/$childId/badges';

  // --- Activities ---
  static String childActivities(String version, String childId) => '/api/v$version/kids/$childId/activities';
  static String childStats(String version, String childId) => '/api/v$version/kids/$childId/stats';

  // --- Photos ---
  static String childPhotos(String version, String childId) => '/api/v$version/kids/$childId/photos';
  static String childPhotoDetail(String version, String childId, String photoId) => '/api/v$version/kids/$childId/photos/$photoId';

  // --- Educational Content ---
  static String videos(String version) => '/api/v$version/videos';
  static String tips(String version) => '/api/v$version/tips';
  static String config(String version) => '/api/v$version/config';

  // --- Goals ---
  static String childGoals(String version, String childId) => '/api/v$version/kids/$childId/goals';
  static String createGoal(String version, String childId) => '/api/v$version/parent/children/$childId/goals';

  // --- Rewards ---
  static String childRewards(String version, String childId) => '/api/v$version/kids/$childId/rewards';
  static String createReward(String version, String childId) => '/api/v$version/parent/children/$childId/rewards';
  static String claimReward(String version, String childId) => '/api/v$version/kids/$childId/rewards/claim';
  static String approveRewardClaim(String version, String claimId) => '/api/v$version/parent/rewards/claims/$claimId/approve';

  // --- Role Management ---
  static String getAllRoles(String version) => '/api/v$version/Role/GetAllRoles';
  static String getRoleUsersList(String version) => '/api/v$version/Role/GetRoleUsersList';
  static String getRoleById(String version, String id) => '/api/v$version/Role/Get/$id';
  static String createRole(String version) => '/api/v$version/Role/Create';
  static String updateRole(String version, String id) => '/api/v$version/Role/Update/$id';
  static String deleteRole(String version, String id) => '/api/v$version/Role/Delete/$id';

  // --- User Manager ---
  static String createUser(String version) => '/api/v$version/UserManager/CreateUser';
  static String getUsers(String version) => '/api/v$version/UserManager';
  static String deleteUser(String version) => '/api/v$version/UserManager/DeleteUser';
  static String addRoleToUser(String version) => '/api/v$version/UserManager/AddRoleToUser';
}
