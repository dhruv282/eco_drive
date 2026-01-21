import 'dart:async';
import 'dart:math';

import 'package:eco_drive/data/drive_sample.dart';
import 'package:eco_drive/data/emission_model.dart';
import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/data/vehicle_state.dart';
import 'package:eco_drive/utils/gps_service.dart';
import 'package:eco_drive/utils/sensor_fusion_engine.dart';
import 'package:eco_drive/utils/sensor_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TripRecorder {
  final SensorService sensors = SensorService();
  final GpsService gps = GpsService();
  late final SensorFusionEngine fusion;
  final EmissionModel emissionModel = EmissionModel();

  final _sampleController = StreamController<DriveSample>.broadcast();

  bool recording = false;
  Trip? trip;
  Position? currentPosition;
  Stream<DriveSample> get samples => _sampleController.stream;

  DateTime? _lastEmitTime;
  static const emitInterval = Duration(milliseconds: 1000); // 1 Hz

  final List<DriveSample> _buffer = [];
  DateTime? _tripStart;

  double totalDistanceMeters = 0.0;
  double avgSpeedMps = 0;

  TripRecorder() {
    fusion = SensorFusionEngine(sensors, gps);
  }

  void start() {
    sensors.start();
    gps.start();
    fusion.start();

    fusion.vehicleState$.listen(_onVehicleState);
    gps.position$.listen(_onPosition);

    _buffer.clear();
    _tripStart = DateTime.now();
    recording = false;
    totalDistanceMeters = 0.0;
    avgSpeedMps = 0;
    currentPosition = null;
  }

  void beginRecording() {
    recording = true;
  }

  void stop() {
    sensors.stop();
    gps.stop();

    recording = false;
    _saveTrip();
  }

  void dispose() {
    sensors.dispose();
    gps.dispose();
    _sampleController.close();
  }

  void _saveTrip() {
    trip = Trip(
      id: _tripStart!.millisecondsSinceEpoch.toString(),
      start: _tripStart!,
      end: DateTime.now(),
      samples: List.from(_buffer),
      totalDistanceMeters: totalDistanceMeters,
      avgSpeedMps: avgSpeedMps,
    );
  }

  double _evaluateAccelerationMagnitude(VehicleState s) {
    return sqrt(s.accelLong * s.accelLong + s.accelLat * s.accelLat);
  }

  void _onVehicleState(VehicleState s) {
    if (currentPosition == null) return;

    // Throttle events to emitInterval
    final now = DateTime.now();
    if (_lastEmitTime != null &&
        now.difference(_lastEmitTime!) < emitInterval) {
      return;
    }
    _lastEmitTime = now;

    final emission = emissionModel.computeEmission(s);
    final accel = _evaluateAccelerationMagnitude(s);
    final sample = DriveSample(
      timestamp: now,
      lat: currentPosition!.latitude,
      lon: currentPosition!.longitude,
      accel: accel,
      speed: s.speed,
      emission: emission,
    );

    _sampleController.add(sample);

    if (!recording) return;
    _buffer.add(sample);
    final elapsedSeconds = DateTime.now().difference(_tripStart!).inSeconds;
    avgSpeedMps = elapsedSeconds > 0 ? totalDistanceMeters / elapsedSeconds : 0;
  }

  void _onPosition(Position p) {
    if (currentPosition != null && recording) {
      totalDistanceMeters += const Distance().as(
        LengthUnit.Meter,
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        LatLng(p.latitude, p.longitude),
      );
    }
    currentPosition = p;
  }
}
