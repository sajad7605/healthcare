import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare/main.dart';

void main() {
  testWidgets('HealthcareApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthcareApp());

    // Verify that onboarding logo/title is present
    expect(find.text('دندون یار'), findsOneWidget);
    expect(find.text('ورود / ثبت نام'), findsOneWidget);
  });
}
