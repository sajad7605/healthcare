import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare/main.dart';
import 'package:healthcare/api/healthcare_api.dart';

class MockAppConfigService extends AppConfigService {
  MockAppConfigService(super.apiClient);

  @override
  Future<AppConfig> getConfig({String? version}) async {
    return AppConfig(
      splashMessage: 'همدم دندون‌ها باش!',
      motd: 'خوش آمدید',
      appVersion: '1.0.0',
      supportPhone: '09123456789',
    );
  }
}

class MockHealthcareApi extends HealthcareApi {
  MockHealthcareApi() : super(apiClient: ApiClient(baseUrl: ''));
}

void main() {
  setUp(() {
    HealthcareApi.instance = MockHealthcareApi();
  });

  testWidgets('HealthcareApp smoke test', (WidgetTester tester) async {
    
    await tester.pumpWidget(const HealthcareApp());

    expect(find.text('دندون یار کوچولو'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
