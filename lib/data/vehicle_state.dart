class VehicleState {
  final double speed; // m/s
  final double accelLong; // m/s² (forward only)
  final double accelLat; // m/s² (lateral)
  final double jerk; // m/s³
  final double dt; // seconds

  const VehicleState({
    required this.speed,
    required this.accelLong,
    required this.accelLat,
    required this.jerk,
    required this.dt,
  });
}
