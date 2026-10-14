// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

Matrix4 getCubeProjection(double zoom, double width, double height) {
  const double near = 0.1;
  const double far = 1000.0;
  const double fov = 60.0;
  final double top = near * math.tan(radians(fov) / 2.0) / zoom;
  final double bottom = -top;
  final double aspectRatio = width / height;
  final double right = top * aspectRatio;
  final double left = -right;
  return makeFrustumMatrix(left, right, bottom, top, near, far);
}

Matrix4 getCubeView() {
  final camPos = Vector3(0.0, 0.0, -10.0);
  final camTarget = Vector3(0.0, 0.0, 0.0);
  final camUp = Vector3(0.0, 1.0, 0.0);
  return makeViewMatrix(camPos, camTarget, camUp);
}

Matrix4 getCubeModel(double pitchDeg, double yawDeg) {
  return Matrix4.compose(
    Vector3.zero(),
    Quaternion.euler(radians(yawDeg), radians(pitchDeg), 0.0),
    Vector3.all(1.0),
  );
}

Vector2 projectVertex(Vector3 v, double pitchDeg, double yawDeg, double zoom) {
  final proj = getCubeProjection(zoom, 100.0, 100.0);
  final view = getCubeView();
  final model = getCubeModel(pitchDeg, yawDeg);
  final transform = proj * view * model;

  final v4 = Vector4(v.x, v.y, v.z, 1.0)..applyMatrix4(transform);
  final ndcX = v4.x / v4.w;
  final ndcY = v4.y / v4.w;

  final normX = (1.0 + ndcX) / 2.0;
  final normY = (1.0 - ndcY) / 2.0;
  return Vector2(normX, normY);
}

void main() {
  test('Detailed dental landmark tracking', () async {
    final file = File('assets/models/mouth.obj');
    final lines = await file.readAsLines();
    final List<Vector3> verts = [];
    for (final line in lines) {
      if (line.startsWith('v ')) {
        final p = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        verts.add(Vector3(double.parse(p[1]), double.parse(p[2]), double.parse(p[3])));
      }
    }

    // Upper Left molars/premolars (remember screen left has projected X < 0.5):
    // At yaw = 0, which verts have projected X < 0.4 and Y in upper jaw (0.2..0.5)?
    final upperLeftTeeth = <Vector3>[];
    final upperRightTeeth = <Vector3>[];
    final lowerLeftTeeth = <Vector3>[];
    final lowerRightTeeth = <Vector3>[];

    for (final v in verts) {
      final s = projectVertex(v, 0, 0, 6.8);
      // Only front/visible facing surfaces
      if (v.z < -0.2) {
        if (s.y > 0.20 && s.y < 0.50) { // Upper
          if (s.x < 0.40) upperLeftTeeth.add(v);
          if (s.x > 0.60) upperRightTeeth.add(v);
        } else if (s.y > 0.52 && s.y < 0.82) { // Lower
          if (s.x < 0.40) lowerLeftTeeth.add(v);
          if (s.x > 0.60) lowerRightTeeth.add(v);
        }
      }
    }

    print('Upper Left teeth count: ${upperLeftTeeth.length}');
    print('Upper Right teeth count: ${upperRightTeeth.length}');
    print('Lower Left teeth count: ${lowerLeftTeeth.length}');
    print('Lower Right teeth count: ${lowerRightTeeth.length}');

    // Now test what happens to upper left teeth when yaw = -30 vs yaw = +30:
    print('\n--- Upper Left teeth at yaw = -30 (yawDeg = -30) ---');
    for (final v in upperLeftTeeth.take(4)) {
      final s = projectVertex(v, 0, -30, 6.8);
      print('v($v) => (${s.x.toStringAsFixed(3)}, ${s.y.toStringAsFixed(3)})');
    }

    print('\n--- Upper Left teeth at yaw = +30 (yawDeg = +30) ---');
    for (final v in upperLeftTeeth.take(4)) {
      final s = projectVertex(v, 0, 30, 6.8);
      print('v($v) => (${s.x.toStringAsFixed(3)}, ${s.y.toStringAsFixed(3)})');
    }

    print('\n--- Upper Right teeth at yaw = -30 (yawDeg = -30) ---');
    for (final v in upperRightTeeth.take(4)) {
      final s = projectVertex(v, 0, -30, 6.8);
      print('v($v) => (${s.x.toStringAsFixed(3)}, ${s.y.toStringAsFixed(3)})');
    }

    print('\n--- Upper Right teeth at yaw = +30 (yawDeg = +30) ---');
    for (final v in upperRightTeeth.take(4)) {
      final s = projectVertex(v, 0, 30, 6.8);
      print('v($v) => (${s.x.toStringAsFixed(3)}, ${s.y.toStringAsFixed(3)})');
    }
  });
}
