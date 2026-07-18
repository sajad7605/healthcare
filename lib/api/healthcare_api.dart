import 'core/api_client.dart';
import 'models/models.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'services/children_service.dart';
import 'services/educational_service.dart';

export 'core/api_client.dart';
export 'core/api_endpoints.dart';
export 'core/api_exception.dart';
export 'models/models.dart';
export 'services/auth_service.dart';
export 'services/account_service.dart';
export 'services/children_service.dart';
export 'services/educational_service.dart';

class HealthcareApi {
  // Global singleton instance for easy app-wide access
  static final ApiClient _defaultClient = ApiClient(baseUrl: 'https://h.ghahremansalamat.ir');
  //static final ApiClient _defaultClient = ApiClient(baseUrl: 'http://127.0.0.1:5158');

  static final HealthcareApi instance = HealthcareApi(apiClient: _defaultClient);

  final ApiClient apiClient;
  
  late final AuthService auth;
  late final AccountService account;
  late final ChildrenService children;
  late final EducationalService educational;

  // Active Session Cache
  ParentProfile? currentParent;
  ChildProfile? currentChild;
  List<ChildProfile>? childrenList;

  HealthcareApi({
    required this.apiClient,
    String defaultVersion = '1',
  }) {
    auth = AuthService(apiClient, defaultVersion: defaultVersion);
    account = AccountService(apiClient, defaultVersion: defaultVersion);
    children = ChildrenService(apiClient, defaultVersion: defaultVersion);
    educational = EducationalService(apiClient, defaultVersion: defaultVersion);
  }
}
