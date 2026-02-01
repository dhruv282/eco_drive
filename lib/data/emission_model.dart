import 'package:eco_drive/data/vehicle_state.dart';

class EmissionModel {
  // Tunable parameters
  static const double accelThreshold = 0.6; // m/s²
  static const double jerkThreshold = 1.5; // m/s³
  static const double lateralThreshold = 1.2; // m/s² (for cornering penalty)

  static const double optimalSpeed = 24.5; // m/s (approx 55 mph)
  static const double optimalSpeedDeviation = 5.0; // m/s

  // Weight factors for different components
  static const double accelWeight = 1.5;
  static const double brakingWeight = 1.0; // Slightly less than accel
  static const double jerkWeight = 0.8;
  static const double lateralWeight = 0.5; // Mild penalty for cornering

  double computeEmission(VehicleState s) {
    double emission = 0.0;

    // Longitudinal acceleration cost
    if (s.accelLong > accelThreshold) {
      final excess = s.accelLong.abs() - accelThreshold;
      // Slightly lower penalty for braking (unavoidable sometimes)
      final weight = s.accelLong > 0 ? accelWeight : brakingWeight;
      emission += excess * weight;
    }

    // Jerk (aggressiveness)
    if (s.jerk.abs() > jerkThreshold) {
      emission += (s.jerk.abs() - jerkThreshold) * jerkThreshold * jerkWeight;
    }

    // Penalize aggressive cornering
    if (s.accelLat.abs() > lateralThreshold) {
      emission += (s.accelLat.abs() - lateralThreshold) * lateralWeight;
    }

    // Reward true coasting (slight deceleration, smooth)
    if (s.accelLong < -0.1 && s.accelLong > -0.5 && s.jerk.abs() < 0.3) {
      emission *= 0.2; // Strong reward for coasting
    } else if (s.speed < 1.0 && s.accelLong.abs() < 0.2) {
      emission = 0; // No penalty for stopped/idling
    }

    // Speed efficiency penalty
    final speedPenalty = _speedEfficiencyPenalty(s.speed);
    emission *= (1.0 + speedPenalty);

    return emission.clamp(0.0, 10.0);
  }

  double _speedEfficiencyPenalty(double speed) {
    if (speed <= 0) return 0.0; // No penalty for stationary

    final deviation = (speed - optimalSpeed).abs();
    if (deviation < optimalSpeedDeviation) {
      return 0.0; // No penalty within optimal range (45-65 mph)
    } else if (deviation < (2 * optimalSpeedDeviation)) {
      return (deviation - optimalSpeedDeviation) * 0.02; // Gentle penalty (65-75 or 35-45 mph)
    } else {
      return 0.1 +
          (deviation - (2 * optimalSpeedDeviation)) * 0.03; // Steeper penalty (>75 or <35 mph)
    }
  }
}
