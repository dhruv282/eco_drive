import 'package:eco_drive/widgets/eco_score_progress_bar.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final int tripCount;
  final double totalDistanceMeters;
  final double avgSpeedMps;
  final double ecoScore;

  const SummaryCard({
    super.key,
    required this.tripCount,
    required this.totalDistanceMeters,
    required this.avgSpeedMps,
    required this.ecoScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceBright,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driving Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Trips: $tripCount'),
            Text(
              'Distance: ${(totalDistanceMeters * 0.000621371).toStringAsFixed(1)} miles',
            ),
            Text(
              'Avg Speed: ${(avgSpeedMps * 2.23694).toStringAsFixed(1)} mph',
            ),
            const SizedBox(height: 12),
            EcoScoreProgressBar(ecoScore: ecoScore),
          ],
        ),
      ),
    );
  }
}
