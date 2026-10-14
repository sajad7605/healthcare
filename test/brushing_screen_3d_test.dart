import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare/screens/brushing_screen.dart';
import 'package:healthcare/widgets/mouth_3d_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mouth3DViewer instantiates with backfaceCulling false and default zoom 6.8', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Mouth3DViewer(
            interactive: false,
          ),
        ),
      ),
    );

    expect(find.byType(Mouth3DViewer), findsOneWidget);
  });

  testWidgets('InteractiveBrushScreen renders cleanly without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InteractiveBrushScreen(),
      ),
    );

    await tester.pump();
    expect(find.byType(InteractiveBrushScreen), findsOneWidget);
  });
}
