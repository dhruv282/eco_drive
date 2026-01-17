class DriveSample {
  final DateTime timestamp;
  final double lat;
  final double lon;
  final double speed;
  final double accel;
  final double emission;

  DriveSample({
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.speed,
    required this.accel,
    required this.emission,
  });

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'lat': lat,
    'lon': lon,
    'speed': speed,
    'accel': accel,
    'emission': emission,
  };

  static DriveSample fromJson(Map<String, dynamic> json) => DriveSample(
    timestamp: DateTime.parse(json['ts']),
    lat: json['lat'],
    lon: json['lon'],
    speed: json['speed'],
    accel: json['accel'],
    emission: json['emission'],
  );
}
