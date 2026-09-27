import 'package:flutter_test/flutter_test.dart';
import 'package:retinoscopy_simulator/state/retinoscopy_state.dart';
import 'package:retinoscopy_simulator/models/patient_profile.dart';
import 'package:retinoscopy_simulator/services/notification_service.dart';
import 'package:retinoscopy_simulator/services/storage_service.dart';

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

    test('12. Continuous Velocity & 100% Aperture Fill at Neutrality', () {
      state.patientSphere = 0.0;
      state.workingDistance = 0.0;
      state.plusSphere = 0.0;

      // At exact neutral point, pupil fill ratio is 1.0 (100% aperture flash)
      expect(state.reflexMotion, equals('neutral'));
      expect(state.pupilFillRatio, equals(1.0));
      expect(state.reflexVelocityFactor, greaterThan(4.0));

      // 3.00 D away from neutrality -> narrow reflex, slower velocity
      state.patientSphere = 3.00;
      expect(state.reflexMotion, equals('with'));
      expect(state.pupilFillRatio, lessThan(0.50));
      expect(state.reflexVelocityFactor, lessThan(1.50));
    });

    test('13. Copeland ±45° Straddle Metrics & Equilibrium Detection', () {
      // Patient with with-the-rule astigmatism at 90°
      state.patientSphere = 0.0;
      state.patientCylinder = -2.00;
      state.patientAngle = 90.0;
      state.workingDistance = 0.0;

      // When trial axis is correctly aligned at 90° with active cylinder
      state.plusCylinder = 2.00;
      state.plusAxis = 90.0;
      state.plusLensesSelected = true;
      state.streakAngle = 90.0;

      // Straddling ±45° gives symmetric reflex width and brightness
      expect(state.isStraddleEquilibrium, isTrue);
      expect(state.straddleWidthDelta, lessThan(2.5));

      // When trial axis is misaligned at 70° (20° error)
      state.plusAxis = 70.0;
      expect(state.isStraddleEquilibrium, isFalse);
      expect(state.straddleClinicalAdvice, contains('Rotate'));
    });

    test('14. Astigmatic Skew Shear Factor', () {
      state.patientSphere = 0.0;
      state.patientCylinder = -3.00;
      state.patientAngle = 45.0; // Oblique

      // Swept along 90° (off-axis) -> skew shear factor is non-zero
      state.streakAngle = 90.0;
      expect(state.skewShearFactor.abs(), greaterThan(0.1));

      // Aligned on-axis at 45° -> zero skew shear
      state.streakAngle = 45.0;
      expect(state.skewShearFactor.abs(), lessThan(0.01));
    });

    test('15. Clinical Protocol State Machine Progression', () {
      // Start AAO Plus-Cyl Protocol
      state.setProtocol(ClinicalProtocolMode.aaoPlusCyl);
      expect(state.activeProtocol, equals(ClinicalProtocolMode.aaoPlusCyl));
      expect(state.protocolStep, equals(1));
      expect(state.protocolStepTitle, contains('1st Principal Meridian'));

      // Progress through steps
      state.nextProtocolStep();
      expect(state.protocolStep, equals(2));
      state.nextProtocolStep();
      expect(state.protocolStep, equals(3));
      state.nextProtocolStep();
      expect(state.protocolStep, equals(4));
      state.nextProtocolStep();
      expect(state.protocolStep, equals(5));
      expect(state.protocolStepTitle, contains('Net Refraction'));

      // Test Mohindra mode switch
      state.setProtocol(ClinicalProtocolMode.mohindraPediatric);
      expect(state.isMohindraMode, isTrue);
      expect(state.workingDistance, equals(2.00));
    });

    test('16. Javal\'s Rule Keratometry & Corneal Astigmatism Estimation', () {
      // K1 = 43.00 D @ 180°, K2 = 45.00 D @ 90° (With-the-rule corneal delta K = +2.00 D)
      final result = RetinoscopyState.calculateJavalsRule(
        k1Diopters: 43.00,
        k2Diopters: 45.00,
        k1Axis: 180.0,
      );

      expect(result['cornealDeltaK'], closeTo(2.00, 0.001));
      // Total Est Astigmatism = 1.25 * (2.00) - 0.50 = +2.00 D
      expect(result['estimatedAstigmatism'], closeTo(2.00, 0.001));
      expect(result['astigmatismType'], contains('With-The-Rule'));
    });

    test('17. Jackson Cross-Cylinder (JCC) Spherical Equivalent Maintenance', () {
      state.plusSphere = 2.00;
      state.plusCylinder = 1.00;
      state.plusLensesSelected = true;

      // Initial SE = 2.00 + (1.00 / 2) = +2.50 D
      // When adding -0.50 D cylinder, should add +0.25 D sphere to maintain SE at +2.50 D
      state.adjustJccCylinderWithSphericalEquivalence(-0.50);

      expect(state.plusCylinder, closeTo(0.50, 0.001));
      expect(state.plusSphere, closeTo(2.25, 0.001));
      // Final SE = 2.25 + (0.50 / 2) = +2.50 D (Unchanged circle of least confusion)
      double finalSE = state.plusSphere + (state.plusCylinder / 2.0);
      expect(finalSE, closeTo(2.50, 0.001));
    });

    test('18. Clinical Master Library Case Definitions & QR Payload', () {
      final cases = PatientProfile.getCuratedMasterLibrary();
      expect(cases.length, equals(10));

      // Case 4 is WTR Astigmatism
      final wtrCase = cases[3];
      expect(wtrCase.name, contains('With-The-Rule'));
      expect(wtrCase.sphere, equals(1.00));
      expect(wtrCase.cylinder, equals(-2.00));
      expect(wtrCase.axis, equals(180.0));

      // QR Payload serialization & deserialization round-trip
      final qrPayload = wtrCase.toQrPayload();
      expect(qrPayload, startsWith('retino://case?d='));
      final decodedCase = PatientProfile.fromQrPayload(qrPayload);
      expect(decodedCase, isNotNull);
      expect(decodedCase!.sphere, equals(1.00));
      expect(decodedCase.cylinder, equals(-2.00));
      expect(decodedCase.axis, equals(180.0));
    });

    test('19. Beginner Onboarding Optical Rules & Starter Cases', () {
      // 1. Hyperopia (+2.00 D at 67 cm WD) -> With motion neutralized with +3.50 D Gross Lens
      state.patientSphere = 2.00;
      state.patientCylinder = 0.0;
      state.workingDistance = 1.50;
      state.plusSphere = 0.0;
      expect(state.reflexMotion, equals('with'));

      // Neutralized by dialing +3.50 D gross (+2.00 D patient + 1.50 D WD)
      state.plusSphere = 3.50;
      state.plusLensesSelected = true;
      expect(state.reflexMotion, equals('neutral'));
      expect(state.pupilFillRatio, equals(1.0));

      // 2. Myopia (-2.00 D at 67 cm WD) -> Against motion neutralized with -0.50 D Gross Lens
      state.patientSphere = -2.00;
      state.patientCylinder = 0.0;
      state.plusSphere = 0.0;
      state.minusSphere = 0.0;
      state.plusLensesSelected = false;
      expect(state.reflexMotion, equals('against'));

      // Neutralized by dialing -0.50 D gross (-2.00 D patient + 1.50 D WD)
      state.minusSphere = -0.50;
      expect(state.reflexMotion, equals('neutral'));
      expect(state.pupilFillRatio, equals(1.0));

      // 3. Working distance deduction formula: Net = Gross - WD
      double grossLens = 3.50;
      double workingDistanceDiopters = 1.50; // 67 cm
      double netRx = grossLens - workingDistanceDiopters;
      expect(netRx, equals(2.00));
    });

    test('20. Clinical Notification Prompts & Study Reminders Integration', () {
      // Prompt generator generates valid ophthalmic case prompts
      final prompt = NotificationService.getDailyCasePrompt();
      expect(prompt.containsKey('title'), isTrue);
      expect(prompt.containsKey('desc'), isTrue);
      expect(prompt['title']!, contains('Daily Case:'));

      // Reminder time formatting
      StorageService.setReminderTime(8, 30);
      expect(NotificationService.getReminderTimeString(), equals('8:30 AM'));

      StorageService.setReminderTime(14, 15);
      expect(NotificationService.getReminderTimeString(), equals('2:15 PM'));

      // Reminder enablement toggle
      NotificationService.setDailyReminderEnabled(true);
      expect(NotificationService.isDailyReminderEnabled(), isTrue);

      NotificationService.setDailyReminderEnabled(false);
      expect(NotificationService.isDailyReminderEnabled(), isFalse);
    });

    test('21. Modulo 180 Axis Difference Calculation', () {
      expect(RetinoscopyState.calculateAxisDifference(180.0, 0.0), equals(0.0));
      expect(RetinoscopyState.calculateAxisDifference(180.0, 5.0), equals(5.0));
      expect(RetinoscopyState.calculateAxisDifference(175.0, 5.0), equals(10.0));
      expect(RetinoscopyState.calculateAxisDifference(90.0, 90.0), equals(0.0));
      expect(RetinoscopyState.calculateAxisDifference(90.0, 95.0), equals(5.0));
    });

    test('22. Answer Check with Modulo 180 Axis Wrap-Around', () {
      state.patientSphere = 1.00;
      state.patientCylinder = -2.00;
      state.patientAngle = 180.0; // Axis 180°

      // User enters axis 180° vs 0° or 178° -> should pass
      bool check180 = state.checkAnswer(
        userSphere1: 1.00,
        userCylinder1: -2.00,
        userAxis1: 180.0,
        userSphere2: -1.00,
        userCylinder2: 2.00,
        userAxis2: 90.0,
      );
      expect(check180, isTrue);

      bool checkCloseAxis = state.checkAnswer(
        userSphere1: 1.00,
        userCylinder1: -2.00,
        userAxis1: 178.0, // Within 5° tolerance of 180°
        userSphere2: -1.00,
        userCylinder2: 2.00,
        userAxis2: 88.0,  // Within 5° tolerance of 90°
      );
      expect(checkCloseAxis, isTrue);
    });

    test('23. Retinoscopy Answer Calculator Method (Dual Meridian M1/M2 solver)', () {
      // Gross M1 = +3.50 D @ 90°, Gross M2 = +1.50 D @ 180°, WD = +1.50 D (67 cm)
      // Net M1 = +2.00 D @ 90°, Net M2 = 0.00 D @ 180°
      final answer = RetinoscopyState.calculateRetinoscopyAnswer(
        grossM1Power: 3.50,
        grossM1Axis: 90.0,
        grossM2Power: 1.50,
        workingDistance: 1.50,
      );

      expect(answer['netM1'], equals(2.00));
      expect(answer['netM2'], equals(0.00));

      // Plus Cylinder Form: 0.00 DS / +2.00 DC x 180° (Base sphere at lower meridian 180°, +cyl adds power along 90°)
      expect(answer['plusSphere'], equals(0.00));
      expect(answer['plusCylinder'], equals(2.00));
      expect(answer['plusAxis'], equals(180.0));

      // Minus Cylinder Form: +2.00 DS / -2.00 DC x 90° (Base sphere at higher meridian 90°, -cyl subtracts power along 180°)
      expect(answer['minusSphere'], equals(2.00));
      expect(answer['minusCylinder'], equals(-2.00));
      expect(answer['minusAxis'], equals(90.0));

      // Spherical Equivalent: +1.00 DS
      expect(answer['sphericalEquivalent'], equals(1.00));
    });

    test('24. Retinoscopy Answer Calculator when M1 is lower power meridian', () {
      // Gross M1 = +0.50 D @ 45°, Gross M2 = +3.00 D @ 135°, WD = +1.50 D
      // Net M1 = -1.00 D @ 45°, Net M2 = +1.50 D @ 135°
      final answer = RetinoscopyState.calculateRetinoscopyAnswer(
        grossM1Power: 0.50,
        grossM1Axis: 45.0,
        grossM2Power: 3.00,
        workingDistance: 1.50,
      );

      expect(answer['netM1'], equals(-1.00));
      expect(answer['netM2'], equals(1.50));

      // Plus Cylinder Form: -1.00 DS / +2.50 DC x 45°
      expect(answer['plusSphere'], equals(-1.00));
      expect(answer['plusCylinder'], equals(2.50));
      expect(answer['plusAxis'], equals(45.0));

      // Minus Cylinder Form: +1.50 DS / -2.50 DC x 135°
      expect(answer['minusSphere'], equals(1.50));
      expect(answer['minusCylinder'], equals(-2.50));
      expect(answer['minusAxis'], equals(135.0));

      // Spherical Equivalent: +0.25 DS
      expect(answer['sphericalEquivalent'], equals(0.25));
    });

    test('25. Global App Navigation Request Signal', () {
      expect(state.requestedAppTab, isNull);
      state.requestAppTab(2);
      expect(state.requestedAppTab, equals(2));
      state.clearRequestedAppTab();
      expect(state.requestedAppTab, isNull);
    });

    test('26. Dual Meridian Neutral Points Validation & Final Rx Derivation', () {
      // Patient Rx: +1.00 DS / -2.00 DC x 90° (Net M1: +1.00 @ 90°, Net M2: -1.00 @ 180°)
      // Working Distance = +1.50 D
      // Gross M1 (Neutral Point 1): +1.00 + 1.50 = +2.50 D @ 90°
      // Gross M2 (Neutral Point 2): -1.00 + 1.50 = +0.50 D @ 180°
      state.loadPatientRx(sphere: 1.00, cylinder: -2.00, axis: 90.0);
      state.workingDistance = 1.50;

      expect(state.patientGrossM1, closeTo(2.50, 0.001));
      expect(state.patientM1Axis, equals(90.0));
      expect(state.patientGrossM2, closeTo(0.50, 0.001));
      expect(state.patientM2Axis, equals(180.0));
      expect(state.patientNetM1, closeTo(1.00, 0.001));
      expect(state.patientNetM2, closeTo(-1.00, 0.001));

      // Test standard order: M1 = +2.50 @ 90°, M2 = +0.50 @ 180°
      expect(
        state.checkMeridianNeutralPoints(
          userM1Power: 2.50,
          userM1Axis: 90.0,
          userM2Power: 0.50,
          userM2Axis: 180.0,
        ),
        isTrue,
      );

      // Test transposed order: M1 = +0.50 @ 180°, M2 = +2.50 @ 90°
      expect(
        state.checkMeridianNeutralPoints(
          userM1Power: 0.50,
          userM1Axis: 180.0,
          userM2Power: 2.50,
          userM2Axis: 90.0,
        ),
        isTrue,
      );

      // Test incorrect power
      expect(
        state.checkMeridianNeutralPoints(
          userM1Power: 3.50,
          userM1Axis: 90.0,
          userM2Power: 0.50,
          userM2Axis: 180.0,
        ),
        isFalse,
      );

      // Test calculateRetinoscopyAnswer derives Final Rx from these neutral points
      final finalRx = RetinoscopyState.calculateRetinoscopyAnswer(
        grossM1Power: 2.50,
        grossM1Axis: 90.0,
        grossM2Power: 0.50,
        workingDistance: 1.50,
      );

      // Low net is -1.00 @ 180°, High net is +1.00 @ 90°
      // Form 1 (+Cyl): -1.00 DS / +2.00 DC x 180°
      expect(finalRx['plusSphere'], equals(-1.00));
      expect(finalRx['plusCylinder'], equals(2.00));
      expect(finalRx['plusAxis'], equals(180.0));

      // Form 2 (-Cyl): +1.00 DS / -2.00 DC x 90°
      expect(finalRx['minusSphere'], equals(1.00));
      expect(finalRx['minusCylinder'], equals(-2.00));
      expect(finalRx['minusAxis'], equals(90.0));
    });

    test('27. Single-Form Prescription Submission Validation', () {
      state.patientSphere = -1.50;
      state.patientCylinder = -1.00;
      state.patientAngle = 90.0;

      // Student enters only Form 1 matching standard minus-cylinder form (-1.50 / -1.00 x 90)
      bool singleFormStandard = state.checkAnswer(
        userSphere1: -1.50,
        userCylinder1: -1.00,
        userAxis1: 90.0,
        userSphere2: 0.0,
        userCylinder2: 0.0,
        userAxis2: 0.0,
        form2Entered: false,
      );
      expect(singleFormStandard, isTrue);

      // Student enters only Form 1 matching transposed plus-cylinder form (-2.50 / +1.00 x 180)
      bool singleFormTransposed = state.checkAnswer(
        userSphere1: -2.50,
        userCylinder1: 1.00,
        userAxis1: 180.0,
        userSphere2: 0.0,
        userCylinder2: 0.0,
        userAxis2: 0.0,
        form2Entered: false,
      );
      expect(singleFormTransposed, isTrue);

      // Student enters incorrect prescription in Form 1
      bool singleFormWrong = state.checkAnswer(
        userSphere1: -1.50,
        userCylinder1: 1.00,
        userAxis1: 90.0,
        userSphere2: 0.0,
        userCylinder2: 0.0,
        userAxis2: 0.0,
        form2Entered: false,
      );
      expect(singleFormWrong, isFalse);
    });

    test('28. Pure Spherical Error Validation (Axis-Invariance & Single Form)', () {
      state.patientSphere = 2.00;
      state.patientCylinder = 0.0;
      state.patientAngle = 90.0;

      // Single form with any axis (axis has no optical power significance in pure spheres)
      bool sphereMatchAxis45 = state.checkAnswer(
        userSphere1: 2.00,
        userCylinder1: 0.0,
        userAxis1: 45.0,
        userSphere2: 0.0,
        userCylinder2: 0.0,
        userAxis2: 0.0,
        form2Entered: false,
      );
      expect(sphereMatchAxis45, isTrue);

      // Incorrect sphere power
      bool sphereWrong = state.checkAnswer(
        userSphere1: 1.50,
        userCylinder1: 0.0,
        userAxis1: 90.0,
        userSphere2: 0.0,
        userCylinder2: 0.0,
        userAxis2: 0.0,
        form2Entered: false,
      );
      expect(sphereWrong, isFalse);
    });
  });
}
