import 'package:eco_drive/data/drive_sample.dart';

class Trip {
  final String id;
  final DateTime start;
  final DateTime end;
  final List<DriveSample> samples;
  final double totalDistanceMeters;
  final double avgSpeedMps;

  Trip({
    required this.id,
    required this.start,
    required this.end,
    required this.samples,
    this.totalDistanceMeters = 0.0,
    this.avgSpeedMps = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'samples': samples.map((s) => s.toJson()).toList(),
    'totalDistanceMeters': totalDistanceMeters,
    'avgSpeedMps': avgSpeedMps,
  };

  static Trip fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'],
    start: DateTime.parse(json['start']),
    end: DateTime.parse(json['end']),
    samples:
        (json['samples'] as List).map((e) => DriveSample.fromJson(e)).toList(),
    totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
    avgSpeedMps: (json['avgSpeedMps'] as num).toDouble(),
  );
}
