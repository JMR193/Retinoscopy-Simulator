import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class RetinoscopyState extends ChangeNotifier {
  // --- Subjective Refraction State ---
  bool _subjectiveModeActive = false;
  bool get subjectiveModeActive => _subjectiveModeActive;
  set subjectiveModeActive(bool val) {
    _subjectiveModeActive = val;
    notifyListeners();
  }

  String _activeSubjectiveTest = 'Duochrome'; // Duochrome, JCC Axis, JCC Power
  String get activeSubjectiveTest => _activeSubjectiveTest;
  set activeSubjectiveTest(String val) {
    _activeSubjectiveTest = val;
    notifyListeners();
  }

  int _jccFlipState = 1; // 1 or 2
  int get jccFlipState => _jccFlipState;
  set jccFlipState(int val) {
    _jccFlipState = val;
    notifyListeners();
  }

  // Defocus blur level based on total error between Patient Rx and Trial Lenses
  double get visualBlurSigma {
    double ps = _patientSphere;
    double pc = _patientCylinder;
    double wd = _workingDistance;

    double ts = _plusLensesSelected ? _plusSphere : _minusSphere;
    double tc = _plusLensesSelected ? _plusCylinder : _minusCylinder;

    // Apply working distance offset to find net corrective error
    double netTs = ts - wd;

    // Calculate spherical equivalent defocus
    double sphereError = ps - netTs;
    double cylError = pc - tc;
    
    // Total defocus metric
    double error = sqrt(sphereError * sphereError + cylError * cylError);
    
    // Scale defocus to blur size
    return (error * 4.0).clamp(0.0, 15.0);
  }

  // Patient verbal feedback/responses
  String get patientSubjectiveResponse {
    double ps = _patientSphere;
    double pc = _patientCylinder;
    double pa = _patientAngle;
    double wd = _workingDistance;

    double ts = _plusLensesSelected ? _plusSphere : _minusSphere;
    double tc = _plusLensesSelected ? _plusCylinder : _minusCylinder;
    double ta = _plusLensesSelected ? _plusAxis : _minusAxis;

    double netTs = ts - wd;

    if (activeSubjectiveTest == 'Duochrome') {
      double sphereError = ps - netTs;
      // Duochrome rule: Red clearer if undercorrected myope or overcorrected hyperope (sphereError > 0)
      if (sphereError > 0.12) {
        return "The letters on the RED background are much sharper and blacker.";
      } else if (sphereError < -0.12) {
        return "The letters on the GREEN background are clearer and stand out more.";
      } else {
        return "Both the red and green sides look equally clear and balanced.";
      }
    } 
    
    else if (activeSubjectiveTest == 'JCC Axis') {
      double axisDiff = (ta - pa).abs();
      if (axisDiff > 180) axisDiff = 360 - axisDiff;

      if (axisDiff < 3.0) {
        return "Both positions 1 and 2 look equally clear.";
      }

      bool closerOnFlip1 = (ta > pa && ta - pa < 90) || (pa > ta && pa - ta > 90);
      if (_jccFlipState == 1) {
        return closerOnFlip1 
            ? "Position 1 is clearer. (Rotate axis towards red marker)"
            : "Position 1 is blurry. I prefer Position 2.";
      } else {
        return closerOnFlip1
            ? "Position 2 is blurry. I prefer Position 1."
            : "Position 2 is clearer. (Rotate axis towards red marker)";
      }
    } 
    
    else {
      // JCC Power
      double cylError = pc - tc;
      if (cylError.abs() < 0.12) {
        return "Both positions look equally clear.";
      }

      bool wantsMoreCyl = cylError > 0;
      if (_jccFlipState == 1) {
        return wantsMoreCyl 
            ? "Position 1 is sharper. (Add cylinder power)"
            : "Position 1 is blurry. I prefer Position 2.";
      } else {
        return wantsMoreCyl
            ? "Position 2 is blurry. I prefer Position 1."
            : "Position 2 is sharper. (Add cylinder power)";
      }
    }
  }

  // --- Settings ---
  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;
  set hapticsEnabled(bool val) {
    _hapticsEnabled = val;
    notifyListeners();
  }

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool val) {
    _soundEnabled = val;
    notifyListeners();
  }

  String _selectedThemeColor = 'Blue'; // Blue, Green, Cyan, Orange
  String get selectedThemeColor => _selectedThemeColor;
  set selectedThemeColor(String val) {
    _selectedThemeColor = val;
    StorageService.setThemeColor(val);
    notifyListeners();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool val) {
    _isDarkMode = val;
    StorageService.setDarkMode(val);
    notifyListeners();
  }

  bool _pupilDilated = true;
  bool get pupilDilated => _pupilDilated;
  set pupilDilated(bool val) {
    _pupilDilated = val;
    notifyListeners();
  }

  bool _scissorsMotionActive = false;
  bool get scissorsMotionActive => _scissorsMotionActive;
  set scissorsMotionActive(bool val) {
    _scissorsMotionActive = val;
    notifyListeners();
  }

  // --- Optical Physics Customizations ---
  double _customPupilAperture = 0.52; // Physiological default ratio
  double get customPupilAperture => _customPupilAperture;
  set customPupilAperture(double val) {
    _customPupilAperture = val.clamp(0.25, 0.85);
    notifyListeners();
  }

  double _customFundusLuminance = 1.0; // 100% default luminance
  double get customFundusLuminance => _customFundusLuminance;
  set customFundusLuminance(double val) {
    _customFundusLuminance = val.clamp(0.5, 2.0);
    notifyListeners();
  }

  void resetOpticalPhysicsToDefault() {
    _customPupilAperture = 0.52;
    _customFundusLuminance = 1.0;
    _pupilDilated = true;
    _cataractDensity = 0.0;
    _cornealOpacity = 0.0;
    _scissorsMotionActive = false;
    notifyListeners();
  }

  // --- Score History ---
  final List<Map<String, dynamic>> _testHistory = [];
  List<Map<String, dynamic>> get testHistory => List.unmodifiable(_testHistory);

  void addHistoryEntry({
    required double sphere,
    required double cylinder,
    required double axis,
    required bool correct,
  }) {
    _testHistory.insert(0, {
      'sphere': sphere,
      'cylinder': cylinder,
      'axis': axis,
      'correct': correct,
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }

  void clearHistory() {
    _testHistory.clear();
    notifyListeners();
  }

  // --- Step-by-Step Instructions ---
  final List<String> instructionSteps = [
    "Step 1: Under the explore tab, enter the patient’s refractive error.",
    "Step 2: Set your working distance offset. This correlates to your arm’s length or the distance between your retinoscope and the patient’s eye. An average length is 67 cm, which correlates to 1.50 D working distance offset.",
    "Step 3: Streak the beam of light across the eye to determine “with motion,” “against motion,” and “neutrality.”",
    "Step 4: PLUS CYLINDER REFRACTION: Determine the angle/axis with the least WITH motion. Neutralize this motion by adding sphere power. When the pupil fills with light and there is no movement, you are at neutrality.",
    "Step 5: PLUS CYLINDER REFRACTION: Now angle the streak 90 degrees from the previous position. Add plus power to the cylinder until any WITH motion is neutralized.",
    "Step 6: PLUS CYLINDER REFRACTION: Record the refractive error: neutralizing sphere minus working distance, then cylinder and axis. Example: (+3.50 -2.00) = +1.50 sphere, +0.75 cyl x 90.",
    "Step 7: MINUS CYLINDER REFRACTION: Determine the angle/axis with the most WITH motion. Neutralize this motion by adding sphere power.",
    "Step 8: MINUS CYLINDER REFRACTION: Now angle the streak 90 degrees. Add minus power to the cylinder until any AGAINST motion is neutralized.",
    "Step 9: MINUS CYLINDER REFRACTION: Record the refractive error: neutralizing sphere minus working distance, then cylinder and axis. Example: (+3.50 -2.00) = +1.50 sphere, -0.75 cyl x 90.",
    "Step 10: Click the “new patient” button under the test tab to generate a randomized refractive error. Enter both prescription forms and check your answer."
  ];

  int _currentInstructionStep = 0;
  int get currentInstructionStep => _currentInstructionStep;
  set currentInstructionStep(int value) {
    _currentInstructionStep = value.clamp(0, instructionSteps.length - 1);
    notifyListeners();
  }

  bool _showTutorial = true;
  bool get showTutorial => _showTutorial;
  set showTutorial(bool value) {
    _showTutorial = value;
    notifyListeners();
  }

  // Mode Selection: true = explore, false = test
  bool _isExploreMode = true;
  bool get isExploreMode => _isExploreMode;

  set isExploreMode(bool value) {
    _isExploreMode = value;
    if (!value) {
      // If switching to test mode, generate a random patient
      generateRandomPatient();
    }
    notifyListeners();
  }

  // Active trial lenses tab: true = plus lenses, false = minus lenses
  bool _plusLensesSelected = true;
  bool get plusLensesSelected => _plusLensesSelected;

  set plusLensesSelected(bool value) {
    switchLensModeWithTransposition(value);
  }

  /// Seamlessly shifts trial lens mode and automatically converts/transposes sphere, cylinder, and axis
  void switchLensModeWithTransposition(bool toPlusLenses) {
    if (_plusLensesSelected == toPlusLenses) return;

    if (toPlusLenses) {
      // Switching from Minus to Plus
      if (_minusSphere != 0.0 || _minusCylinder != 0.0) {
        if (_minusCylinder.abs() < 0.01) {
          _plusSphere = _minusSphere;
          _plusCylinder = 0.0;
          _plusAxis = _minusAxis;
        } else {
          _plusSphere = _minusSphere + _minusCylinder;
          _plusCylinder = -_minusCylinder;
          double newAxis = _minusAxis + 90.0;
          if (newAxis > 180.0) newAxis -= 180.0;
          _plusAxis = newAxis;
        }
      }
    } else {
      // Switching from Plus to Minus
      if (_plusSphere != 0.0 || _plusCylinder != 0.0) {
        if (_plusCylinder.abs() < 0.01) {
          _minusSphere = _plusSphere;
          _minusCylinder = 0.0;
          _minusAxis = _plusAxis;
        } else {
          _minusSphere = _plusSphere + _plusCylinder;
          _minusCylinder = -_plusCylinder;
          double newAxis = _plusAxis + 90.0;
          if (newAxis > 180.0) newAxis -= 180.0;
          _minusAxis = newAxis;
        }
      }
    }

    _plusLensesSelected = toPlusLenses;
    notifyListeners();
  }

  // --- Advanced Simulation Modules ---
  bool _isMohindraMode = false;
  bool get isMohindraMode => _isMohindraMode;
  void toggleMohindraMode() {
    _isMohindraMode = !_isMohindraMode;
    if (_isMohindraMode) {
      _workingDistance = 2.00; // 50 cm
    }
    notifyListeners();
  }

  bool _isRayDiagramVisible = false;
  bool get isRayDiagramVisible => _isRayDiagramVisible;
  void toggleRayDiagram() {
    _isRayDiagramVisible = !_isRayDiagramVisible;
    notifyListeners();
  }

  bool _isVectorPlotVisible = false;
  bool get isVectorPlotVisible => _isVectorPlotVisible;
  void toggleVectorPlot() {
    _isVectorPlotVisible = !_isVectorPlotVisible;
    notifyListeners();
  }

  // Pathology Simulation Modes
  bool _isKeratoconus = false;
  bool get isKeratoconus => _isKeratoconus;

  bool _isNuclearCataract = false;
  bool get isNuclearCataract => _isNuclearCataract;

  bool _isCornealScar = false;
  bool get isCornealScar => _isCornealScar;

  void setPathology({bool keratoconus = false, bool cataract = false, bool scar = false}) {
    _isKeratoconus = keratoconus;
    _isNuclearCataract = cataract;
    _isCornealScar = scar;
    if (keratoconus) {
      _patientCylinder = -3.50;
      _patientAngle = 65.0;
    }
    notifyListeners();
  }

  // 14 Official AAO 2020 Clinical Preset Configurations
  // Format: [patientSphere, patientCylinder, patientAngle, workingDistance, plusSphere, plusCylinder, plusAxis, minusSphere, minusCylinder, minusAxis, streakAngle, plusLensesSelected]
  final List<List<dynamic>> presets = [
    [0.0, 0.0, 90.0, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 0: Emmetropia
    [1.0, 1.5, 90.0, 0.0, 0.0, 2.0, 90.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 1: Hyperopic Astigmatism
    [-2.0, -1.0, 90.0, 2.0, 1.0, 0.0, 90.0, 0.0, 0.0, 90.0, 180.0, false], // Preset 2: Myopic Astigmatism (Against)
    [-2.0, -1.0, 90.0, 0.0, 1.0, 0.0, 90.0, 1.5, 0.0, 90.0, 90.0, false], // Preset 3: Minus Cyl Test
    [1.0, 1.0, 90.0, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 4: Low Astigmatism
    [1.0, 2.0, 90.0, 0.0, 0.0, 2.0, 90.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 5: Plus Cyl Lens
    [1.0, 2.0, 90.0, 0.0, 0.0, 1.0, 90.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 6: Plus Cyl Neutralizing
    [1.25, 1.0, 90.0, 0.0, 0.0, 1.0, 180.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 7: Horizontal Axis
    [1.0, 2.0, 90.0, 0.0, 0.0, 1.0, 90.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 8: High Cylinder
    [2.0, 1.0, 180.0, 0.0, 0.0, 1.0, 180.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 9: With-the-Rule
    [1.0, 1.0, 90.0, 0.0, 0.0, 1.0, 180.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 10: Compound Hyperopia
    [1.0, 2.0, 180.0, 0.0, 0.0, 1.0, 180.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 11: Against-the-Rule
    [0.0, 0.0, 90.0, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 90.0, 90.0, true], // Preset 12: Zero Baseline
    [3.0, 1.0, 90.0, 0.0, 1.0, 1.0, 180.0, 0.0, 0.0, 90.0, 180.0, true], // Preset 13: Mixed Astigmatism
  ];

  int _selectedPreset = 1;
  int get selectedPreset => _selectedPreset;

  void applyPreset(int index) {
    if (index < 0 || index >= presets.length) return;
    _selectedPreset = index;
    final preset = presets[index];
    
    _patientSphere = (preset[0] as num).toDouble();
    _patientCylinder = (preset[1] as num).toDouble();
    _patientAngle = (preset[2] as num).toDouble();
    _workingDistance = (preset[3] as num).toDouble();

    // Plus Lenses Values
    _plusSphere = (preset[4] as num).toDouble();
    _plusCylinder = (preset[5] as num).toDouble();
    _plusAxis = (preset[6] as num).toDouble();

    // Minus Lenses Values
    _minusSphere = (preset[7] as num).toDouble();
    _minusCylinder = (preset[8] as num).toDouble();
    _minusAxis = (preset[9] as num).toDouble();

    _streakAngle = (preset[10] as num).toDouble();
    _plusLensesSelected = preset[11] as bool;

    notifyListeners();
  }

  /// Flips streak orientation 90 degrees (orthogonal principal meridian)
  void flipStreakAxis90() {
    _streakAngle = (_streakAngle + 90.0) > 180.0 ? _streakAngle - 90.0 : _streakAngle + 90.0;
    notifyListeners();
  }

  // --- Patient Rx ---
  double _patientSphere = 0.00;
  double get patientSphere => _patientSphere;
  set patientSphere(double value) {
    _patientSphere = value;
    notifyListeners();
  }

  double _patientCylinder = 0.00;
  double get patientCylinder => _patientCylinder;
  set patientCylinder(double value) {
    _patientCylinder = value;
    notifyListeners();
  }

  double _patientAngle = 90.0;
  double get patientAngle => _patientAngle;
  set patientAngle(double value) {
    _patientAngle = value;
    notifyListeners();
  }

  /// Load a saved patient profile's Rx directly into the simulator
  void loadPatientRx({
    required double sphere,
    required double cylinder,
    required double axis,
  }) {
    _patientSphere = sphere;
    _patientCylinder = cylinder;
    _patientAngle = axis;
    _isExploreMode = true;
    _plusSphere = 0.00;
    _plusCylinder = 0.00;
    _plusAxis = 90.0;
    _minusSphere = 0.00;
    _minusCylinder = 0.00;
    _minusAxis = 90.0;
    notifyListeners();
  }

  double _workingDistance = 0.00;
  double get workingDistance => _workingDistance;
  set workingDistance(double value) {
    _workingDistance = value;
    notifyListeners();
  }

  // --- Plus Lenses (Trial) ---
  double _plusSphere = 0.00;
  double get plusSphere => _plusSphere;
  set plusSphere(double value) {
    _plusSphere = value;
    notifyListeners();
  }

  double _plusCylinder = 0.00;
  double get plusCylinder => _plusCylinder;
  set plusCylinder(double value) {
    _plusCylinder = value;
    notifyListeners();
  }

  double _plusAxis = 90.0;
  double get plusAxis => _plusAxis;
  set plusAxis(double value) {
    _plusAxis = value;
    notifyListeners();
  }

  // --- Minus Lenses (Trial) ---
  double _minusSphere = 0.00;
  double get minusSphere => _minusSphere;
  set minusSphere(double value) {
    _minusSphere = value;
    notifyListeners();
  }

  double _minusCylinder = 0.00;
  double get minusCylinder => _minusCylinder;
  set minusCylinder(double value) {
    _minusCylinder = value;
    notifyListeners();
  }

  double _minusAxis = 90.0;
  double get minusAxis => _minusAxis;
  set minusAxis(double value) {
    _minusAxis = value;
    notifyListeners();
  }

  // --- Streak Configuration (Retinoscope) ---
  double _streakAngle = 90.0;
  double get streakAngle => _streakAngle;
  set streakAngle(double value) {
    _streakAngle = value;
    notifyListeners();
  }

  bool _sleeveUp = false; // true = concave mirror (reversed motion), false = plane mirror (standard)
  bool get sleeveUp => _sleeveUp;
  set sleeveUp(bool value) {
    _sleeveUp = value;
    notifyListeners();
  }

  bool get sleeveIsPlaneMirror => !_sleeveUp;
  set sleeveIsPlaneMirror(bool value) {
    _sleeveUp = !value;
    notifyListeners();
  }

  // --- Draggable Beam Offset ---
  double _beamPosition = 0.0; // Current displacement along the sweep axis (-100 to 100)
  double get beamPosition => _beamPosition;
  set beamPosition(double value) {
    _beamPosition = value;
    notifyListeners();
  }

  // --- Reset All to default state ---
  void resetAll() {
    _patientSphere = 0.0;
    _patientCylinder = 0.0;
    _patientAngle = 90.0;
    _workingDistance = 0.0;

    _plusSphere = 0.0;
    _plusCylinder = 0.0;
    _plusAxis = 90.0;

    _minusSphere = 0.0;
    _minusCylinder = 0.0;
    _minusAxis = 90.0;

    _streakAngle = 90.0;
    _plusLensesSelected = true;
    _selectedPreset = 1;
    _beamPosition = 0.0;
    _pupilDilated = true; // Dilation enabled by default
    _scissorsMotionActive = false;
    _cataractDensity = 0.0;
    _cornealOpacity = 0.0;
    
    notifyListeners();
  }

  /// Sets working distance from standard clinical distance (in cm)
  void setWorkingDistancePreset(double distanceCm) {
    if (distanceCm <= 55) {
      _workingDistance = 2.00; // 50 cm -> +2.00 D
    } else if (distanceCm <= 75) {
      _workingDistance = 1.50; // 67 cm -> +1.50 D
    } else {
      _workingDistance = 1.00; // 100 cm -> +1.00 D
    }
    notifyListeners();
  }

  /// Advanced Clinical Case Generator across 4 difficulty tiers
  void generateRandomCase(String difficulty) {
    final rng = Random();
    _plusSphere = 0.0;
    _plusCylinder = 0.0;
    _plusAxis = 90.0;
    _minusSphere = 0.0;
    _minusCylinder = 0.0;
    _minusAxis = 90.0;
    _beamPosition = 0.0;
    _pupilDilated = true;

    switch (difficulty) {
      case 'Beginner':
        // Simple spherical error between -4.00 and +4.00 (0.50 steps)
        _patientSphere = (rng.nextInt(17) - 8) * 0.50;
        _patientCylinder = 0.0;
        _patientAngle = 90.0;
        _scissorsMotionActive = false;
        _cataractDensity = 0.0;
        _cornealOpacity = 0.0;
        break;

      case 'Intermediate':
        // Spherical with regular WTR / ATR astigmatism
        _patientSphere = (rng.nextInt(25) - 12) * 0.50;
        _patientCylinder = -((rng.nextInt(9) + 1) * 0.25);
        _patientAngle = rng.nextBool() ? 90.0 : 180.0;
        _scissorsMotionActive = false;
        _cataractDensity = 0.0;
        _cornealOpacity = 0.0;
        break;

      case 'Advanced':
        // High oblique astigmatism with potential spherical aberration
        _patientSphere = (rng.nextInt(33) - 16) * 0.50;
        _patientCylinder = -((rng.nextInt(17) + 3) * 0.25);
        _patientAngle = (rng.nextInt(36) * 5.0).clamp(5.0, 180.0);
        _scissorsMotionActive = rng.nextDouble() < 0.35;
        _cataractDensity = 0.0;
        _cornealOpacity = 0.0;
        break;

      case 'Pathology':
        // Media opacity case with cataract or corneal scar
        _patientSphere = (rng.nextInt(21) - 10) * 0.50;
        _patientCylinder = -((rng.nextInt(9) + 1) * 0.25);
        _patientAngle = (rng.nextInt(18) * 10.0).clamp(10.0, 180.0);
        _scissorsMotionActive = false;
        if (rng.nextBool()) {
          _cataractDensity = (rng.nextInt(6) + 3) * 0.10; // 0.30 to 0.80
          _cornealOpacity = 0.0;
        } else {
          _cataractDensity = 0.0;
          _cornealOpacity = (rng.nextInt(5) + 2) * 0.10; // 0.20 to 0.60
        }
        break;

      default:
        _patientSphere = 0.0;
        _patientCylinder = 0.0;
        _patientAngle = 90.0;
    }
    notifyListeners();
  }

  // Helper function to calculate angle difference matching CSS/JS
  double _calculateAngleDiff(double a, double b) {
    double diff = a - b;
    if (diff < 0) {
      diff = 180 + diff;
    }
    if (diff > 90) {
      diff = 180 - diff;
    }
    return diff;
  }

  // --- Outputs ---

  // Reflex Width
  double get reflexWidth {
    double ps = _patientSphere;
    double pc = _patientCylinder;
    double pa = _patientAngle;
    double wd = _workingDistance;

    double s = _plusLensesSelected ? _plusSphere : _minusSphere;
    double c = _plusLensesSelected ? _plusCylinder : _minusCylinder;
    double axis = _plusLensesSelected ? _plusAxis : _minusAxis;

    double pala = _calculateAngleDiff(pa, _streakAngle);
    double tala = _calculateAngleDiff(axis, _streakAngle);

    double rw;
    if (_plusLensesSelected) {
      // Plus Mode equation
      rw = ((ps - s) * -2.0) - (wd * 2.0) + ((pala - tala) / 45.0) * pc + (c - pc) * (2.0 - tala / 45.0);
    } else {
      // Minus Mode equation
      rw = ((ps - s) * -2.0) - (wd * 2.0) + ((pala - tala) / 45.0) * pc + (c - pc) * (2.0 - tala / 45.0);
    }

    if (_sleeveUp) {
      rw = -rw;
    }

    // Multiply by pixel multiplier
    return rw * 30.0;
  }

  // Reflex Angle
  double get reflexAngle {
    if (_patientCylinder != 0) {
      double df = _streakAngle - _patientAngle;
      double lb = _streakAngle;
      double rf;
      double md = 2.0;

      if (df > 135) {
        rf = (lb + (df - 45) / 5.0 + 27.0) + (((-(df - 45) / 5.0 - 36.0) * 2.0)) + 72.0 - (df - 180) / md;
      } else if (df < -135) {
        rf = (lb + (df - 45) / 5.0 + 27.0) + (((-(df - 45) / 5.0 - 36.0) * 2.0)) - (df + 180) / md;
      } else if (df < -45) {
        rf = lb + (df - 45) / 5.0 + 27.0 - (-90.0 / md - df / md);
      } else if (df > 45) {
        rf = lb + (df - 45) / 5.0 - 9.0 - (90.0 - df) / md;
      } else {
        rf = lb - (df / 5.0) - (df) / md;
      }
      return rf;
    } else {
      return _streakAngle;
    }
  }

  // Reflex Motion Description
  String get reflexMotion {
    double rw = reflexWidth;
    if (rw.abs() < 1.0) {
      return "neutral";
    } else if (rw < 0) {
      return "with";
    } else {
      return "against";
    }
  }

  // Retina Opacity based on distance to neutrality
  double get retinaOpacity {
    double rw = reflexWidth / 30.0; // unmultiplied
    double widthZeroOpacity = 6.0;
    double maxOpacity = 0.75;
    double correctedOpacity = 0.8;

    double opacity = maxOpacity - rw.abs() / widthZeroOpacity * maxOpacity;
    if (rw == 0.0) {
      opacity = correctedOpacity;
    }
    double dimming = (1.0 - (_cataractDensity * 0.75)) * (1.0 - (_cornealOpacity * 0.6));
    return (opacity * dimming).clamp(0.0, 1.0);
  }

  // Streak Reflection Opacity
  double get reflectionOpacity {
    double rw = (reflexWidth / 30.0).abs();
    double widthZeroOpacityStreak = 20.0;
    double widthFullOpacityStreak = 1.0;
    double correctedOpacityStreak = 1.0;

    double streakOpacity = 1.0;
    if (rw > widthFullOpacityStreak) {
      streakOpacity = correctedOpacityStreak - rw / (widthZeroOpacityStreak - widthFullOpacityStreak);
    }
    double dimming = (1.0 - (_cataractDensity * 0.75)) * (1.0 - (_cornealOpacity * 0.6));
    return (streakOpacity * dimming).clamp(0.0, 1.0);
  }

  // --- Advanced Optical Vergence & Physics Calculations ---

  /// Net spherical-equivalent unneutralized vergence error along swept meridian (in Diopters)
  double get netVergenceError {
    double sweepMeridian = (_streakAngle + 90.0) % 180.0;
    double sweepRad = sweepMeridian * pi / 180.0;

    // Patient power along swept meridian (Euler's Formula: F = S + C * sin^2(alpha - theta))
    double patientAxisRad = _patientAngle * pi / 180.0;
    double patientPower = _patientSphere + _patientCylinder * pow(sin(sweepRad - patientAxisRad), 2);

    // Trial lens power along swept meridian
    double ts = _plusLensesSelected ? _plusSphere : _minusSphere;
    double tc = _plusLensesSelected ? _plusCylinder : _minusCylinder;
    double ta = _plusLensesSelected ? _plusAxis : _minusAxis;
    double trialAxisRad = ta * pi / 180.0;
    double trialPower = ts + tc * pow(sin(sweepRad - trialAxisRad), 2);

    // Net vergence at peephole = Patient + Trial - WorkingDistanceOffset
    double netD = patientPower + trialPower - _workingDistance;
    return _sleeveUp ? -netD : netD;
  }

  /// Apparent reflex sweep velocity multiplier (inversely proportional to vergence error)
  double get reflexVelocityFactor {
    double err = netVergenceError.abs();
    if (err < 0.25) {
      return 3.5; // Very fast, rushing reflex near neutrality
    } else if (err < 0.75) {
      return 2.2;
    } else if (err < 1.50) {
      return 1.4;
    } else {
      return 0.75; // Sluggish motion far from neutrality
    }
  }

  /// Relative reflex luminance / brightness (peaks at neutrality)
  double get reflexIlluminance {
    double err = netVergenceError.abs();
    double base = 1.0 / (1.0 + err * 0.85);
    double dimming = (1.0 - (_cataractDensity * 0.75)) * (1.0 - (_cornealOpacity * 0.6));
    return (base * dimming).clamp(0.15, 1.0);
  }

  // --- Thibos Fourier Power Vector Calculations ---

  /// Mean Spherical Equivalent: M = S + C/2
  double get thibosM => _patientSphere + (_patientCylinder / 2.0);

  /// Jackson Cross-Cylinder at 0°/90°: J0 = -(C/2) * cos(2 * alpha)
  double get thibosJ0 {
    double axisRad = _patientAngle * pi / 180.0;
    return -(_patientCylinder / 2.0) * cos(2.0 * axisRad);
  }

  /// Jackson Cross-Cylinder at 45°/135°: J45 = -(C/2) * sin(2 * alpha)
  double get thibosJ45 {
    double axisRad = _patientAngle * pi / 180.0;
    return -(_patientCylinder / 2.0) * sin(2.0 * axisRad);
  }

  /// Total Dioptric Blur Metric: B = sqrt(M^2 + J0^2 + J45^2)
  double get thibosBlurMetric => sqrt(thibosM * thibosM + thibosJ0 * thibosJ0 + thibosJ45 * thibosJ45);

  // --- Clinical Straddling & Astigmatic Phenomena ---

  /// Straddles the streak 45 degrees to either side of current orientation for axis refinement
  void straddleAxis(int direction) {
    if (direction >= 0) {
      _streakAngle = (_streakAngle + 45.0) > 180.0 ? _streakAngle - 135.0 : _streakAngle + 45.0;
    } else {
      _streakAngle = (_streakAngle - 45.0) <= 0.0 ? _streakAngle + 135.0 : _streakAngle - 45.0;
    }
    notifyListeners();
  }

  /// Break Phenomenon angular displacement between external streak and internal reflex (degrees)
  double get breakDisplacementAngle {
    if (_patientCylinder == 0.0) {
      return 0.0;
    }
    double diff = (_streakAngle - _patientAngle) % 180.0;
    if (diff > 90.0) {
      diff = 180.0 - diff;
    }
    return diff * (_patientCylinder.abs() / 4.0).clamp(0.0, 1.0);
  }

  /// Returns true if break phenomenon is visible (misaligned astigmatic meridian)
  bool get isBreakPhenomenonActive => _patientCylinder.abs() >= 0.50 && breakDisplacementAngle.abs() > 5.0;

  // --- Pathology Simulation State ---
  double _cataractDensity = 0.0; // 0.0 (Clear) to 1.0 (Dense Nuclear Cataract)
  double get cataractDensity => _cataractDensity;
  set cataractDensity(double val) {
    _cataractDensity = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  double _cornealOpacity = 0.0; // 0.0 (Clear) to 1.0 (Dense Corneal Scar)
  double get cornealOpacity => _cornealOpacity;
  set cornealOpacity(double val) {
    _cornealOpacity = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  // --- Randomized Patient Generation for Test Mode ---
  void generateRandomPatient() {
    final random = Random();
    
    // Random Patient Sphere between -20.0 and +20.0 in 0.25 steps
    int sphereSteps = random.nextInt(161) - 80; // -80 to 80
    _patientSphere = sphereSteps * 0.25;

    // Random Patient Cylinder between -6.0 and +6.0 in 0.25 steps
    int cylSteps = random.nextInt(49) - 24; // -24 to 24
    _patientCylinder = cylSteps * 0.25;

    // Random Patient Axis/Angle between 5 and 180 in 5 steps
    _patientAngle = (random.nextInt(36) + 1) * 5.0;

    // Reset controls
    _plusSphere = 0.0;
    _plusCylinder = 0.0;
    _plusAxis = 90.0;
    _minusSphere = 0.0;
    _minusCylinder = 0.0;
    _minusAxis = 90.0;
    _workingDistance = 1.5; // Set a default WD offset like 1.5 D
    _streakAngle = 90.0;
    _beamPosition = 0.0;
    _pupilDilated = false;
    _scissorsMotionActive = false;

    notifyListeners();
  }

  // Getters for correct answers to display to user
  double get correctSphere1 => _patientSphere;
  double get correctCylinder1 => _patientCylinder;
  double get correctAxis1 => _patientAngle;

  double get correctSphere2 => _patientSphere + _patientCylinder;
  double get correctCylinder2 => -_patientCylinder;
  double get correctAxis2 {
    double a = _patientAngle + 90.0;
    if (a > 180.0) a -= 180.0;
    return a;
  }

  // --- Test Validation Logic ---
  // Returns true if correct, false if incorrect
  bool checkAnswer({
    required double userSphere1,
    required double userCylinder1,
    required double userAxis1,
    required double userSphere2,
    required double userCylinder2,
    required double userAxis2,
  }) {
    double correctSphere1 = _patientSphere;
    double correctCylinder1 = _patientCylinder;
    double correctAxis1 = _patientAngle;

    double correctSphere2 = _patientSphere + _patientCylinder;
    double correctCylinder2 = -_patientCylinder;
    double correctAxis2 = _patientAngle + 90.0;
    if (correctAxis2 > 180.0) {
      correctAxis2 -= 180.0;
    }

    bool checkPair(
      double s, double c, double a,
      double refS, double refC, double refA,
    ) {
      if (refC.abs() < 0.05) {
        // Pure spherical case: Axis has no optical significance
        return (s - refS).abs() < 0.13 && c.abs() < 0.13;
      }
      return (s - refS).abs() < 0.13 &&
             (c - refC).abs() < 0.13 &&
             ((a - refA).abs() < 1.0 || (a - refA).abs() == 180.0);
    }

    bool isStandardMatch = checkPair(userSphere1, userCylinder1, userAxis1, correctSphere1, correctCylinder1, correctAxis1) &&
                          checkPair(userSphere2, userCylinder2, userAxis2, correctSphere2, correctCylinder2, correctAxis2);

    bool isTransposedMatch = checkPair(userSphere1, userCylinder1, userAxis1, correctSphere2, correctCylinder2, correctAxis2) &&
                            checkPair(userSphere2, userCylinder2, userAxis2, correctSphere1, correctCylinder1, correctAxis1);

    return isStandardMatch || isTransposedMatch;
  }
}
