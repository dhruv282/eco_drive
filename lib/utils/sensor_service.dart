import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _userAccelSub;

  final _accelController = StreamController<AccelerometerEvent>.broadcast();
  final _gyroController = StreamController<GyroscopeEvent>.broadcast();
  final _userAccelController = StreamController<UserAccelerometerEvent>.broadcast();

  Stream<AccelerometerEvent> get accel$ => _accelController.stream;
  Stream<GyroscopeEvent> get gyro$ => _gyroController.stream;
  Stream<UserAccelerometerEvent> get userAccel$ => _userAccelController.stream;

  void start() {
    _accelSub = accelerometerEventStream().listen(_accelController.add);
    _gyroSub = gyroscopeEventStream().listen(_gyroController.add);
    _userAccelSub = userAccelerometerEventStream().listen(_userAccelController.add);
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _userAccelSub?.cancel();
  }

  void dispose() {
    stop();
    _accelController.close();
    _gyroController.close();
    _userAccelController.close();
  }
}
