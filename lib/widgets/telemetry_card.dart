import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:eco_drive/widgets/metric.dart';

class TelemetryCard extends StatelessWidget {
  final double speedMps;
  final double accel;
  final double emission;
  final double totalDistanceMeters;
  final double avgSpeedMps;
  final LatLng? position;
  final bool recording;
  final bool isViewTrip;

  const TelemetryCard({
    super.key,
    required this.speedMps,
    required this.accel,
    required this.emission,
    required this.totalDistanceMeters,
    required this.avgSpeedMps,
    required this.position,
    required this.recording,
    required this.isViewTrip,
  });

  Color accelColor(double a) {
    final v = a.abs();
    if (v < 0.5) return Colors.green;
    if (v < 1.5) return Colors.orange;
    return Colors.red;
  }

  Color emissionColor(double e) {
    if (e < 0.5) return Colors.green;
    if (e < 1.0) return Colors.yellow.shade700;
    if (e < 2.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final speedMph = speedMps * 2.23694;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isViewTrip) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Metric(
                    label: 'SPEED',
                    value: speedMph.toStringAsFixed(1),
                    unit: 'mph',
                  ),
                  Metric(
                    label: 'ACCEL',
                    value: accel.toStringAsFixed(2),
                    unit: 'm/s²',
                    color: accelColor(accel),
                  ),
                  Metric(
                    label: 'EMISS',
                    value: emission.toStringAsFixed(2),
                    unit: '',
                    color: emissionColor(emission),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Metric(
                  label: 'DIST',
                    value: (totalDistanceMeters * 0.000621371).toStringAsFixed(2),
                  unit: 'miles',
                ),
                Metric(
                  label: 'AVG',
                  value: (avgSpeedMps * 2.23694).toStringAsFixed(1),
                  unit: 'mph',
                ),
              ],
            ),
            if (!isViewTrip) ...[
              const SizedBox(height: 8),
              if (position != null)
                Text(
                  'Lat: ${position!.latitude.toStringAsFixed(5)}   '
                  'Lon: ${position!.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Text(
                recording ? '● Recording' : 'Stopped',
                style: TextStyle(
                  color: recording ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
