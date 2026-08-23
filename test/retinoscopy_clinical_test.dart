import 'package:flutter_test/flutter_test.dart';
import 'package:retinoscopy_simulator/state/retinoscopy_state.dart';

void main() {
  group('A to Z Retinoscopy Clinical & Optical Physics Tests', () {
    late RetinoscopyState state;

    setUp(() {
      state = RetinoscopyState();
    });

    test('1. Emmetropia baseline reflex dynamics', () {
      state.patientSphere = 0.0;
      state.patientCylinder = 0.0;
      state.patientAngle = 90.0;
      state.workingDistance = 1.50; // 67 cm
      state.plusSphere = 0.0;
      state.sleeveUp = false; // Plane mirror

      // Without working distance lens in front, emergent rays focus at infinity -> far point behind retinoscope -> WITH motion
      expect(state.reflexMotion, equals('with'));

      // Add +1.50 D working distance lens -> neutral flash point
      state.plusSphere = 1.50;
      expect(state.reflexMotion, equals('neutral'));
    });

    test('2. Simple Hyperopia (+2.00 D) Neutralization with Plus Lenses', () {
      state.patientSphere = 2.00;
      state.patientCylinder = 0.0;
      state.workingDistance = 1.50; // 67 cm (+1.50 D gross offset)
      state.plusSphere = 0.0;

      // Uncorrected hyperope -> Far point is virtual behind retina -> Strong WITH motion
      expect(state.reflexMotion, equals('with'));

      // Gross neutralizing sphere = Patient Rx (+2.00) + Working Distance (+1.50) = +3.50 D
      state.plusSphere = 3.50;
      expect(state.reflexMotion, equals('neutral'));
    });

    test('3. Simple Myopia (-3.00 D) Neutralization with Minus Lenses', () {
      state.patientSphere = -3.00;
      state.patientCylinder = 0.0;
      state.workingDistance = 1.50;
      state.plusLensesSelected = false;
      state.minusSphere = 0.0;

      // Far point of -3.00 D eye is at 33 cm (in front of the 67 cm retinoscope) -> AGAINST motion
      expect(state.reflexMotion, equals('against'));

      // Gross neutralizing lens = -3.00 + 1.50 = -1.50 D
      state.minusSphere = -1.50;
      expect(state.reflexMotion, equals('neutral'));
    });

    test('4. Retinoscope Sleeve Reversal (Plane vs. Concave Mirror)', () {
      state.patientSphere = 2.00;
      state.workingDistance = 0.0;
      state.sleeveUp = false; // Plane mirror
      expect(state.reflexMotion, equals('with'));

      // Slide sleeve UP to concave mirror mode -> convergent illumination inverts apparent motion
      state.sleeveUp = true;
      expect(state.reflexMotion, equals('against'));
    });

    test('5. With-The-Rule Astigmatism (+1.00 DS -2.00 DC x 180°)', () {
      state.patientSphere = 1.00;
      state.patientCylinder = -2.00;
      state.patientAngle = 180.0; // Power in vertical (90°) meridian is +1.00 - 2.00 = -1.00 D
      state.workingDistance = 0.0;

      // Test Horizontal Sweep (Streak at 90°): evaluates power along 180° = +1.00 D
      state.streakAngle = 90.0;
      state.plusSphere = 0.0;
      expect(state.reflexMotion, equals('with'));

      // Neutralize vertical streak with +1.00 D
      state.plusSphere = 1.00;
      expect(state.reflexMotion, equals('neutral'));

      // Flip streak to 180° (Vertical Sweep): evaluates power along 90° = -1.00 D
      state.flipStreakAxis90();
      expect(state.streakAngle, equals(180.0));
      // With +1.00 D sphere in place, vertical meridian is overcorrected -> AGAINST motion
      expect(state.reflexMotion, equals('against'));

      // Add -2.00 D cylinder at 180° to neutralize second meridian
      state.plusCylinder = -2.00;
      state.plusAxis = 180.0;
      expect(state.reflexMotion, equals('neutral'));
    });

    test('6. Break Phenomenon on Misaligned Astigmatic Axis', () {
      state.patientSphere = 0.0;
      state.patientCylinder = -3.00;
      state.patientAngle = 45.0; // Oblique astigmatism

      // Sweep along 90° (45° misaligned from principal meridian)
      state.streakAngle = 90.0;
      expect(state.isBreakPhenomenonActive, isTrue);
      expect(state.breakDisplacementAngle, greaterThan(5.0));

      // Align streak with 45° principal meridian
      state.streakAngle = 45.0;
      expect(state.isBreakPhenomenonActive, isFalse);
    });

    test('7. Copeland Straddle Axis Refinement', () {
      state.streakAngle = 90.0;
      // Straddle +45°
      state.straddleAxis(1);
      expect(state.streakAngle, equals(135.0));

      // Straddle -45°
      state.straddleAxis(-1);
      expect(state.streakAngle, equals(90.0));
    });

    test('8. Mohindra Pediatric Retinoscopy Working Distance', () {
      state.toggleMohindraMode();
      expect(state.isMohindraMode, isTrue);
      expect(state.workingDistance, equals(2.00)); // 50 cm dark room distance
    });

    test('9. Thibos Fourier Power Vectors Calculation', () {
      // Rx: +2.00 DS -2.00 DC x 180°
      state.patientSphere = 2.00;
      state.patientCylinder = -2.00;
      state.patientAngle = 180.0;

      // Mean Spherical Equivalent M = S + C/2 = 2.00 + (-1.00) = +1.00 D
      expect(state.thibosM, closeTo(1.00, 0.001));

      // J0 = -(C/2) * cos(2 * 180°) = -(-1.00) * 1.0 = +1.00 D
      expect(state.thibosJ0, closeTo(1.00, 0.001));

      // J45 = -(C/2) * sin(2 * 180°) = 0.0
      expect(state.thibosJ45, closeTo(0.00, 0.001));

      // Blur metric B = sqrt(1^2 + 1^2 + 0^2) = sqrt(2) approx 1.414
      expect(state.thibosBlurMetric, closeTo(1.414, 0.01));
    });

    test('10. Clinical Prescription Transposition & Answer Validation', () {
      // Patient Rx: +1.50 DS -2.00 DC x 75°
      // Transposed: -0.50 DS +2.00 DC x 165°
      state.patientSphere = 1.50;
      state.patientCylinder = -2.00;
      state.patientAngle = 75.0;

      expect(state.correctSphere1, equals(1.50));
      expect(state.correctCylinder1, equals(-2.00));
      expect(state.correctAxis1, equals(75.0));

      expect(state.correctSphere2, equals(-0.50));
      expect(state.correctCylinder2, equals(2.00));
      expect(state.correctAxis2, equals(165.0));

      // Validate user answering with standard form
      bool standardCheck = state.checkAnswer(
        userSphere1: 1.50,
        userCylinder1: -2.00,
        userAxis1: 75.0,
        userSphere2: -0.50,
        userCylinder2: 2.00,
        userAxis2: 165.0,
      );
      expect(standardCheck, isTrue);

      // Validate user answering in reverse order
      bool reverseCheck = state.checkAnswer(
        userSphere1: -0.50,
        userCylinder1: 2.00,
        userAxis1: 165.0,
        userSphere2: 1.50,
        userCylinder2: -2.00,
        userAxis2: 75.0,
      );
      expect(reverseCheck, isTrue);
    });

    test('11. Subjective Refraction Duochrome & JCC Logic', () {
      state.patientSphere = -2.00;
      state.patientCylinder = 0.0;
      state.workingDistance = 0.0;
      state.plusSphere = 0.0;
      state.subjectiveModeActive = true;
      state.activeSubjectiveTest = 'Duochrome';

      // Undercorrected myope -> Red clearer
      expect(state.patientSubjectiveResponse, contains('RED'));

      // Fully corrected -> Equal balance
      state.minusSphere = -2.00;
      state.plusLensesSelected = false;
      expect(state.patientSubjectiveResponse, contains('equally clear'));
    });
  });
}
