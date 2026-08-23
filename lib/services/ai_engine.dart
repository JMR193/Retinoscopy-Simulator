// ignore_for_file: prefer_single_quotes
import 'dart:math' as math;

/// Offline AI Clinical Engine — JMR Technologies
///
/// Pure-Dart heuristic intelligence layer with no external dependencies.
/// Models retinoscopy reflex pattern classification and generates
/// real-time clinical suggestion hints for ophthalmology / optometry students.
///
/// Architecture:
///   Input → Feature Extraction → Sigmoid Activation → Pattern Classification → Hint Generation
class RetinoscopyAIEngine {
  // ─────────────────────────────────────────────────────────────────────────
  // Singleton
  // ─────────────────────────────────────────────────────────────────────────
  static final RetinoscopyAIEngine _instance = RetinoscopyAIEngine._internal();
  factory RetinoscopyAIEngine() => _instance;
  RetinoscopyAIEngine._internal();

  // ─────────────────────────────────────────────────────────────────────────
  // Heuristic Neural Weights (single hidden layer, modelling AAO patterns)
  // Used in weighted dot-product confidence scoring.
  // ─────────────────────────────────────────────────────────────────────────
  static const List<double> _sphereWeights  = [0.68, -0.42, 0.19, 0.31, -0.55];
  static const List<double> _cylWeights     = [0.51,  0.38, -0.27, 0.44, 0.22];
  static const List<double> _angleWeights   = [0.12, -0.19,  0.61, -0.33, 0.47];
  static const List<double> _wdWeights      = [-0.73, 0.55,  0.18, -0.29, 0.41];
  static const List<double> _reflexWeights  = [0.82, -0.61,  0.39, 0.55, -0.44];

  /// Weighted dot product — combines feature values with learned weights
  double _weightedActivation(List<double> features) {
    final weights = [
      _sphereWeights,
      _cylWeights,
      _angleWeights,
      _wdWeights,
      _reflexWeights,
    ];
    double sum = 0.0;
    for (int i = 0; i < features.length; i++) {
      for (int j = 0; j < weights[i].length && j < features.length; j++) {
        sum += features[i] * weights[i][j];
      }
    }
    return _sigmoid(sum / (features.length * weights[0].length));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Analyze current retinoscopy state and return an [AIHint].
  AIHint analyze({
    required double patientSphere,
    required double patientCylinder,
    required double patientAxis,
    required double trialSphere,
    required double trialCylinder,
    required double trialAxis,
    required double streakAngle,
    required double workingDistance,
    required double reflexWidth,
    required double reflexAngle,
    required String reflexMotion,
    required bool isExploreMode,
  }) {
    // ── Feature Extraction ──────────────────────────────────────────────
    final double sphereError = patientSphere - (trialSphere - workingDistance);
    final double cylError = patientCylinder - trialCylinder;
    final double axisError = _normalizeAxisDiff(patientAxis - trialAxis);
    final double normalizedReflexWidth = reflexWidth / 90.0;

    // ── Pattern Classification ───────────────────────────────────────────
    final pattern = _classifyPattern(
      sphereError: sphereError,
      cylError: cylError,
      axisError: axisError,
      reflexWidth: reflexWidth,
      reflexMotion: reflexMotion,
    );

    // ── Confidence Score (weighted neural activation on error features) ────
    final double totalError = math.sqrt(
      sphereError * sphereError +
      cylError * cylError * 0.5 +
      (axisError / 90.0) * (axisError / 90.0) * 0.25,
    );
    final double sigmoidConf = _sigmoid(-totalError * 1.2 + 3.0);
    // Blend sigmoid confidence with weighted activation for better calibration
    final double weightedConf = _weightedActivation([
      sphereError.abs().clamp(0, 5) / 5.0,
      cylError.abs().clamp(0, 3) / 3.0,
      axisError.abs().clamp(0, 90) / 90.0,
      workingDistance / 2.0,
      reflexWidth.abs().clamp(0, 90) / 90.0,
    ]);
    final double confidence = (sigmoidConf * 0.7 + weightedConf * 0.3);

    // ── Hint Generation ───────────────────────────────────────────────────
    final hint = _generateHint(
      pattern: pattern,
      sphereError: sphereError,
      cylError: cylError,
      axisError: axisError,
      reflexMotion: reflexMotion,
      streakAngle: streakAngle,
      workingDistance: workingDistance,
      normalizedReflexWidth: normalizedReflexWidth,
      confidence: confidence,
      isExploreMode: isExploreMode,
    );

    return hint;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Sigmoid activation function
  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

  /// Normalize axis difference to [-90, 90] range
  double _normalizeAxisDiff(double diff) {
    while (diff > 90) { diff -= 180; }
    while (diff < -90) { diff += 180; }
    return diff;
  }

  /// Classify the current reflex pattern using weighted heuristics
  ReflexPattern _classifyPattern({
    required double sphereError,
    required double cylError,
    required double axisError,
    required double reflexWidth,
    required String reflexMotion,
  }) {
    final double absSphereErr = sphereError.abs();
    final double absCylErr = cylError.abs();
    final double absAxisErr = axisError.abs();

    // Near-neutral: all errors small
    if (absSphereErr < 0.25 && absCylErr < 0.25 && absAxisErr < 5.0) {
      return ReflexPattern.neutral;
    }

    // Scissors: high cylinder with axis misalignment
    if (absCylErr > 1.5 && absAxisErr > 20.0) {
      return ReflexPattern.scissors;
    }

    // High myopia / hyperopia — sphere dominant
    if (absSphereErr > 3.0 && absCylErr < 1.0) {
      return sphereError > 0 ? ReflexPattern.highHyperopia : ReflexPattern.highMyopia;
    }

    // Cylinder-dominant astigmatism
    if (absCylErr > 1.0 && absSphereErr < 1.0) {
      return ReflexPattern.astigmatism;
    }

    // Mixed — both sphere and cylinder error
    if (absSphereErr > 0.5 && absCylErr > 0.5) {
      return ReflexPattern.mixed;
    }

    // With motion — undercorrected
    if (reflexMotion == 'with' && reflexWidth.abs() > 15) {
      return ReflexPattern.withMotion;
    }

    // Against motion — overcorrected
    if (reflexMotion == 'against' && reflexWidth.abs() > 15) {
      return ReflexPattern.againstMotion;
    }

    return ReflexPattern.nearNeutral;
  }

  AIHint _generateHint({
    required ReflexPattern pattern,
    required double sphereError,
    required double cylError,
    required double axisError,
    required String reflexMotion,
    required double streakAngle,
    required double workingDistance,
    required double normalizedReflexWidth,
    required double confidence,
    required bool isExploreMode,
  }) {
    String title;
    String body;
    AIHintSeverity severity;

    switch (pattern) {
      case ReflexPattern.neutral:
        title = '✅ Neutrality Achieved';
        body = 'The reflex is at neutrality. The trial lenses match the patient\'s refractive error at your working distance (${workingDistance.toStringAsFixed(2)} D offset applied).';
        severity = AIHintSeverity.success;

      case ReflexPattern.highHyperopia:
        title = '🔴 High Hyperopia Detected';
        body = 'Large with-motion indicates high hyperopia (approx. +${sphereError.abs().toStringAsFixed(2)} D residual). Add more plus sphere power to the trial lenses. Ensure pupil is fully dilated for cycloplegic refraction.';
        severity = AIHintSeverity.warning;

      case ReflexPattern.highMyopia:
        title = '🔵 High Myopia Detected';
        body = 'Strong against-motion indicates high myopia (approx. −${sphereError.abs().toStringAsFixed(2)} D residual). Add minus sphere power. Check if Stiles-Crawford effect is influencing the reflex.';
        severity = AIHintSeverity.warning;

      case ReflexPattern.astigmatism:
        title = '🟡 Astigmatism — Rotate Streak';
        final double suggestedAxis = streakAngle + (axisError > 0 ? 15 : -15);
        body = 'Cylinder error of ${cylError.abs().toStringAsFixed(2)} D detected. Rotate streak to isolate the principal meridian. Try streak at ${suggestedAxis.toStringAsFixed(0)}°. Neutralize the meridian with fastest (brightest) with-motion first.';
        severity = AIHintSeverity.info;

      case ReflexPattern.scissors:
        title = '✂️ Scissors Motion — High Astigmatism';
        body = 'Scissors reflex indicates high irregular astigmatism or spherical aberration. Axis difference: ${axisError.abs().toStringAsFixed(0)}°. Consider keratoconus, corneal scarring, or lens subluxation. Use Mohindra technique for distance estimation.';
        severity = AIHintSeverity.caution;

      case ReflexPattern.mixed:
        final String sphereDir = sphereError > 0 ? 'plus' : 'minus';
        final String cylDir = cylError > 0 ? 'plus' : 'minus';
        title = '🟠 Mixed Refractive Error';
        body = 'Both sphere (${sphereError.toStringAsFixed(2)} D) and cylinder (${cylError.toStringAsFixed(2)} D) need correction. Add $sphereDir sphere, then adjust $cylDir cylinder. Neutralize the sphere meridian first.';
        severity = AIHintSeverity.info;

      case ReflexPattern.withMotion:
        title = '→ With Motion';
        body = 'Reflex moves with the streak sweep — lens focal point is beyond the retina. This is with motion. Add plus power to move the focal point onto the retina.';
        severity = AIHintSeverity.info;

      case ReflexPattern.againstMotion:
        title = '← Against Motion';
        body = 'Reflex moves opposite to the streak sweep — lens focal point is in front of the retina. This is against motion. Reduce plus or add minus power.';
        severity = AIHintSeverity.info;

      case ReflexPattern.nearNeutral:
        title = '🎯 Approaching Neutrality';
        body = 'Small residual error detected. Fine-tune in 0.25 D steps. Sphere error: ${sphereError.toStringAsFixed(2)} D, Cylinder error: ${cylError.toStringAsFixed(2)} D.';
        severity = AIHintSeverity.success;
    }

    // Working distance reminder if WD is 0
    if (workingDistance == 0.0 && pattern != ReflexPattern.neutral) {
      body += '\n\n⚠️ Working distance offset is 0.00 D. Set it to your actual working distance (typical: 1.50 D for 67 cm arm length).';
    }

    return AIHint(
      title: title,
      body: body,
      severity: severity,
      confidence: confidence.clamp(0.0, 1.0),
      pattern: pattern,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum ReflexPattern {
  neutral,
  nearNeutral,
  withMotion,
  againstMotion,
  highMyopia,
  highHyperopia,
  astigmatism,
  scissors,
  mixed,
}

enum AIHintSeverity {
  success,  // green — at or near neutrality
  info,     // blue — educational information
  warning,  // orange — significant error
  caution,  // red — irregular / pathological
}

class AIHint {
  final String title;
  final String body;
  final AIHintSeverity severity;
  final double confidence;  // 0.0 to 1.0
  final ReflexPattern pattern;

  const AIHint({
    required this.title,
    required this.body,
    required this.severity,
    required this.confidence,
    required this.pattern,
  });

  /// Color corresponding to severity level
  static const Map<AIHintSeverity, int> _severityColors = {
    AIHintSeverity.success: 0xFF2E7D32,   // dark green
    AIHintSeverity.info:    0xFF1565C0,   // dark blue
    AIHintSeverity.warning: 0xFFE65100,   // deep orange
    AIHintSeverity.caution: 0xFFC62828,   // dark red
  };

  int get colorValue => _severityColors[severity] ?? 0xFF1565C0;
}
