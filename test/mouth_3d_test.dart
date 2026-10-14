import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test rendering Cube with mouth_full.obj', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: cube.Cube(
                interactive: false,
                onSceneCreated: (cube.Scene scene) {
                  final mouth = cube.Object(
                    fileName: 'assets/models/mouth.obj',
                    isAsset: false,
                    lighting: false,
                    backfaceCulling: false,
                  );
                  scene.world.add(mouth);
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Wait for async loadObj and render
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

  });
}
