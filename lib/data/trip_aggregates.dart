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

    double ecoScore =
        count == 0 ? 100 : (100 / (1 + emissionSum / count)).clamp(0, 100);

    return TripAggregates(
      totalDistanceMeters: distance,
      avgSpeedMps: avgSpeed,
      ecoScore: ecoScore,
    );
  }
}
