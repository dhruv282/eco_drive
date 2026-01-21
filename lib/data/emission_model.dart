import 'package:eco_drive/data/vehicle_state.dart';

class EmissionModel {
  // Tunable parameters
  static const double accelThreshold = 0.6;    // m/s²
  static const double jerkThreshold = 1.5;     // m/s³
  static const double lateralLimit = 0.8;      // m/s²

  static const double optimalSpeedMin = 13.0;  // m/s
  static const double optimalSpeedMax = 27.0;  // m/s

  double computeEmission(VehicleState s) {
    double emission = 0.0;

    // Longitudinal acceleration cost
    if (s.accelLong > accelThreshold) {
      emission += (s.accelLong - accelThreshold) * 1.5;
    }

    // Jerk (aggressiveness)
    if (s.jerk.abs() > jerkThreshold) {
      emission += (s.jerk.abs() - jerkThreshold) * 0.8;
    }

    // Suppress during turns
    if (s.accelLat.abs() > lateralLimit) {
      emission *= 0.4;
    }

    // Suppress if speed not changing (coasting / turning)
    if ((s.accelLong.abs() < 0.2) && (s.jerk.abs() < 0.5)) {
      emission *= 0.5;
    }

    // Speed efficiency factor
    final speedFactor = _speedEfficiencyFactor(s.speed);
    emission /= speedFactor;

    return emission.clamp(0.0, 10.0);
  }

  double _speedEfficiencyFactor(double speed) {
    if (speed <= 0) return 0.7;

    if (speed >= optimalSpeedMin && speed <= optimalSpeedMax) {
      return 1.0;
    }

    final double delta = speed < optimalSpeedMin
        ? optimalSpeedMin - speed
        : speed - optimalSpeedMax;

    final double penalty = (delta / optimalSpeedMax).clamp(0.0, 0.3);
    return (1.0 - penalty).clamp(0.7, 1.0);
  }
}
