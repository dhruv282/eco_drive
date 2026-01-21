import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class GpsService {
  StreamSubscription? _sub;
  final _posCtrl = StreamController<Position>.broadcast();

  Stream<Position> get position$ => _posCtrl.stream;
  double speed = 0.0; // m/s
  double heading = 0.0; // radians

  void start() {
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    ).listen((p) {
      speed = p.speed;
      heading = p.heading * math.pi / 180.0;
      _posCtrl.add(p);
    });
  }

  void stop() => _sub?.cancel();

  void dispose() {
    _sub?.cancel();
    _posCtrl.close();
  }
}
