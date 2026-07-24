import 'core/api_client.dart';
import 'models/models.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'services/children_service.dart';
import 'services/educational_service.dart';
import 'services/app_config_service.dart';

export 'core/api_client.dart';
export 'core/api_endpoints.dart';
export 'core/api_exception.dart';
export 'models/models.dart';
export 'services/auth_service.dart';
export 'services/account_service.dart';
export 'services/children_service.dart';
export 'services/educational_service.dart';
export 'services/app_config_service.dart';
export 'services/session_manager.dart';

class HealthcareApi {
  
  static final ApiClient _defaultClient = ApiClient(baseUrl: 'https://h.ghahremansalamat.ir');
  
  static HealthcareApi instance = HealthcareApi(apiClient: _defaultClient);

  final ApiClient apiClient;
  
  late final AuthService auth;
  late final AccountService account;
  late final ChildrenService children;
  late final EducationalService educational;
  late final AppConfigService config;

  ParentProfile? currentParent;
  ChildProfile? currentChild;
  List<ChildProfile>? childrenList;
  AppConfig? activeConfig;

  HealthcareApi({
    required this.apiClient,
    String defaultVersion = '1',
  }) {
    auth = AuthService(apiClient, defaultVersion: defaultVersion);
    account = AccountService(apiClient, defaultVersion: defaultVersion);
    children = ChildrenService(apiClient, defaultVersion: defaultVersion);
    educational = EducationalService(apiClient, defaultVersion: defaultVersion);
    config = AppConfigService(apiClient, defaultVersion: defaultVersion);
  }
}
