import 'dart:async';
import 'dart:math' as math;

import 'package:eco_drive/data/vehicle_state.dart';
import 'package:eco_drive/utils/gps_service.dart';
import 'package:eco_drive/utils/sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart';

class SensorFusionEngine {
  final SensorService sensors;
  final GpsService gps;

  static const double _yawAlpha = 0.98;
  static const double gravityAlpha = 0.9;

  Vector3 _gravity = Vector3.zero();
  
  double _yaw = 0.0;
  double _lastAccelX = 0.0;
  
  DateTime? _lastTs;

  final _vehicleStateCtrl = StreamController<VehicleState>.broadcast();
  Stream<VehicleState> get vehicleState$ => _vehicleStateCtrl.stream;

  SensorFusionEngine(this.sensors, this.gps);

  void start() {
    sensors.accel$.listen(_onAccel);
    sensors.gyro$.listen(_onGyro);
    sensors.userAccel$.listen(_onUserAccel);
  }

  void _onAccel(AccelerometerEvent e) {
    _gravity = Vector3(e.x, e.y, e.z).normalized();
  }

  void _onGyro(GyroscopeEvent e) {
    final dt = _deltaT();
    _yaw += e.z * dt;

    // Gentle correction toward GPS heading
    final gpsYaw = gps.heading;
    _yaw = _yaw * _yawAlpha + gpsYaw * (1 - _yawAlpha);
  }

  void _onUserAccel(UserAccelerometerEvent e) {
    final now = DateTime.now();
    final dt = _deltaT(now);

    // Linear acceleration in phone frame
    final phoneAccel = Vector3(e.x, e.y, e.z);

    // Rotate by gravity (tilt compensation)
    final tiltCorrected = _removeGravity(phoneAccel);

    // Rotate by yaw (vehicle heading)
    final vehicleAccel = _rotateYaw(tiltCorrected, _yaw);

    final ax = vehicleAccel.x;
    final ay = vehicleAccel.y;
    final jerk = (ax - _lastAccelX) / dt;

    _lastAccelX = ax;

    _vehicleStateCtrl.add(
      VehicleState(
        speed: gps.speed, // injected from GPS service
        accelLong: ax,
        accelLat: ay,
        jerk: jerk,
        dt: dt,
      ),
    );
  }

  double _deltaT([DateTime? now]) {
    final t = now ?? DateTime.now();
    final dt =
        _lastTs == null ? 0.02 : t.difference(_lastTs!).inMilliseconds / 1000.0;
    _lastTs = t;
    return dt;
  }

  Vector3 _removeGravity(Vector3 accel) {
    // World "up"
    final worldUp = Vector3(0, 0, 1);

    // Axis-angle rotation from gravity → world up
    final axis = _gravity.cross(worldUp);
    final axisLen2 = axis.length2;
    final angle = math.acos(_gravity.dot(worldUp).clamp(-1.0, 1.0));

    // If phone is already flat
    if (axisLen2 < 1e-6 || angle.isNaN) {
      return accel;
    }

    final q = Quaternion.axisAngle(axis.normalized(), angle);
    final rotation = q.asRotationMatrix();

    return rotation.transform(accel);
  }

  Vector3 _rotateYaw(Vector3 accel, double yaw) {
    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);

    final x = accel.x * cosYaw - accel.y * sinYaw;
    final y = accel.x * sinYaw + accel.y * cosYaw;

    return Vector3(x, y, accel.z);
  }
}
