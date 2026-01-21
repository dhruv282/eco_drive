import 'dart:async';
import 'package:eco_drive/data/drive_sample.dart';
import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/providers/trips_provider.dart';
import 'package:eco_drive/utils/trip_recorder.dart';
import 'package:eco_drive/widgets/telemetry_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class DriveScreen extends StatefulWidget {
  final Trip? viewTrip;
  const DriveScreen({super.key, this.viewTrip});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  MapController mapController = MapController();
  TripRecorder tripRecorder = TripRecorder();

  double totalDistanceMeters = 0.0;
  double avgSpeedMps = 0;
  DriveSample? lastSample;

  final List<Polyline> polylines = [];
  final List<Marker> markers = [];

  bool followUser = true;

  @override
  void initState() {
    super.initState();
    if (widget.viewTrip != null) {
      _rebuildPolylines(widget.viewTrip!.samples);
      _buildStartEndMarkers(widget.viewTrip!.samples);
      totalDistanceMeters = widget.viewTrip!.totalDistanceMeters;
      avgSpeedMps = widget.viewTrip!.avgSpeedMps;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToTrip(widget.viewTrip!.samples);
      });
    } else {
      tripRecorder.start();
      tripRecorder.samples.listen(_onNewSample);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    tripRecorder.dispose();
    super.dispose();
  }

  void _rebuildPolylines(List<DriveSample> samples) {
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

  void _buildStartEndMarkers(List<DriveSample> samples) {
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

  LatLngBounds _tripBounds(List<DriveSample> samples) {
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

  void _fitMapToTrip(List<DriveSample> samples) {
    if (samples.length < 2) return;

    final bounds = _tripBounds(samples);

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );

    _forceTileRefresh();
  }

  void _forceTileRefresh() {
    Future.delayed(const Duration(milliseconds: 50), () {
      final center = mapController.camera.center;

      mapController.move(
        LatLng(center.latitude + 1e-7, center.longitude),
        mapController.camera.zoom,
      );
    });
  }

  void _updatePolyline(DriveSample s1, DriveSample s2) {
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

    tripRecorder.beginRecording();

    setState(() {
      polylines.clear();
      totalDistanceMeters = 0;
    });
  }

  void _onNewSample(DriveSample sample) {
    if (tripRecorder.recording) {
      totalDistanceMeters = tripRecorder.totalDistanceMeters;
      avgSpeedMps = tripRecorder.avgSpeedMps;

      if (lastSample != null) {
        _updatePolyline(sample, lastSample!);
      }
    }

    final currentPos = LatLng(sample.lat, sample.lon);
    if (followUser) {
      mapController.move(currentPos, mapController.camera.zoom);
    }
    setState(() {
      lastSample = sample;
    });
  }

  Future<void> _stopTrip(TripsProvider tripsProvider) async {
    await WakelockPlus.disable();
    tripRecorder.stop();
    if (tripRecorder.trip == null) return;
    await tripsProvider.saveTrip(tripRecorder.trip!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final recording = widget.viewTrip == null && tripRecorder.recording;
    final currentPosition =
        tripRecorder.currentPosition != null
            ? LatLng(
              tripRecorder.currentPosition!.latitude,
              tripRecorder.currentPosition!.longitude,
            )
            : null;
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewTrip != null ? 'Trip Replay' : 'Driving'),
        actions: [
          if (widget.viewTrip != null)
            IconButton(
              onPressed:
                  () => showDialog(
                    context: context,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: const Text('Delete Trip?'),
                          content: const Text(
                            'Are you sure you want to delete this trip?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await tripsProvider
                                    .deleteTrip(widget.viewTrip!)
                                    .then((_) {
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    });
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  ),
              icon: Icon(Icons.delete, color: Colors.redAccent),
            ),
        ],
      ),
      floatingActionButton:
          widget.viewTrip != null
              ? null
              : FloatingActionButton(
                backgroundColor: recording ? Colors.red : Colors.green,
                onPressed:
                    recording ? () => _stopTrip(tripsProvider) : _startTrip,
                child: Icon(recording ? Icons.stop : Icons.play_arrow),
              ),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:
                    currentPosition ?? LatLng(37.4219999, -122.0840575),
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
                      if (widget.viewTrip != null) {
                        _fitMapToTrip(widget.viewTrip!.samples);
                      } else if (currentPosition != null) {
                        mapController.move(
                          currentPosition,
                          mapController.camera.zoom,
                        );
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
                speedMps: lastSample?.speed ?? 0.0,
                accel: lastSample?.accel ?? 0.0,
                emission: lastSample?.emission ?? 0.0,
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
