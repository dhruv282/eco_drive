import 'dart:async';
import 'dart:math';
import 'package:eco_drive/data/drive_sample.dart';
import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/utils/trip_storage.dart';
import 'package:eco_drive/widgets/telemetry_card.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:vector_math/vector_math.dart' show Matrix3, Vector3;
import 'package:wakelock_plus/wakelock_plus.dart';

class DriveScreen extends StatefulWidget {
  final Trip? viewTrip;
  const DriveScreen({super.key, this.viewTrip});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  late MapController mapController;

  StreamSubscription<UserAccelerometerEvent>? accelSub;
  StreamSubscription<Position>? gpsSub;
  StreamSubscription<AccelerometerEvent>? accelerometerSub;
  StreamSubscription<GyroscopeEvent>? gyroSub;

  bool recording = false;
  DateTime? tripStart;

  Vector3 gravity = Vector3(0, 0, -1);

  double filteredAccel = 0.0;
  double speed = 0.0;
  double emissionRate = 0.0;

  DateTime? lastUiUpdate;
  static const uiUpdateInterval = Duration(milliseconds: 200);

  double totalDistanceMeters = 0.0;
  double avgSpeedMps = 0;
  double speedMps = 0;
  double longitudinalAccel = 0;
  double emissionScore = 0;
  LatLng? currentPosition;
  double yawRad = 0.0;
  DateTime? lastGyroTs;
  DateTime? lastAccelTs;
  double? lastGpsHeadingRad;
  static const double yawAlpha = 0.98;

  final List<DriveSample> samples = [];
  final List<Polyline> polylines = [];
  final List<Marker> markers = [];

  static const double accelFilterAlpha = 0.8;

  bool followUser = true;
  LatLng? lastPosition;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    if (widget.viewTrip != null) {
      samples.addAll(widget.viewTrip!.samples);
      _rebuildPolylines();
      _buildStartEndMarkers();
      totalDistanceMeters = widget.viewTrip!.totalDistanceMeters;
      avgSpeedMps = widget.viewTrip!.avgSpeedMps;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToTrip();
      });
    } else {
      _startSensors();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    accelSub?.cancel();
    gpsSub?.cancel();
    accelerometerSub?.cancel();
    gyroSub?.cancel();
    super.dispose();
  }

  void _rebuildPolylines() {
    for (int i = 0; i < samples.length - 1; i++) {
      final s1 = samples[i];
      final s2 = samples[i + 1];
      polylines.add(
        Polyline(
          points: [LatLng(s1.lat, s1.lon), LatLng(s2.lat, s2.lon)],
          strokeWidth: 5,
          color: _emissionToColor(s1.emission),
        ),
      );
    }
  }

  void _buildStartEndMarkers() {
    if (samples.isEmpty) return;

    final start = samples.first;
    final end = samples.last;

    markers.addAll([
      Marker(
        point: LatLng(start.lat, start.lon),
        width: 40,
        height: 40,
        child: const Icon(Icons.flag, color: Colors.green, size: 36),
      ),
      Marker(
        point: LatLng(end.lat, end.lon),
        width: 40,
        height: 40,
        child: const Icon(Icons.flag, color: Colors.red, size: 36),
      ),
    ]);
  }

  LatLngBounds _tripBounds() {
    final lats = samples.map((s) => s.lat);
    final lons = samples.map((s) => s.lon);

    return LatLngBounds(
      LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lons.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lons.reduce((a, b) => a > b ? a : b),
      ),
    );
  }

  void _fitMapToTrip() {
    if (samples.length < 2) return;

    final bounds = _tripBounds();

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
  }

  Future<void> _startSensors() async {
    await Geolocator.requestPermission();

    accelSub = userAccelerometerEventStream().listen(_onAccel);
    accelerometerSub = accelerometerEventStream().listen((e) {
      gravity = Vector3(e.x, e.y, e.z).normalized();
    });
    gyroSub = gyroscopeEventStream().listen(_onGyro);

    gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    ).listen(_onGps);
  }

  void _throttledUiUpdate(DateTime now) {
    if (lastUiUpdate == null ||
        now.difference(lastUiUpdate!) > uiUpdateInterval) {
      lastUiUpdate = now;
      setState(() {});
    }
  }

  void _onGyro(GyroscopeEvent e) {
    final now = DateTime.now();

    if (lastGyroTs != null) {
      final dt = now.difference(lastGyroTs!).inMilliseconds / 1000.0;

      // Z-axis rotation ≈ yaw (phone flat assumption)
      yawRad += e.z * dt;
    }

    lastGyroTs = now;
  }

  void _onAccel(UserAccelerometerEvent e) {
    final now = DateTime.now();

    // Linear acceleration in phone frame
    final phoneAccel = Vector3(e.x, e.y, e.z);

    // Build world frame from gravity
    final zWorld = -gravity; // up
    final xRef = Vector3(1, 0, 0);
    final yWorld = zWorld.cross(xRef).normalized();
    final xWorld = yWorld.cross(zWorld).normalized();

    // Rotation matrix (phone → world)
    final R = Matrix3.columns(xWorld, yWorld, zWorld);

    // Rotate acceleration into world frame
    final worldAccel = R * phoneAccel;

    // rotate horizontal plane by gyro yaw
    final forwardAccel =
        worldAccel.x * cos(yawRad) + worldAccel.y * sin(yawRad);

    // Longitudinal acceleration (approximate)
    filteredAccel =
        accelFilterAlpha * filteredAccel +
        (1 - accelFilterAlpha) * forwardAccel;

    // Integrate to estimate speed (short-term only)
    if (lastAccelTs != null) {
      final dt = now.difference(lastAccelTs!).inMilliseconds / 1000.0;
      speed += filteredAccel * dt;
      speed = speed.clamp(0, 200); // sanity clamp
    }

    lastAccelTs = now;

    // Simple relative emissions proxy
    emissionRate = filteredAccel.abs() + speed * 0.02;

    longitudinalAccel = filteredAccel;
    emissionScore = emissionRate;
    _throttledUiUpdate(now);
  }

  void _onGps(Position pos) {
    currentPosition = LatLng(pos.latitude, pos.longitude);

    speedMps = pos.speed;

    // Convert heading to radians
    if (pos.heading >= 0) {
      lastGpsHeadingRad = pos.heading * pi / 180.0;
    }

    // Apply complementary filter if we have GPS heading
    if (lastGpsHeadingRad != null) {
      yawRad = yawAlpha * yawRad + (1 - yawAlpha) * lastGpsHeadingRad!;
    }

    if (followUser) {
      mapController.move(
        currentPosition!,
        mapController.camera.zoom,
        id: 'gps-follow',
      );
    }

    if (!recording) return;

    if (lastPosition != null) {
      totalDistanceMeters += const Distance().as(
        LengthUnit.Meter,
        lastPosition!,
        currentPosition!,
      );
    }
    final elapsedSeconds = DateTime.now().difference(tripStart!).inSeconds;
    avgSpeedMps = elapsedSeconds > 0 ? totalDistanceMeters / elapsedSeconds : 0;

    lastPosition = currentPosition;

    final sample = DriveSample(
      timestamp: DateTime.now(),
      lat: pos.latitude,
      lon: pos.longitude,
      speed: speed,
      accel: filteredAccel,
      emission: emissionRate,
    );

    setState(() {
      samples.add(sample);
      _updatePolyline();
    });
  }

  void _updatePolyline() {
    if (samples.length < 2) return;

    final s1 = samples[samples.length - 2];
    final s2 = samples.last;

    polylines.add(
      Polyline(
        points: [LatLng(s1.lat, s1.lon), LatLng(s2.lat, s2.lon)],
        strokeWidth: 5,
        color: _emissionToColor(s1.emission),
      ),
    );
  }

  Color _emissionToColor(double e) {
    if (e < 0.5) return Colors.green;
    if (e < 1.0) return Colors.yellow;
    if (e < 2.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _startTrip() async {
    await WakelockPlus.enable();

    setState(() {
      samples.clear();
      polylines.clear();
      tripStart = DateTime.now();
      totalDistanceMeters = 0;
      lastPosition = null;
      recording = true;
    });
  }

  Future<void> _stopTrip() async {
    recording = false;

    await WakelockPlus.disable();

    final trip = Trip(
      id: tripStart!.millisecondsSinceEpoch.toString(),
      start: tripStart!,
      end: DateTime.now(),
      samples: List.from(samples),
      totalDistanceMeters: totalDistanceMeters,
      avgSpeedMps: avgSpeedMps,
    );

    await TripStorage.saveTrip(trip);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewTrip != null ? 'Trip Replay' : 'Driving'),
      ),
      floatingActionButton:
          widget.viewTrip != null
              ? null
              : FloatingActionButton(
                backgroundColor: recording ? Colors.red : Colors.green,
                onPressed: recording ? _stopTrip : _startTrip,
                child: Icon(recording ? Icons.stop : Icons.play_arrow),
              ),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:
                    widget.viewTrip != null
                        ? LatLng(samples.first.lat, samples.first.lon)
                        : const LatLng(37.4219999, -122.0840575),
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      followUser = false;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  // urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/${isDarkMode ? 'dark' : 'light'}_all/{z}/{x}/{y}{r}.png',
                  subdomains: ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.ecodrive',
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
                if (widget.viewTrip == null) ...[
                  CurrentLocationLayer(
                    style: LocationMarkerStyle(showHeadingSector: false),
                    positionStream: Geolocator.getPositionStream().map(
                      (position) => LocationMarkerPosition(
                        latitude: position.latitude,
                        longitude: position.longitude,
                        accuracy: position.accuracy,
                      ),
                    ),
                  ),
                ],
                Positioned(
                  bottom: 75,
                  left: 20,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'resetRotation',
                    onPressed: () {
                      mapController.rotate(0, id: 'reset-rotation');
                    },
                    child: const Icon(Icons.explore),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'recenterLocation',
                    onPressed: () {
                      setState(() {
                        followUser = true;
                      });
                      if (currentPosition != null) {
                        mapController.move(
                          currentPosition!,
                          mapController.camera.zoom,
                        );
                      } else if (widget.viewTrip != null) {
                        _fitMapToTrip();
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: TelemetryCard(
                speedMps: speedMps,
                accel: longitudinalAccel,
                emission: emissionScore,
                totalDistanceMeters: totalDistanceMeters,
                avgSpeedMps: avgSpeedMps,
                position: currentPosition,
                recording: recording,
                isViewTrip: widget.viewTrip != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
