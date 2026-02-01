import 'dart:math' as math;

import 'package:eco_drive/data/trip.dart';

class TripAggregates {
  final double totalDistanceMeters;
  final double avgSpeedMps;
  final double ecoScore;

  const TripAggregates({
    required this.totalDistanceMeters,
    required this.avgSpeedMps,
    required this.ecoScore,
  });

  static double computeTripEcoScore(Trip trip) {
    if (trip.samples.isEmpty) return 100.0;

    double emissionSum = 0;
    for (var s in trip.samples) {
      emissionSum += s.emission;
    }
    final avgEmission = emissionSum / trip.samples.length;

    // Exponential decay for eco score
    final ecoScore = (100 * math.exp(-avgEmission / 1.5)).clamp(0.0, 100.0);
    return ecoScore;
  }

  static TripAggregates computeAggregates(List<Trip> trips) {
    if (trips.isEmpty) {
      return const TripAggregates(
        totalDistanceMeters: 0,
        avgSpeedMps: 0,
        ecoScore: 100,
      );
    }

    double distance = 0;
    double speedSum = 0;
    double emissionSum = 0;
    int count = 0;

    for (final trip in trips) {
      distance += trip.totalDistanceMeters;
      speedSum += trip.avgSpeedMps * trip.samples.length;
      for (var s in trip.samples) {
        emissionSum += s.emission;
        count++;
      }
    }

    double avgSpeed = count == 0 ? 0 : speedSum / count;

    // Exponential decay for eco score
    final avgEmission = count == 0 ? 0.0 : emissionSum / count;
    final ecoScore = (100 * math.exp(-avgEmission / 1.5)).clamp(0.0, 100.0);

    return TripAggregates(
      totalDistanceMeters: distance,
      avgSpeedMps: avgSpeed,
      ecoScore: ecoScore,
    );
  }
}
