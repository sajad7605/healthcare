// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:convert';
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

Map<String, dynamic> projectStage(
    List<Vector3> verts, List<List<int>> faces, double pitchDeg, double yawDeg, double zoom) {
  final proj = getCubeProjection(zoom, 1000.0, 1000.0);
  final view = getCubeView();
  final model = getCubeModel(pitchDeg, yawDeg);
  final transform = proj * view * model;

  final screenVerts = <List<double>>[];
  for (final v in verts) {
    final v4 = Vector4(v.x, v.y, v.z, 1.0)..applyMatrix4(transform);
    final ndcX = v4.x / v4.w;
    final ndcY = v4.y / v4.w;
    final ndcZ = v4.z / v4.w;
    // screen 0..1
    final sx = (1.0 + ndcX) / 2.0;
    final sy = (1.0 - ndcY) / 2.0;
    screenVerts.add([sx, sy, ndcZ]);
  }

  return {
    'verts': screenVerts,
    'faces': faces,
  };
}

void main() {
  test('Dump stage projections to JSON', () async {
    final file = File('assets/models/mouth.obj');
    final lines = await file.readAsLines();
    final List<Vector3> verts = [];
    final List<List<int>> faces = [];
    for (final line in lines) {
      if (line.startsWith('v ')) {
        final p = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        verts.add(Vector3(double.parse(p[1]), double.parse(p[2]), double.parse(p[3])));
      } else if (line.startsWith('f ')) {
        final p = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        int v0 = int.parse(p[1].split('/')[0]) - 1;
        int v1 = int.parse(p[2].split('/')[0]) - 1;
        int v2 = int.parse(p[3].split('/')[0]) - 1;
        faces.add([v0, v1, v2]);
      }
    }

    // Stages to dump:
    // 1: upperFrontOuter (yaw=0, pitch=4.6)
    // 4: upperLeftOuter (yaw=25.8, pitch=4.6) AND test (yaw=-25.8, pitch=4.6)
    // 7: upperRightOuter (yaw=-25.8, pitch=4.6) AND test (yaw=25.8, pitch=4.6)
    // 10: lowerFrontOuter (yaw=0, pitch=-4.6)
    // 12: lowerFrontChewing (yaw=0, pitch=-11.5)
    // 13: lowerLeftOuter (yaw=25.8, pitch=-4.6)
    // 16: lowerRightOuter (yaw=-25.8, pitch=-4.6)
    final stages = <String, Map<String, dynamic>>{
      'step1_upperFrontOuter_yaw0': projectStage(verts, faces, 4.6, 0.0, 6.8),
      'step4_upperLeftOuter_yawPos25': projectStage(verts, faces, 4.6, 25.8, 6.8),
      'step4_upperLeftOuter_yawNeg25': projectStage(verts, faces, 4.6, -25.8, 6.8),
      'step7_upperRightOuter_yawNeg25': projectStage(verts, faces, 4.6, -25.8, 6.8),
      'step7_upperRightOuter_yawPos25': projectStage(verts, faces, 4.6, 25.8, 6.8),
      'step10_lowerFrontOuter_yaw0': projectStage(verts, faces, -4.6, 0.0, 6.8),
      'step12_lowerFrontChewing_yaw0': projectStage(verts, faces, -11.5, 0.0, 6.8),
      'step13_lowerLeftOuter_yawPos25': projectStage(verts, faces, -4.6, 25.8, 6.8),
      'step16_lowerRightOuter_yawNeg25': projectStage(verts, faces, -4.6, -25.8, 6.8),
    };

    final outFile = File('/home/sajad/.gemini/antigravity-ide/brain/af39618c-4dcd-4769-ad43-ff69f0d8d676/scratch/projections.json');
    await outFile.writeAsString(jsonEncode(stages));
    print('Wrote projections to ${outFile.path}');
  });
}
