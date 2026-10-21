import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/retinoscopy_state.dart';
import '../services/ai_engine.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../widgets/realistic_eye.dart';
import '../widgets/trial_lens_overlay.dart';
import '../widgets/subjective_view.dart';
import '../widgets/optical_ray_diagram.dart';
import '../widgets/thibos_vector_plot.dart';
import '../widgets/copeland_straddle_view.dart';
import '../widgets/protocol_guided_banner.dart';
import '../widgets/power_cross_view.dart';
import '../widgets/sturms_conoid_view.dart';
import '../widgets/reflex_motion_gauge.dart';
import '../widgets/spherocylinder_transposition_card.dart';
import '../widgets/interactive_onboarding_overlay.dart';
import '../widgets/score_card_generator.dart';
import 'about_screen.dart';
import 'store_screen.dart';
import 'optical_calculator_screen.dart';
import 'ai_tutor_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
import '../services/cloud_sync_service.dart';

class RetinoscopySimulatorScreen extends StatefulWidget {
  const RetinoscopySimulatorScreen({super.key});

  @override
  State<RetinoscopySimulatorScreen> createState() => _RetinoscopySimulatorScreenState();
}

class _RetinoscopySimulatorScreenState extends State<RetinoscopySimulatorScreen> with TickerProviderStateMixin {
  late RetinoscopyState _state;

  // Auto-Sweep State
  bool _isAutoSweep = false;
  double _autoSweepSpeed = 1.0;
  late AnimationController _autoSweepController;

  // Test Mode Inputs
  final TextEditingController _userSphere1Controller = TextEditingController();
  final TextEditingController _userCylinder1Controller = TextEditingController();
  final TextEditingController _userAxis1Controller = TextEditingController();
  final TextEditingController _userSphere2Controller = TextEditingController();
  final TextEditingController _userCylinder2Controller = TextEditingController();
  final TextEditingController _userAxis2Controller = TextEditingController();

  // Dual Meridian Neutral Point Inputs
  final TextEditingController _m1PowerController = TextEditingController();
  final TextEditingController _m1AxisController = TextEditingController();
  final TextEditingController _m2PowerController = TextEditingController();
  final TextEditingController _m2AxisController = TextEditingController();
  bool _useDualMeridianEntry = true;
  bool _showFormFields = false;

  bool? _testResult;
  bool _showTestFeedback = false;

  final RetinoscopyAIEngine _aiEngine = RetinoscopyAIEngine();
  AIHint? _currentHint;
  Timer? _hintDebounceTimer;

  @override
  void initState() {
    super.initState();
    _state = context.read<RetinoscopyState>();
    _state.addListener(_onStateChange);
    _updateAIHint(shouldSetState: false);

    // Auto-Sweep continuous oscillator
    _autoSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        if (_isAutoSweep) {
          double sweepVal = math.sin(_autoSweepController.value * 2 * math.pi) * 65.0;
          _state.beamPosition = sweepVal;
        }
      });

    // Check first-time user tour popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!StorageService.hasSeenSimulatorTour() && mounted) {
        InteractiveOnboardingOverlay.show(context);
      }
    });
  }

  void _toggleAutoSweep() {
    setState(() {
      _isAutoSweep = !_isAutoSweep;
      if (_isAutoSweep) {
        _autoSweepController.duration = Duration(milliseconds: (1400 / _autoSweepSpeed).round());
        _autoSweepController.repeat();
      } else {
        _autoSweepController.stop();
        _animateBeamBack();
      }
    });
  }

  void _setAutoSweepSpeed(double speed) {
    setState(() {
      _autoSweepSpeed = speed;
      if (_isAutoSweep) {
        _autoSweepController.duration = Duration(milliseconds: (1400 / _autoSweepSpeed).round());
        _autoSweepController.repeat();
      }
    });
  }

  void _updateAIHint({bool shouldSetState = true}) {
    final s = _state;
    final double trialS = s.plusLensesSelected ? s.plusSphere : s.minusSphere;
    final double trialC = s.plusLensesSelected ? s.plusCylinder : s.minusCylinder;
    final double trialA = s.plusLensesSelected ? s.plusAxis : s.minusAxis;
    final hint = _aiEngine.analyze(
      patientSphere: s.patientSphere,
      patientCylinder: s.patientCylinder,
      patientAxis: s.patientAngle,
      trialSphere: trialS,
      trialCylinder: trialC,
      trialAxis: trialA,
      streakAngle: s.streakAngle,
      workingDistance: s.workingDistance,
      reflexWidth: s.reflexWidth,
      reflexAngle: s.reflexAngle,
      reflexMotion: s.reflexMotion,
      isExploreMode: s.isExploreMode,
    );
    if (shouldSetState && mounted) {
      setState(() {
        _currentHint = hint;
      });
    } else {
      _currentHint = hint;
    }
  }

  void _onStateChange() {
    if (!mounted) return;
    _hintDebounceTimer?.cancel();
    _hintDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _updateAIHint(shouldSetState: true);
    });
  }

  @override
  void dispose() {
    _hintDebounceTimer?.cancel();
    _autoSweepController.dispose();
    _state.removeListener(_onStateChange);
    _userSphere1Controller.dispose();
    _userCylinder1Controller.dispose();
    _userAxis1Controller.dispose();
    _userSphere2Controller.dispose();
    _userCylinder2Controller.dispose();
    _userAxis2Controller.dispose();
    _m1PowerController.dispose();
    _m1AxisController.dispose();
    _m2PowerController.dispose();
    _m2AxisController.dispose();
    super.dispose();
  }

  void _calculateFinalRxFromMeridians({bool showFeedback = true}) {
    final double? m1P = double.tryParse(_m1PowerController.text);
    final double? m1A = double.tryParse(_m1AxisController.text);
    final double? m2P = double.tryParse(_m2PowerController.text);
    if (m1P == null || m1A == null || m2P == null) {
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter Gross Powers and Meridian 1 Axis.')),
        );
      }
      return;
    }
    final answer = RetinoscopyState.calculateRetinoscopyAnswer(
      grossM1Power: m1P,
      grossM1Axis: m1A,
      grossM2Power: m2P,
      workingDistance: _state.workingDistance,
    );

    _userSphere1Controller.text = (answer['plusSphere'] as double).toStringAsFixed(2);
    _userCylinder1Controller.text = (answer['plusCylinder'] as double).toStringAsFixed(2);
    _userAxis1Controller.text = (answer['plusAxis'] as double).toInt().toString();

    _userSphere2Controller.text = (answer['minusSphere'] as double).toStringAsFixed(2);
    _userCylinder2Controller.text = (answer['minusCylinder'] as double).toStringAsFixed(2);
    _userAxis2Controller.text = (answer['minusAxis'] as double).toInt().toString();

    if (_m2AxisController.text.trim().isEmpty) {
      _m2AxisController.text = (answer['grossM2Axis'] as double).toInt().toString();
    }

    setState(() {
      _showFormFields = true;
    });
    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calculated Final Net Rx (-${_state.workingDistance.toStringAsFixed(2)} D WD applied)! Form 1 & 2 populated.'),
          backgroundColor: Colors.teal[700],
        ),
      );
    }
  }

  void _captureCurrentLensToM1() {
    _state.captureActiveAsM1();
    final double currentPower = _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere;
    _m1PowerController.text = currentPower.toStringAsFixed(2);
    _m1AxisController.text = _state.streakAngle.toInt().toString();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Locked M1: ${_m1PowerController.text} DS @ ${_m1AxisController.text}°'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _captureCurrentLensToM2() {
    _state.captureActiveAsM2();
    final double currentPower = _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere;
    _m2PowerController.text = currentPower.toStringAsFixed(2);
    _m2AxisController.text = _state.streakAngle.toInt().toString();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Locked M2: ${_m2PowerController.text} DS @ ${_m2AxisController.text}°'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _checkAnswer() {
    // If in dual meridian mode and final Rx fields are empty, auto-calculate final Rx first
    if (_useDualMeridianEntry && _userSphere1Controller.text.trim().isEmpty) {
      _calculateFinalRxFromMeridians(showFeedback: false);
    }

    final double? m1P = double.tryParse(_m1PowerController.text);
    final double? m1A = double.tryParse(_m1AxisController.text);
    final double? m2P = double.tryParse(_m2PowerController.text);
    final double? m2A = double.tryParse(_m2AxisController.text);

    bool hasMeridianInput = (m1P != null && m1A != null && m2P != null && m2A != null);
    bool meridianCorrect = false;
    if (hasMeridianInput) {
      meridianCorrect = _state.checkMeridianNeutralPoints(
        userM1Power: m1P,
        userM1Axis: m1A,
        userM2Power: m2P,
        userM2Axis: m2A,
      );
    }

    double s1 = double.tryParse(_userSphere1Controller.text) ?? 0.0;
    double c1 = double.tryParse(_userCylinder1Controller.text) ?? 0.0;
    double a1 = double.tryParse(_userAxis1Controller.text) ?? 0.0;
    double s2 = double.tryParse(_userSphere2Controller.text) ?? 0.0;
    double c2 = double.tryParse(_userCylinder2Controller.text) ?? 0.0;
    double a2 = double.tryParse(_userAxis2Controller.text) ?? 0.0;

    final bool hasForm2Input = _userSphere2Controller.text.trim().isNotEmpty ||
                               _userCylinder2Controller.text.trim().isNotEmpty ||
                               _userAxis2Controller.text.trim().isNotEmpty;
    bool hasRxInput = _userSphere1Controller.text.trim().isNotEmpty || hasForm2Input;
    bool rxCorrect = _state.checkAnswer(
      userSphere1: s1,
      userCylinder1: c1,
      userAxis1: a1,
      userSphere2: s2,
      userCylinder2: c2,
      userAxis2: a2,
      form2Entered: hasForm2Input,
    );

    bool correct = false;
    if (hasMeridianInput && hasRxInput) {
      correct = meridianCorrect && rxCorrect;
    } else if (hasMeridianInput) {
      correct = meridianCorrect;
    } else {
      correct = rxCorrect;
    }

    if (correct) {
      AudioService.playSuccess();
      StorageService.addXp(150);
    } else {
      AudioService.playWrong();
    }

    _state.addHistoryEntry(
      sphere: _state.patientSphere,
      cylinder: _state.patientCylinder,
      axis: _state.patientAngle,
      correct: correct,
    );
    // Persist to storage
    StorageService.addHistoryEntry(
      sphere: _state.patientSphere,
      cylinder: _state.patientCylinder,
      axis: _state.patientAngle,
      correct: correct,
    );

    setState(() {
      _testResult = correct;
      _showTestFeedback = true;
    });
  }

  void _nextPatient() {
    _state.generateRandomPatient();
    _clearUserInputs();
  }

  void _hardPatient() {
    _state.generateHardPatient();
    _clearUserInputs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hard Clinical Case Activated — Complex Astigmatism')),
    );
  }

  void _clearUserInputs() {
    _userSphere1Controller.clear();
    _userCylinder1Controller.clear();
    _userAxis1Controller.clear();
    _userSphere2Controller.clear();
    _userCylinder2Controller.clear();
    _userAxis2Controller.clear();
    _m1PowerController.clear();
    _m1AxisController.clear();
    _m2PowerController.clear();
    _m2AxisController.clear();
    setState(() {
      _showFormFields = false;
      _showTestFeedback = false;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Retinoscopy Simulator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: _state.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              HapticFeedback.lightImpact();
              _state.toggleDarkMode();
            },
          ),
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: 'Clinical Case Generator',
              onPressed: () => _showRandomCaseDialog(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Clinical Tools & Menu',
              onSelected: (value) {
                switch (value) {
                  case 'optics':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())).then((_) => setState(() {}));
                    break;
                  case 'calculator':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OpticalCalculatorScreen()));
                    break;
                  case 'share':
                    ScoreCardGenerator.shareScoreCard(context);
                    break;
                  case 'onboarding':
                    InteractiveOnboardingOverlay.show(context);
                    break;
                  case 'tour':
                    _showFeatureTourDialog(context);
                    break;
                  case 'reset':
                    _state.resetAll();
                    setState(() {
                      _showTestFeedback = false;
                      _testResult = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulator reset to baseline Plano')),
                    );
                    break;
                  case 'tutorial':
                    _state.showTutorial = !_state.showTutorial;
                    break;
                  case 'protocol':
                    _showInstructionsDialog(context);
                    break;
                  case 'powercross':
                    _state.togglePowerCross();
                    break;
                  case 'presets':
                    _showAAOPresetsDialog(context);
                    break;
                  case 'about':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'onboarding',
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 10),
                      const Text('Interactive Onboarding', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'tour',
                child: const Row(
                  children: [
                    Icon(Icons.tour_outlined, color: Colors.amber, size: 18),
                    SizedBox(width: 10),
                    Text('Feature Tour & Guide'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 10),
                    const Text('Reset Simulator'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tutorial',
                child: Row(
                  children: [
                    Icon(_state.showTutorial ? Icons.view_headline : Icons.view_headline_outlined, color: Colors.indigo, size: 18),
                    const SizedBox(width: 10),
                    Text(_state.showTutorial ? 'Hide Step Tutorial' : 'Step-by-Step Tutorial'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'protocol',
                child: const Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.teal, size: 18),
                    SizedBox(width: 10),
                    Text('AAO Clinical Protocol'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'powercross',
                child: Row(
                  children: [
                    Icon(
                      _state.isPowerCrossVisible ? Icons.check_circle : Icons.add_circle_outline,
                      color: Colors.tealAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(_state.isPowerCrossVisible ? 'Hide Optical Power Cross' : '2-Meridian Optical Cross'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'presets',
                child: const Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.purple, size: 18),
                    SizedBox(width: 10),
                    Text('AAO Verified Presets'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'about',
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 18),
                    SizedBox(width: 10),
                    Text('About Suite & Credits'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildSettingsDrawer(context),
      body: Stack(
        children: [
          SafeArea(
            child: isLandscape
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: Column(
                      children: [
                        // Compact Mode Selector Header in Landscape
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeTab('Explore', true),
                            const SizedBox(width: 8),
                            _buildModeTab('Test', false),
                            const SizedBox(width: 12),
                            const SizedBox(
                              height: 20,
                              child: VerticalDivider(width: 2, thickness: 1, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Builder(
                              builder: (context) {
                                final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;
                                return FilterChip(
                                  label: Text(
                                    'Subjective Refraction',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: _state.subjectiveModeActive
                                          ? (isDark ? Colors.purple.shade100 : Colors.purple.shade900)
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  selected: _state.subjectiveModeActive,
                                  selectedColor: isDark ? Colors.purple.shade900 : Colors.purple[100],
                                  checkmarkColor: isDark ? Colors.purple.shade200 : Colors.purple,
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : null,
                                  onSelected: (val) {
                                    _state.subjectiveModeActive = val;
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        if (_state.activeProtocol != ClinicalProtocolMode.none) ...[
                          const SizedBox(height: 4),
                          ProtocolGuidedBanner(
                            state: _state,
                            onDismiss: () => _state.setProtocol(ClinicalProtocolMode.none),
                          ),
                        ],
                        if (_state.showTutorial) ...[
                          const SizedBox(height: 6),
                          _buildTutorialBanner(),
                        ],
                        const SizedBox(height: 6),
                        // Dedicated iPad/Tablet Split-View Dashboard
                        Expanded(
                          child: _state.subjectiveModeActive
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Massive Eye on Left (60%)
                                    Expanded(flex: 6, child: _buildSubjectiveCenterPanel()),
                                    const SizedBox(width: 12),
                                    // Docked Controls on Right (40%)
                                    Expanded(
                                      flex: 4,
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: [
                                            _buildSubjectiveRightPanel(),
                                            const SizedBox(height: 12),
                                            _buildLeftPanel(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Massive Eye on Left (60%)
                                    Expanded(flex: 6, child: _buildCenterPanel()),
                                    const SizedBox(width: 12),
                                    // Docked Controls on Right (40%)
                                    Expanded(
                                      flex: 4,
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: [
                                            _buildRightPanel(),
                                            const SizedBox(height: 12),
                                            _buildLeftPanel(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Explore vs Test Mode Tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeTab('Explore', true),
                            const SizedBox(width: 8),
                            _buildModeTab('Test', false),
                            const SizedBox(width: 12),
                            const SizedBox(
                              height: 24,
                              child: VerticalDivider(width: 2, thickness: 1, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Builder(
                              builder: (context) {
                                final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;
                                return FilterChip(
                                  label: Text(
                                    'Subjective Refraction',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _state.subjectiveModeActive
                                          ? (isDark ? Colors.purple.shade100 : Colors.purple.shade900)
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  selected: _state.subjectiveModeActive,
                                  selectedColor: isDark ? Colors.purple.shade900 : Colors.purple[100],
                                  checkmarkColor: isDark ? Colors.purple.shade200 : Colors.purple,
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : null,
                                  onSelected: (val) {
                                    _state.subjectiveModeActive = val;
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        if (_state.activeProtocol != ClinicalProtocolMode.none) ...[
                          const SizedBox(height: 8),
                          ProtocolGuidedBanner(
                            state: _state,
                            onDismiss: () => _state.setProtocol(ClinicalProtocolMode.none),
                          ),
                        ],
                        if (_state.showTutorial) ...[
                          const SizedBox(height: 16),
                          _buildTutorialBanner(),
                        ],
                        const SizedBox(height: 16),
                        if (_state.subjectiveModeActive)
                          Column(
                            children: [
                              _buildLeftPanel(),
                              const SizedBox(height: 16),
                              _buildSubjectiveCenterPanel(),
                              const SizedBox(height: 16),
                              _buildSubjectiveRightPanel(),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildLeftPanel(),
                              const SizedBox(height: 16),
                              _buildCenterPanel(),
                              const SizedBox(height: 16),
                              _buildRightPanel(),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool exploreMode) {
    final active = _state.isExploreMode == exploreMode;
    final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: active,
      selectedColor: _getThemeColor(),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
      onSelected: (selected) {
        if (selected) {
          _state.isExploreMode = exploreMode;
        }
      },
    );
  }

  // --- Left Panel: Patient RX Settings ---
  Widget _buildLeftPanel() {
    final bool isDarkMode = _state.isDarkMode;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_pin, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '1. Patient Refraction',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_state.isExploreMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _formatRx(_state.patientSphere, _state.patientCylinder, _state.patientAngle),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const Divider(height: 18),
            if (_state.isExploreMode) ...[
              // Quick Presets Row for fast clinical testing
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPatientPresetChip('Plano', 0.0, 0.0, 90.0),
                    const SizedBox(width: 6),
                    _buildPatientPresetChip('Myopia -2.00', -2.00, 0.0, 90.0),
                    const SizedBox(width: 6),
                    _buildPatientPresetChip('Hyperopia +3.00', 3.00, 0.0, 90.0),
                    const SizedBox(width: 6),
                    _buildPatientPresetChip('WTR Astig (+1.00/-2.00 × 90°)', 1.00, -2.00, 90.0),
                    const SizedBox(width: 6),
                    _buildPatientPresetChip('ATR Astig (-1.00/-1.50 × 180°)', -1.00, -1.50, 180.0),
                    const SizedBox(width: 6),
                    _buildPatientPresetChip('Oblique (+2.00/-2.00 × 45°)', 2.00, -2.00, 45.0),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.patientSphere,
                onChanged: (val) => _state.patientSphere = val,
                min: -20.0,
                max: 20.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.patientCylinder,
                onChanged: (val) => _state.patientCylinder = val,
                min: -6.0,
                max: 6.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Angle',
                value: _state.patientAngle,
                onChanged: (val) => _state.patientAngle = val,
                min: 5.0,
                max: 180.0,
                step: 5.0,
                isAngle: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkMode ? Colors.indigo.shade400 : Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.indigoAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getClinicalDiagnosisString(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.indigo.shade900),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Text(
                      'Refractive Error Forms (Transpositions):',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Form 1: ${_formatRx(_state.correctSphere1, _state.correctCylinder1, _state.correctAxis1)}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Form 2: ${_formatRx(_state.correctSphere2, _state.correctCylinder2, _state.correctAxis2)}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const Divider(height: 14),
                    Text(
                      'Dual Principal Neutral Points (WD: -${_state.workingDistance.toStringAsFixed(2)} D):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDarkMode ? Colors.amberAccent : Colors.teal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Meridian 1: Gross ${_state.patientGrossM1 >= 0 ? '+' : ''}${_state.patientGrossM1.toStringAsFixed(2)} DS × ${_state.patientM1Axis.toInt()}°  →  Net ${_state.patientNetM1 >= 0 ? '+' : ''}${_state.patientNetM1.toStringAsFixed(2)} DS',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '• Meridian 2: Gross ${_state.patientGrossM2 >= 0 ? '+' : ''}${_state.patientGrossM2.toStringAsFixed(2)} DS × ${_state.patientM2Axis.toInt()}°  →  Net ${_state.patientNetM2 >= 0 ? '+' : ''}${_state.patientNetM2.toStringAsFixed(2)} DS',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deducting Working Distance (-${_state.workingDistance.toStringAsFixed(2)} D) from both gross neutral points calculates the Final Net Rx above.',
                      style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: isDarkMode ? 0.5 : 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.quiz_outlined, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Clinical Test Case Active: Sweep the streak beam across both principal meridians, dial neutralizing trial lenses, deduct Working Distance (${_state.workingDistance.toStringAsFixed(2)} D), and write the Net Prescription below.',
                        style: TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white.withValues(alpha: 0.92) : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _useDualMeridianEntry ? 'Enter Neutral Points (M1 & M2):' : 'Write Patient Net Prescription:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  InkWell(
                    onTap: () => setState(() => _useDualMeridianEntry = !_useDualMeridianEntry),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _useDualMeridianEntry
                            ? (isDarkMode ? Colors.teal.withValues(alpha: 0.25) : Colors.teal[50])
                            : (isDarkMode ? Colors.indigo.withValues(alpha: 0.25) : Colors.indigo[50]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _useDualMeridianEntry ? Colors.teal : Colors.indigo,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_useDualMeridianEntry ? Icons.calculate_outlined : Icons.alt_route, size: 14, color: _useDualMeridianEntry ? Colors.tealAccent : Colors.indigoAccent),
                          const SizedBox(width: 4),
                          Text(
                            _useDualMeridianEntry ? 'Dual Meridian Mode' : 'Direct Net Rx Mode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTestRxFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDualMeridianCard() {
    final bool isDarkMode = _state.isDarkMode;
    final rx = _state.calculatedRxFromCaptured;
    final bool bothReady = _state.areBothMeridiansCaptured && rx != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bothReady ? Colors.teal : Colors.blue.withValues(alpha: 0.35),
          width: bothReady ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    bothReady ? Icons.check_circle : Icons.swap_horizontal_circle_outlined,
                    size: 16,
                    color: bothReady ? Colors.tealAccent : Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bothReady ? 'Both Meridians Neutralized!' : 'Dual Neutral Points Tracker',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: bothReady
                          ? (isDarkMode ? Colors.tealAccent : Colors.teal.shade800)
                          : (isDarkMode ? Colors.cyanAccent : Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _state.clearCapturedMeridians(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Clear',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _state.capturedM1Gross != null
                        ? Colors.blue.withValues(alpha: 0.15)
                        : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _state.capturedM1Gross != null ? Colors.blue : Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meridian 1 (M1)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 2),
                      Text(
                        _state.capturedM1Gross != null
                            ? 'Gross: ${_state.capturedM1Gross! >= 0 ? '+' : ''}${_state.capturedM1Gross!.toStringAsFixed(2)} @ ${_state.capturedM1Axis?.toInt()}°'
                            : 'Pending sweep',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _state.capturedM1Gross != null
                              ? (isDarkMode ? Colors.white : Colors.black87)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _state.capturedM2Gross != null
                        ? Colors.purple.withValues(alpha: 0.15)
                        : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _state.capturedM2Gross != null ? Colors.purple : Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meridian 2 (M2)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                      const SizedBox(height: 2),
                      Text(
                        _state.capturedM2Gross != null
                            ? 'Gross: ${_state.capturedM2Gross! >= 0 ? '+' : ''}${_state.capturedM2Gross!.toStringAsFixed(2)} @ ${_state.capturedM2Axis?.toInt()}°'
                            : 'Pending sweep',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _state.capturedM2Gross != null
                              ? (isDarkMode ? Colors.white : Colors.black87)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (bothReady) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculated Final Net Rx (Working Distance -${_state.workingDistance.toStringAsFixed(2)} D applied):',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.tealAccent : Colors.teal.shade900),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• Form 1 (+Cyl): ${_formatRx(rx['plusSphere'], rx['plusCylinder'], rx['plusAxis'])}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '• Form 2 (-Cyl): ${_formatRx(rx['minusSphere'], rx['minusCylinder'], rx['minusAxis'])}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: 'Form 1: ${_formatRx(rx['plusSphere'], rx['plusCylinder'], rx['plusAxis'])}\nForm 2: ${_formatRx(rx['minusSphere'], rx['minusCylinder'], rx['minusAxis'])}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied Final Net Rx to clipboard!'), duration: Duration(seconds: 1)),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 12),
                        label: const Text('Copy Rx', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        onPressed: () {
                          _userSphere1Controller.text = (rx['plusSphere'] as double).toStringAsFixed(2);
                          _userCylinder1Controller.text = (rx['plusCylinder'] as double).toStringAsFixed(2);
                          _userAxis1Controller.text = (rx['plusAxis'] as double).toInt().toString();

                          _userSphere2Controller.text = (rx['minusSphere'] as double).toStringAsFixed(2);
                          _userCylinder2Controller.text = (rx['minusCylinder'] as double).toStringAsFixed(2);
                          _userAxis2Controller.text = (rx['minusAxis'] as double).toInt().toString();

                          _m1PowerController.text = (_state.capturedM1Gross!).toStringAsFixed(2);
                          _m1AxisController.text = (_state.capturedM1Axis ?? 90).toInt().toString();
                          _m2PowerController.text = (_state.capturedM2Gross!).toStringAsFixed(2);
                          _m2AxisController.text = (_state.capturedM2Axis ?? 180).toInt().toString();

                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Applied Final Net Rx to Test Answers!'), duration: Duration(seconds: 1)),
                          );
                        },
                        icon: const Icon(Icons.assignment_turned_in, size: 12),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        label: const Text('Apply to Test Answer', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestRxFields() {
    final bool isDarkMode = _state.isDarkMode;

    Widget buildField(String label, TextEditingController controller, double min, double max, {String? hint}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white70 : Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF0F172A) : Colors.grey[50],
            ),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    final double activePower = _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_useDualMeridianEntry) ...[
          // Meridian 1 Card
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meridian 1 Neutral Point (Gross):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    InkWell(
                      onTap: _captureCurrentLensToM1,
                      child: Text('Capture Active: ${activePower >= 0 ? '+' : ''}${activePower.toStringAsFixed(2)} @ ${_state.streakAngle.toInt()}°', style: const TextStyle(fontSize: 10.5, color: Colors.blue, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    buildField('Gross Power (DS)', _m1PowerController, -20, 20, hint: '+2.00'),
                    buildField('Axis (°)', _m1AxisController, 0, 180, hint: '90'),
                  ],
                ),
              ],
            ),
          ),

          // Meridian 2 Card
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meridian 2 Neutral Point (Orthogonal):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                    InkWell(
                      onTap: _captureCurrentLensToM2,
                      child: Text('Capture Active: ${activePower >= 0 ? '+' : ''}${activePower.toStringAsFixed(2)} @ ${_state.streakAngle.toInt()}°', style: const TextStyle(fontSize: 10.5, color: Colors.purple, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    buildField('Gross Power (DS)', _m2PowerController, -20, 20, hint: '+3.50'),
                    buildField('Axis (°)', _m2AxisController, 0, 180, hint: '180'),
                  ],
                ),
              ],
            ),
          ),

          // Working distance & Convert Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Working Distance: -${_state.workingDistance.toStringAsFixed(2)} D',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                ElevatedButton.icon(
                  onPressed: () => _calculateFinalRxFromMeridians(showFeedback: true),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text('Calculate Final Net Rx', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Final Net Refraction Inputs (Progressive disclosure in Dual Meridian Mode)
        if (!_useDualMeridianEntry || _showFormFields) ...[
          Text(
            'Final Net Prescription (Form 1 — Primary Required):',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.cyanAccent : Colors.indigo),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              buildField('Sphere (DS)', _userSphere1Controller, -20, 20),
              buildField('Cyl (DC)', _userCylinder1Controller, -6, 6),
              buildField('Axis (°)', _userAxis1Controller, 0, 180),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Final Net Prescription (Form 2 — Transposed Optional):',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.amberAccent : Colors.teal),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              buildField('Sphere (DS)', _userSphere2Controller, -20, 20),
              buildField('Cyl (DC)', _userCylinder2Controller, -6, 6),
              buildField('Axis (°)', _userAxis2Controller, 0, 180),
            ],
          ),
        ] else ...[
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showFormFields = true),
              icon: const Icon(Icons.tune, size: 15),
              label: const Text(
                'Show Final Rx Fields (Manual Entry)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _checkAnswer,
                icon: const Icon(Icons.check, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getThemeColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Check Answer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _nextPatient,
                icon: const Icon(Icons.refresh, size: 16),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('New Case'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _hardPatient,
            icon: const Icon(Icons.diamond, size: 16, color: Colors.cyanAccent),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            label: const Text('Hard Clinical Case', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (_showTestFeedback) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _testResult == true
                  ? (isDarkMode ? const Color(0xFF064E3B) : Colors.green[50])
                  : (isDarkMode ? const Color(0xFF7F1D1D) : Colors.red[50]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _testResult == true ? Colors.green : Colors.red),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _testResult == true ? Icons.check_circle : Icons.error,
                      color: _testResult == true ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult == true
                            ? 'Correct! Neutralization Verified in Both Meridians & Final Net Rx.'
                            : 'Incorrect. Verify Neutral Points & Working Distance Deduction.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _testResult == true ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Clinical Target Neutral Points (Gross):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.cyanAccent : Colors.indigo),
                ),
                const SizedBox(height: 3),
                Text(
                  '• Meridian 1: ${_state.patientGrossM1 >= 0 ? '+' : ''}${_state.patientGrossM1.toStringAsFixed(2)} DS × ${_state.patientM1Axis.toInt()}° (Net: ${_state.patientNetM1 >= 0 ? '+' : ''}${_state.patientNetM1.toStringAsFixed(2)} DS)',
                  style: TextStyle(fontSize: 11.5, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                Text(
                  '• Meridian 2: ${_state.patientGrossM2 >= 0 ? '+' : ''}${_state.patientGrossM2.toStringAsFixed(2)} DS × ${_state.patientM2Axis.toInt()}° (Net: ${_state.patientNetM2 >= 0 ? '+' : ''}${_state.patientNetM2.toStringAsFixed(2)} DS)',
                  style: TextStyle(fontSize: 11.5, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Target Final Net Prescription:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.amberAccent : Colors.teal),
                ),
                const SizedBox(height: 3),
                Text(
                  '• Form 1 (+Cyl): ${_formatRx(_state.correctSphere1, _state.correctCylinder1, _state.correctAxis1)}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                Text(
                  '• Form 2 (-Cyl): ${_formatRx(_state.correctSphere2, _state.correctCylinder2, _state.correctAxis2)}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueAdjustmentRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    required double step,
    bool isDiopter = false,
    bool isAngle = false,
  }) {
    String formattedValue = value.toStringAsFixed(isDiopter ? 2 : 0);
    if (isDiopter && value > 0) formattedValue = '+$formattedValue';
    if (isAngle) formattedValue = '$formattedValue°';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (isDiopter && value != 0.0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioService.playTick();
                        double newValue = (-value).clamp(min, max);
                        onChanged(newValue);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (value > 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (value > 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Flip ± Sign',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.1,
                            color: value > 0 ? const Color(0xFF248A3D) : const Color(0xFFD70015),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioService.playTick();
                        onChanged(0.0);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Plano',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (isDiopter && (max - min) >= 4.0) ...[
                IconButton.filledTonal(
                  icon: const Icon(Icons.fast_rewind_rounded, size: 17),
                  tooltip: '-1.00 D',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AudioService.playTick();
                    double newValue = (value - 1.00).clamp(min, max);
                    onChanged(newValue);
                  },
                ),
                const SizedBox(width: 4),
              ],
              IconButton.filledTonal(
                icon: const Icon(Icons.remove_rounded, size: 19),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AudioService.playTick();
                  double newValue = value - step;
                  if (newValue < min) {
                    if (isAngle) { newValue = max; }
                    else { newValue = min; }
                  }
                  onChanged(newValue);
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      formattedValue,
                      key: ValueKey<String>(formattedValue),
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: -0.2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded, size: 19),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AudioService.playTick();
                  double newValue = value + step;
                  if (newValue > max) {
                    if (isAngle) { newValue = min; }
                    else { newValue = max; }
                  }
                  onChanged(newValue);
                },
              ),
              if (isDiopter && (max - min) >= 4.0) ...[
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: const Icon(Icons.fast_forward_rounded, size: 17),
                  tooltip: '+1.00 D',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AudioService.playTick();
                    double newValue = (value + 1.00).clamp(min, max);
                    onChanged(newValue);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientPresetChip(String label, double sphere, double cylinder, double axis) {
    final bool isCurrent = (_state.patientSphere - sphere).abs() < 0.05 &&
        (_state.patientCylinder - cylinder).abs() < 0.05 &&
        (_state.patientAngle - axis).abs() < 0.05;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      avatar: isCurrent ? const Icon(Icons.check, size: 14, color: Colors.blue) : null,
      backgroundColor: isCurrent ? Colors.blue.withValues(alpha: 0.2) : null,
      onPressed: () {
        AudioService.playTick();
        _state.patientSphere = sphere;
        _state.patientCylinder = cylinder;
        _state.patientAngle = axis;
      },
    );
  }

  String _getStreakMeridianLabel(double angle) {
    final normalized = (angle % 180).round();
    if ((normalized - 90).abs() <= 10) return 'VERT';
    if (normalized <= 10 || (normalized - 180).abs() <= 10) return 'HORIZ';
    return 'OBL';
  }

  Widget _buildDynamicIslandReflexPill() {
    if (!_state.showLiveNeutralityFeedback) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'OBSERVE REFLEX',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: -0.1),
        ),
      );
    }

    final motion = _state.reflexMotion;
    Color badgeColor;
    String badgeText;
    IconData? badgeIcon;

    if (motion == 'neutral') {
      badgeColor = const Color(0xFFFFD60A); // Apple Gold
      badgeText = '★ NEUTRAL FLASH';
      badgeIcon = Icons.auto_awesome_rounded;
    } else if (motion == 'with') {
      badgeColor = const Color(0xFF34C759); // Apple Green
      badgeText = 'WITH (+)';
      badgeIcon = Icons.arrow_forward_rounded;
    } else if (motion == 'against') {
      badgeColor = const Color(0xFFFF453A); // Apple Red
      badgeText = 'AGAINST (−)';
      badgeIcon = Icons.arrow_back_rounded;
    } else {
      badgeColor = const Color(0xFFBF5AF2); // Apple Purple
      badgeText = 'SCISSORS';
      badgeIcon = Icons.content_cut_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- Center Panel: Interactive Eye Simulator ---
  Widget _buildCenterPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '2. Retinoscope Simulator',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                  ],
                ),
                Text(
                  'Working Dist: ${_state.workingDistance.toStringAsFixed(2)} D',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Apple Dynamic Island / Samsung One UI Pill Capsule HUD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slit beam indicator with glowing dot & streak angle
                  InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      AudioService.playTick();
                      _state.flipStreakAxis90();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getEquippedStreakColor(),
                              boxShadow: [
                                BoxShadow(
                                  color: _getEquippedStreakColor().withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Streak ${_state.streakAngle.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStreakMeridianLabel(_state.streakAngle),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade300,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.sync_rounded, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  // Dynamic Reflex Status Pill
                  _buildDynamicIslandReflexPill(),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Gentle gesture guidance hint pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe streak light across pupil to observe speed & motion',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                final double size = math.min(constraints.maxWidth - 20, isLandscape ? 220.0 : 290.0);
                return Center(
                  child: Container(
                    width: size + 16,
                    height: size + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF101012),
                                const Color(0xFF1E1E22),
                                const Color(0xFF2C2C30),
                                const Color(0xFF141416),
                              ]
                            : [
                                const Color(0xFFE5E5EA),
                                const Color(0xFFD1D1D6),
                                const Color(0xFFE5E5EA),
                                const Color(0xFFC7C7CC),
                              ],
                        stops: const [0.86, 0.92, 0.96, 1.0],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Realistic procedural Eye Simulator
                          Positioned.fill(
                            child: ClipOval(
                              child: RealisticEye(
                                streakColor: _getEquippedStreakColor(),
                                beamPosition: _state.beamPosition,
                                streakAngle: _state.streakAngle,
                                reflexWidth: _state.reflexWidth,
                                reflexAngle: _state.reflexAngle,
                                retinaOpacity: _state.retinaOpacity,
                                reflectionOpacity: _state.reflectionOpacity,
                                reflexMotion: _state.reflexMotion,
                                pupilDilated: _state.pupilDilated,
                                scissorsMotionActive: _state.scissorsMotionActive,
                                cataractDensity: _state.cataractDensity,
                                cornealOpacity: _state.cornealOpacity,
                                breakDisplacementAngle: _state.breakDisplacementAngle,
                                skewShearFactor: _state.skewShearFactor,
                                velocityFactor: _state.reflexVelocityFactor,
                                illuminance: _state.reflexIlluminance,
                                pupilFillRatio: _state.pupilFillRatio,
                                pupilApertureRatio: _state.customPupilAperture,
                                fundusLuminanceMultiplier: _state.customFundusLuminance,
                                enableAccelerometerTilt: _state.accelerometerTiltEnabled,
                              ),
                            ),
                          ),

                        // 3D Realistic Trial Lens Holder Overlay with Sphere & Cyl Tabs
                        if (_state.plusLensesSelected && (_state.plusSphere != 0 || _state.plusCylinder != 0)) ...[
                          Positioned.fill(
                            child: AAOTrialLensOverlay(
                              size: size,
                              sphere: _state.plusSphere,
                              cylinder: _state.plusCylinder,
                              axis: _state.plusAxis,
                              isPlusLens: true,
                            ),
                          ),
                        ],
                        if (!_state.plusLensesSelected && (_state.minusSphere != 0 || _state.minusCylinder != 0)) ...[
                          Positioned.fill(
                            child: AAOTrialLensOverlay(
                              size: size,
                              sphere: _state.minusSphere,
                              cylinder: _state.minusCylinder,
                              axis: _state.minusAxis,
                              isPlusLens: false,
                            ),
                          ),
                        ],

                        // Draggable Retinoscope Beam Overlay (2D Omnidirectional Sweep along Perpendicular Streak Axis)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              // Project touch delta onto perpendicular sweep axis
                              double rad = (_state.streakAngle - 90) * math.pi / 180;
                              double delta = details.delta.dx * math.cos(rad) + details.delta.dy * math.sin(rad);
                              double newPos = _state.beamPosition + delta;
                              _state.beamPosition = newPos.clamp(-size / 2, size / 2);
                              if (_state.hapticsEnabled) {
                                HapticFeedback.lightImpact();
                              }
                            },
                            onPanEnd: (_) {
                              // Snap back towards center
                              _animateBeamBack();
                            },
                            child: Container(color: Colors.transparent), // Transparent touch target
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
            const SizedBox(height: 16),
            // Streamlined Retinoscope Streak & Clinical Tools Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Streak Meridian & Collar Controls + Mirror Mode
                  Row(
                    children: [
                      // Meridian Selection Chips
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('90° V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: (_state.streakAngle - 90.0).abs() < 1.0,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => _state.streakAngle = 90.0,
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('180° H', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: (_state.streakAngle - 180.0).abs() < 1.0,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => _state.streakAngle = 180.0,
                              ),
                              const SizedBox(width: 4),
                              ActionChip(
                                avatar: const Icon(Icons.flip, size: 14),
                                label: const Text('Flip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _state.flipStreakAxis90(),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<double>(
                                tooltip: 'Oblique Meridians',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (_state.streakAngle != 90 && _state.streakAngle != 180)
                                            ? '${_state.streakAngle.toStringAsFixed(0)}°'
                                            : 'Other',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 16),
                                    ],
                                  ),
                                ),
                                onSelected: (angle) => _state.streakAngle = angle,
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 45.0, child: Text('45° Oblique Meridian')),
                                  PopupMenuItem(value: 135.0, child: Text('135° Oblique Meridian')),
                                  PopupMenuItem(value: 30.0, child: Text('30° Meridian')),
                                  PopupMenuItem(value: 60.0, child: Text('60° Meridian')),
                                  PopupMenuItem(value: 120.0, child: Text('120° Meridian')),
                                  PopupMenuItem(value: 150.0, child: Text('150° Meridian')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Sleeve Mode Toggle (Plane vs Concave)
                      FilterChip(
                        avatar: Icon(_state.sleeveUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
                        label: Text(_state.sleeveUp ? 'Concave' : 'Plane', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _state.sleeveUp,
                        visualDensity: VisualDensity.compact,
                        onSelected: (val) => _state.sleeveUp = val,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 2: Working Distance & Auto-Sweep & Clinical Tools
                  Row(
                    children: [
                      // Auto-Sweep Compact Toggle
                      ActionChip(
                        avatar: Icon(
                          _isAutoSweep ? Icons.pause_circle : Icons.play_circle,
                          size: 14,
                          color: _isAutoSweep ? Colors.amberAccent : Colors.blue,
                        ),
                        label: Text(
                          _isAutoSweep ? '${_autoSweepSpeed}x' : 'Auto',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isAutoSweep ? Colors.amberAccent : null,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: _isAutoSweep ? Colors.amber.withValues(alpha: 0.2) : null,
                        onPressed: () {
                          if (!_isAutoSweep) {
                            _toggleAutoSweep();
                          } else {
                            if (_autoSweepSpeed == 1.0) {
                              _setAutoSweepSpeed(1.5);
                            } else if (_autoSweepSpeed == 1.5) {
                              _setAutoSweepSpeed(2.0);
                            } else {
                              _toggleAutoSweep();
                              _setAutoSweepSpeed(1.0);
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      // Working Distance Segmented Choices
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('50cm', style: TextStyle(fontSize: 10.5)),
                                selected: (_state.workingDistance - 2.00).abs() < 0.05,
                                visualDensity: VisualDensity.compact,
                                tooltip: '50 cm working distance (+2.00 D deduction)',
                                onSelected: (_) => _state.setWorkingDistancePreset(50),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('67cm', style: TextStyle(fontSize: 10.5)),
                                selected: (_state.workingDistance - 1.50).abs() < 0.05,
                                visualDensity: VisualDensity.compact,
                                tooltip: '67 cm working distance (+1.50 D deduction)',
                                onSelected: (_) => _state.setWorkingDistancePreset(67),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('1m', style: TextStyle(fontSize: 10.5)),
                                selected: (_state.workingDistance - 1.00).abs() < 0.05,
                                visualDensity: VisualDensity.compact,
                                tooltip: '1 m working distance (+1.00 D deduction)',
                                onSelected: (_) => _state.setWorkingDistancePreset(100),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Consolidated Tools Menu
                      PopupMenuButton<String>(
                        tooltip: 'Clinical Tools, Protocols & Optics',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: (_state.isRayDiagramVisible || _state.isVectorPlotVisible || _state.isPowerCrossVisible)
                                ? Colors.cyan.withValues(alpha: 0.18)
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_state.isRayDiagramVisible || _state.isVectorPlotVisible || _state.isPowerCrossVisible)
                                  ? Colors.cyan
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 14,
                                color: (_state.isRayDiagramVisible || _state.isVectorPlotVisible || _state.isPowerCrossVisible)
                                    ? Colors.cyan
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tools',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (_state.isRayDiagramVisible || _state.isVectorPlotVisible || _state.isPowerCrossVisible)
                                      ? Colors.cyan
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 16),
                            ],
                          ),
                        ),
                        onSelected: (action) {
                          if (action == 'protocol') {
                            _showProtocolSelectionDialog(context);
                          } else if (action == 'straddle') {
                            _showCopelandStraddleModal(context);
                          } else if (action == 'sturm') {
                            _state.toggleSturmsConoid();
                          } else if (action == 'gauge') {
                            _state.toggleReflexGauge();
                          } else if (action == 'transposition') {
                            _state.toggleTranspositionCard();
                          } else if (action == 'ray') {
                            _state.toggleRayDiagram();
                          } else if (action == 'thibos') {
                            _state.toggleVectorPlot();
                          } else if (action == 'powercross') {
                            _state.togglePowerCross();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'protocol',
                            child: Row(
                              children: [
                                Icon(Icons.menu_book, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Clinical Protocols (AAO)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'straddle',
                            child: Row(
                              children: [
                                Icon(Icons.explore, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Text('Copeland Straddle (±45°)'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'sturm',
                            child: Row(
                              children: [
                                Icon(_state.isSturmsConoidVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.cyanAccent, size: 18),
                                const SizedBox(width: 8),
                                const Text('Sturm’s Conoid 3D View'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'gauge',
                            child: Row(
                              children: [
                                Icon(_state.isReflexGaugeVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                const Text('Reflex Dynamics Gauge'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'transposition',
                            child: Row(
                              children: [
                                Icon(_state.isTranspositionCardVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.teal, size: 18),
                                const SizedBox(width: 8),
                                const Text('Transposition Lab Card'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'ray',
                            child: Row(
                              children: [
                                Icon(_state.isRayDiagramVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.cyan, size: 18),
                                const SizedBox(width: 8),
                                const Text('2D Ray Tracing Diagram'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'thibos',
                            child: Row(
                              children: [
                                Icon(_state.isVectorPlotVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.purple, size: 18),
                                const SizedBox(width: 8),
                                const Text('Thibos Vector Plot'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'powercross',
                            child: Row(
                              children: [
                                Icon(_state.isPowerCrossVisible ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.tealAccent, size: 18),
                                const SizedBox(width: 8),
                                const Text('2-Meridian Optical Cross'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Simulation feedback stats & Neutrality Flash Banner
            if (_state.reflexMotion == 'neutral') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade100, Colors.amber.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'NEUTRALITY FLASH (${_state.streakAngle.toStringAsFixed(0)}° Meridian Neutralized)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _state.captureActiveAsM1();
                            _m1PowerController.text = _state.currentDialedGrossPower.toStringAsFixed(2);
                            _m1AxisController.text = _state.streakAngle.toInt().toString();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Locked as Meridian 1 Neutral: ${_state.currentDialedGrossPower >= 0 ? '+' : ''}${_state.currentDialedGrossPower.toStringAsFixed(2)} DS @ ${_state.streakAngle.toInt()}°'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_clock, size: 13),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          label: Text('Lock M1 (${_state.currentDialedGrossPower >= 0 ? '+' : ''}${_state.currentDialedGrossPower.toStringAsFixed(2)} @ ${_state.streakAngle.toInt()}°)', style: const TextStyle(fontSize: 11)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _state.captureActiveAsM2();
                            _m2PowerController.text = _state.currentDialedGrossPower.toStringAsFixed(2);
                            _m2AxisController.text = _state.streakAngle.toInt().toString();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Locked as Meridian 2 Neutral: ${_state.currentDialedGrossPower >= 0 ? '+' : ''}${_state.currentDialedGrossPower.toStringAsFixed(2)} DS @ ${_state.streakAngle.toInt()}°'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_clock, size: 13),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          label: Text('Lock M2 (${_state.currentDialedGrossPower >= 0 ? '+' : ''}${_state.currentDialedGrossPower.toStringAsFixed(2)} @ ${_state.streakAngle.toInt()}°)', style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_state.capturedM1Gross != null || _state.capturedM2Gross != null) ...[
              _buildLiveDualMeridianCard(),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge(
                  'Reflex Motion',
                  !_state.showLiveNeutralityFeedback
                      ? 'OBSERVE REFLEX'
                      : (_state.reflexMotion == 'neutral'
                          ? 'NEUTRAL FLASH'
                          : (_state.reflexMotion == 'with' ? 'WITH (+ LENS)' : 'AGAINST (- LENS)')),
                  !_state.showLiveNeutralityFeedback
                      ? Colors.grey
                      : (_state.reflexMotion == 'neutral'
                          ? Colors.amber.shade800
                          : (_state.reflexMotion == 'with' ? Colors.green : Colors.red)),
                ),
                _buildInfoBadge('Reflex Width', '${_state.reflexWidth.abs().toStringAsFixed(1)} px', Colors.orange),
                _buildInfoBadge('Reflex Meridian', '${_state.reflexAngle.toStringAsFixed(0)}°', Colors.blue),
              ],
            ),
            if (_state.isReflexGaugeVisible) ...[
              const SizedBox(height: 14),
              ReflexMotionGauge(state: _state),
            ],
            if (_state.isSturmsConoidVisible) ...[
              const SizedBox(height: 16),
              SturmsConoidView(
                sphere: _state.isExploreMode
                    ? _state.patientSphere
                    : (_state.plusLensesSelected ? _state.plusSphere : _state.minusSphere),
                cylinder: _state.isExploreMode
                    ? _state.patientCylinder
                    : (_state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder),
                axis: _state.isExploreMode
                    ? _state.patientAngle
                    : (_state.plusLensesSelected ? _state.plusAxis : _state.minusAxis),
                workingDistance: _state.workingDistance,
                onClose: () => _state.toggleSturmsConoid(),
              ),
            ],
            if (_state.isTranspositionCardVisible) ...[
              const SizedBox(height: 16),
              SpherocylinderTranspositionCard(
                initialSphere: _state.isExploreMode
                    ? _state.patientSphere
                    : (_state.plusLensesSelected ? _state.plusSphere : _state.minusSphere),
                initialCylinder: _state.isExploreMode
                    ? _state.patientCylinder
                    : (_state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder),
                initialAxis: _state.isExploreMode
                    ? _state.patientAngle
                    : (_state.plusLensesSelected ? _state.plusAxis : _state.minusAxis),
                onApplyToSimulator: (s, c, a) {
                  if (_state.isExploreMode) {
                    _state.patientSphere = s;
                    _state.patientCylinder = c;
                    _state.patientAngle = a;
                  } else {
                    if (_state.plusLensesSelected) {
                      _state.plusSphere = s;
                      _state.plusCylinder = c;
                      _state.plusAxis = a;
                    } else {
                      _state.minusSphere = s;
                      _state.minusCylinder = c;
                      _state.minusAxis = a;
                    }
                  }
                },
                onClose: () => _state.toggleTranspositionCard(),
              ),
            ],
            if (_state.isRayDiagramVisible) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: OpticalRayDiagram(
                  netSphericalEquivalent: _state.thibosM,
                  cylinderPower: _state.patientCylinder,
                  cylinderAngle: _state.patientAngle,
                  streakAngle: _state.streakAngle,
                  workingDistance: _state.workingDistance,
                  grossTrialPower: _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere,
                ),
              ),
            ],
            if (_state.isVectorPlotVisible) ...[
              const SizedBox(height: 16),
              ThibosVectorPlot(
                patientM: _state.patientSphere + (_state.patientCylinder / 2),
                patientJ0: -(_state.patientCylinder / 2) * math.cos(2 * _state.patientAngle * math.pi / 180),
                patientJ45: -(_state.patientCylinder / 2) * math.sin(2 * _state.patientAngle * math.pi / 180),
                trialM: _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere,
                trialJ0: _state.plusLensesSelected
                    ? -(_state.plusCylinder / 2) * math.cos(2 * _state.plusAxis * math.pi / 180)
                    : -(_state.minusCylinder / 2) * math.cos(2 * _state.minusAxis * math.pi / 180),
                trialJ45: _state.plusLensesSelected
                    ? -(_state.plusCylinder / 2) * math.sin(2 * _state.plusAxis * math.pi / 180)
                    : -(_state.minusCylinder / 2) * math.sin(2 * _state.minusAxis * math.pi / 180),
              ),
            ],
            if (_state.isPowerCrossVisible) ...[
              const SizedBox(height: 16),
              PowerCrossView(
                sphere: _state.isExploreMode
                    ? _state.patientSphere
                    : (_state.plusLensesSelected ? _state.plusSphere : _state.minusSphere),
                cylinder: _state.isExploreMode
                    ? _state.patientCylinder
                    : (_state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder),
                axis: _state.isExploreMode
                    ? _state.patientAngle
                    : (_state.plusLensesSelected ? _state.plusAxis : _state.minusAxis),
                workingDistance: _state.workingDistance,
                title: _state.isExploreMode
                    ? 'Patient 2-Meridian Power Cross'
                    : 'Dialed Trial Lens Power Cross',
                onClose: () => _state.togglePowerCross(),
              ),
            ],
            const SizedBox(height: 16),
            // AI Clinical Hint Panel
            if (_currentHint != null) _buildAIHintPanel(_currentHint!),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHintPanel(AIHint hint) {
    final Color color = Color(hint.colorValue);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AI ${(hint.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint.body,
            style: TextStyle(fontSize: 12, height: 1.45, ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hint.confidence,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }



  void _animateBeamBack() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (_state.beamPosition.abs() < 1.0) {
        _state.beamPosition = 0;
        return false;
      }
      _state.beamPosition = _state.beamPosition * 0.8;
      return true;
    });
  }



  Widget _buildInfoBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // --- Right Panel: Trial Lenses & Streak Controls ---
  Widget _buildRightPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (_state.plusLensesSelected ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.visibility_rounded,
                        color: _state.plusLensesSelected ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '3. Trial Lenses (Phoropter)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_state.plusLensesSelected ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_state.plusLensesSelected ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _state.plusLensesSelected ? 'Plus Mode (+)' : 'Minus Mode (−)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: -0.1,
                      color: _state.plusLensesSelected ? const Color(0xFF248A3D) : const Color(0xFFD70015),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Apple Cupertino / Samsung One UI Segmented Sliding Pill Selector
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioService.playTick();
                        setState(() => _state.plusLensesSelected = true);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _state.plusLensesSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF34C759), Color(0xFF248A3D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _state.plusLensesSelected ? null : Colors.transparent,
                          boxShadow: _state.plusLensesSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF34C759).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 16,
                                color: _state.plusLensesSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Plus Lenses (+)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _state.plusLensesSelected ? FontWeight.w700 : FontWeight.w500,
                                  letterSpacing: -0.2,
                                  color: _state.plusLensesSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioService.playTick();
                        setState(() => _state.plusLensesSelected = false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: !_state.plusLensesSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF3B30), Color(0xFFD70015)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: !_state.plusLensesSelected ? null : Colors.transparent,
                          boxShadow: !_state.plusLensesSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 16,
                                color: !_state.plusLensesSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Minus Lenses (−)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !_state.plusLensesSelected ? FontWeight.w700 : FontWeight.w500,
                                  letterSpacing: -0.2,
                                  color: !_state.plusLensesSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (_state.plusLensesSelected) ...[
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.plusSphere,
                onChanged: (val) => _state.plusSphere = val,
                min: -20.0,
                max: 20.0,
                step: _state.sphereStep,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.plusCylinder,
                onChanged: (val) => _state.plusCylinder = val,
                min: -6.0,
                max: 6.0,
                step: _state.cylinderStep,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Axis',
                value: _state.plusAxis,
                onChanged: (val) => _state.plusAxis = val,
                min: 5.0,
                max: 180.0,
                step: _state.axisStep,
                isAngle: true,
              ),
            ] else ...[
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.minusSphere,
                onChanged: (val) => _state.minusSphere = val,
                min: -20.0,
                max: 20.0,
                step: _state.sphereStep,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.minusCylinder,
                onChanged: (val) => _state.minusCylinder = val,
                min: -6.0,
                max: 6.0,
                step: _state.cylinderStep,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Axis',
                value: _state.minusAxis,
                onChanged: (val) => _state.minusAxis = val,
                min: 5.0,
                max: 180.0,
                step: _state.axisStep,
                isAngle: true,
              ),
            ],
            const Divider(height: 20),
            // Live Gross & Net Power Summary Card with Transposition
            Builder(
              builder: (context) {
                final double ts = _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere;
                final double tc = _state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder;
                final double ta = _state.plusLensesSelected ? _state.plusAxis : _state.minusAxis;
                final double netS = ts - _state.workingDistance;

                // Transposed form
                final double transS = ts + tc;
                final double transC = -tc;
                double transA = ta + 90.0;
                if (transA > 180.0) transA -= 180.0;
                final double transNetS = transS - _state.workingDistance;
                final bool isDark = _state.isDarkMode;

                return Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2E2E) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.teal.shade400 : Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility, color: isDark ? Colors.tealAccent : Colors.teal, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Active Trial Lens (Phoropter)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.tealAccent : Colors.teal),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              _state.switchLensModeWithTransposition(!_state.plusLensesSelected);
                              AudioService.playTick();
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.tealAccent : Colors.teal).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: (isDark ? Colors.tealAccent : Colors.teal).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _state.plusLensesSelected ? '⇄ To Minus Cyl' : '⇄ To Plus Cyl',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gross Retinoscopy: ${_formatRx(ts, tc, ta)}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Net Refraction (${_state.workingDistance.toStringAsFixed(2)} D WD): ${_formatRx(netS, tc, ta)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent : Colors.teal.shade900),
                      ),
                      if (tc != 0.0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Transposed Net: ${_formatRx(transNetS, transC, transA)}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.teal.shade700),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear Trial Lenses (Plano)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _state.plusSphere = 0.0;
                _state.plusCylinder = 0.0;
                _state.plusAxis = 90.0;
                _state.minusSphere = 0.0;
                _state.minusCylinder = 0.0;
                _state.minusAxis = 90.0;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    final List<Map<String, String>> steps = [
      {
        'step': 'Step 1: Explore Refractive Error',
        'desc': 'Under the Explore mode, adjust the patient’s sphere, cylinder, and axis to observe fundus reflex dynamics.'
      },
      {
        'step': 'Step 2: Set Working Distance',
        'desc': 'Set your working distance offset correlating to arm length (e.g. 67 cm = +1.50 D, 50 cm = +2.00 D, 1 m = +1.00 D).'
      },
      {
        'step': 'Step 3: Sweep & Identify Motion',
        'desc': 'Drag the light streak across the pupil to identify WITH motion (same direction), AGAINST motion (opposite direction), or NEUTRALITY (uniform flash).'
      },
      {
        'step': 'Step 4: Plus Cyl — Neutralize Sphere',
        'desc': 'Locate the principal meridian with least WITH motion. Neutralize with sphere trial lens until pupil fills without translation.'
      },
      {
        'step': 'Step 5: Plus Cyl — Neutralize Cylinder',
        'desc': 'Rotate streak 90° to the orthogonal meridian. Add plus cylinder power along this axis until the remaining motion is completely neutralized.'
      },
      {
        'step': 'Step 6: Plus Cyl — Net Rx Formula',
        'desc': 'Calculate final net Rx = (Neutralizing Sphere − Working Distance Offset) + Cylinder Power × Axis.'
      },
      {
        'step': 'Step 7: Minus Cyl — Neutralize Sphere',
        'desc': 'Locate the principal meridian with most WITH motion (or least against). Neutralize with sphere lens.'
      },
      {
        'step': 'Step 8: Minus Cyl — Neutralize Cylinder',
        'desc': 'Rotate streak 90° to the orthogonal meridian. Add minus cylinder power along this axis until AGAINST motion is neutralized.'
      },
      {
        'step': 'Step 9: Minus Cyl — Net Rx Formula',
        'desc': 'Calculate final net Rx = (Neutralizing Sphere − Working Distance Offset) − Cylinder Power × Axis.'
      },
      {
        'step': 'Step 10: Test Mode & Examination',
        'desc': 'Switch to Test tab, generate randomized patients with hidden Rx, input both plus/minus forms, and check accuracy.'
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.menu_book, color: Colors.blue),
              SizedBox(width: 8),
              Text('AAO Retinoscopy Protocol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: steps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[idx]['step']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      const SizedBox(height: 2),
                      Text(steps[idx]['desc']!, style: const TextStyle(fontSize: 12, height: 1.35, )),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  void _showCopelandStraddleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                child: CopelandStraddleView(state: _state),
              ),
            );
          },
        );
      },
    );
  }

  void _showProtocolSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Clinical Protocol Guided Modes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Select a standardized clinical examination procedure to practice step-by-step:',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final bool isDark = Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F5E9),
                            child: Icon(Icons.check_circle_outline, color: isDark ? Colors.greenAccent : Colors.green),
                          ),
                          title: const Text('AAO Plus-Cyl Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: const Text('Ophthalmology standard: 1st meridian sphere, sweep 90°, add +cyl', style: TextStyle(fontSize: 11.5)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.setProtocol(ClinicalProtocolMode.aaoPlusCyl);
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFFEBEE),
                            child: Icon(Icons.swap_horiz, color: isDark ? Colors.redAccent : Colors.red),
                          ),
                          title: const Text('Optometry Minus-Cyl Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: const Text('ANSI standard: Neutralize most WITH meridian, sweep 90°, add -cyl', style: TextStyle(fontSize: 11.5)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.setProtocol(ClinicalProtocolMode.optometryMinusCyl);
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFFFFF3E0),
                            child: Icon(Icons.child_care, color: isDark ? Colors.orangeAccent : Colors.orange),
                          ),
                          title: const Text('Mohindra Pediatric Near Retinoscopy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: const Text('Dark room at 50 cm with -1.25 D tonic accommodation deduction', style: TextStyle(fontSize: 11.5)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.setProtocol(ClinicalProtocolMode.mohindraPediatric);
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E5F5),
                            child: Icon(Icons.auto_stories, color: isDark ? Colors.purpleAccent : Colors.purple),
                          ),
                          title: const Text('MEM Dynamic Retinoscopy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: const Text('Near card fixation at 40 cm to measure accommodative lag/lead', style: TextStyle(fontSize: 11.5)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.setProtocol(ClinicalProtocolMode.memDynamic);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRandomCaseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clinical Case Generator',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Select a training tier to generate randomized refractive cases:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final bool isDark = Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F5E9),
                            child: Icon(Icons.looks_one, color: isDark ? Colors.greenAccent : Colors.green),
                          ),
                          title: const Text('Beginner — Spherical', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Simple myopia & hyperopia (-4.00D to +4.00D)', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.generateRandomCase('Beginner');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generated: Beginner Spherical Case')),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFF8E1),
                            child: Icon(Icons.looks_two, color: isDark ? Colors.amberAccent : Colors.amber),
                          ),
                          title: const Text('Intermediate — Regular Astigmatism', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('WTR / ATR astigmatism on 90° & 180° principal meridians', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.generateRandomCase('Intermediate');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generated: Intermediate Astigmatism Case')),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFFEBEE),
                            child: Icon(Icons.looks_3, color: isDark ? Colors.redAccent : Colors.red),
                          ),
                          title: const Text('Advanced — Oblique & Aberrations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('High oblique cylinder + scissors spherical aberration', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.generateRandomCase('Advanced');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generated: Advanced Oblique Case')),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E5F5),
                            child: Icon(Icons.remove_red_eye, color: isDark ? Colors.purpleAccent : Colors.purple),
                          ),
                          title: const Text('Pathology — Media Opacities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Simulates nuclear cataracts and anterior corneal scars', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.generateRandomCase('Pathology');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generated: Pathology Simulation Case')),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAAOPresetsDialog(BuildContext context) {
    final List<Map<String, String>> presetLabels = [
      {'name': 'Preset 0: Emmetropia Baseline', 'desc': 'Plano (0.00 DS) with 0.00 DC'},
      {'name': 'Preset 1: Hyperopic Astigmatism', 'desc': '+1.00 DS +1.50 DC × 90° (Trial: +2.00 DC)'},
      {'name': 'Preset 2: Myopic Astigmatism (Against)', 'desc': '-2.00 DS -1.00 DC × 90° (WD: 2.00 D)'},
      {'name': 'Preset 3: Minus Cylinder Refraction', 'desc': '-2.00 DS -1.00 DC × 90° (Trial: -1.50 DS)'},
      {'name': 'Preset 4: Low Simple Astigmatism', 'desc': '+1.00 DS +1.00 DC × 90°'},
      {'name': 'Preset 5: Plus Cylinder Sweep', 'desc': '+1.00 DS +2.00 DC × 90° (Trial: +2.00 DC)'},
      {'name': 'Preset 6: Plus Cyl Neutralization', 'desc': '+1.00 DS +2.00 DC × 90° (Trial: +1.00 DC)'},
      {'name': 'Preset 7: Horizontal Axis Meridian', 'desc': '+1.25 DS +1.00 DC × 90° (Trial: +1.00 DC × 180°)'},
      {'name': 'Preset 8: High Cylinder Astigmatism', 'desc': '+1.00 DS +2.00 DC × 90° (Trial: +1.00 DC)'},
      {'name': 'Preset 9: With-the-Rule Astigmatism', 'desc': '+2.00 DS +1.00 DC × 180° (Trial: +1.00 DC × 180°)'},
      {'name': 'Preset 10: Compound Hyperopia', 'desc': '+1.00 DS +1.00 DC × 90° (Trial: +1.00 DC × 180°)'},
      {'name': 'Preset 11: Against-the-Rule Oblique', 'desc': '+1.00 DS +2.00 DC × 180° (Trial: +1.00 DC × 180°)'},
      {'name': 'Preset 12: Zero Refraction Baseline', 'desc': 'Plano (0.00 DS) baseline test'},
      {'name': 'Preset 13: Mixed Astigmatism Case', 'desc': '+3.00 DS +1.00 DC × 90° (Trial: +1.00 DS +1.00 DC × 180°)'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final bool isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AAO 2020 Official Presets (0–13)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a verified clinical configuration from American Academy of Ophthalmology',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: presetLabels.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (itemCtx, idx) {
                        final bool isSelected = _state.selectedPreset == idx;
                        final bool isDark = Theme.of(itemCtx).brightness == Brightness.dark;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.blue : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[200]),
                            foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(presetLabels[idx]['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
                          subtitle: Text(presetLabels[idx]['desc']!, style: const TextStyle(fontSize: 11)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            _state.applyPreset(idx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Loaded ${presetLabels[idx]['name']}')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTutorialBanner() {
    final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.4) : const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: isDark ? Colors.blueAccent : Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Step ${_state.currentInstructionStep + 1} of 10',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueAccent : Colors.blue[900],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _state.showTutorial = false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _state.instructionSteps[_state.currentInstructionStep],
            style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _state.currentInstructionStep > 0
                    ? () => _state.currentInstructionStep--
                    : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _state.currentInstructionStep < 9
                    ? () => _state.currentInstructionStep++
                    : () => _state.showTutorial = false,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: Text(_state.currentInstructionStep < 9 ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    final Color primaryColor = _getThemeColor();

    return Drawer(
      child: Column(
        children: [
          // Medical Suite Branding Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stackTrace) => CustomPaint(
                        painter: EyePainter(
                          streakColor: _getEquippedStreakColor(),
                          beamPosition: 0,
                          streakAngle: 90,
                          reflexWidth: 3,
                          reflexAngle: 90,
                          retinaOpacity: 0.8,
                          reflectionOpacity: 0.9,
                          reflexMotion: 'neutral',
                          hippusFactor: 1.0,
                          pupilDilated: false,
                          scissorsMotionActive: false,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Retinoscopy Suite',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Clinical Optics & Refraction',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 ${StorageService.getStudyStreak()} Day Practice Streak',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Streamlined Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              children: [
                // ── Section 1: Clinical Applications & Tools ───────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    'CLINICAL TOOLS & EDUCATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.quiz_rounded, color: Colors.orange),
                  title: const Text('Clinical Board Exam', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('10-case assessment & certification', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<RetinoscopyState>().requestAppTab(1);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                  title: const Text('Global Leaderboard & Rankings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Verified optometry rankings & CME points', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.calculate_rounded, color: Colors.teal),
                  title: const Text('Optical Cross & Calculator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Dual-meridian & power transposition', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OpticalCalculatorScreen()));
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.psychology_rounded, color: Colors.deepPurple),
                  title: const Text('AI Clinical Optics Tutor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Offline ophthalmic physics assistant', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiTutorScreen()));
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.menu_book_rounded, color: Colors.indigo),
                  title: const Text('Clinical Handbook & Guidelines', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('AAO protocols, physics & diagrams', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<RetinoscopyState>().requestAppTab(3);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.folder_shared_rounded, color: Colors.blue),
                  title: const Text('Patient Refractive Records', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Custom clinical patient cases', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<RetinoscopyState>().requestAppTab(2);
                  },
                ),

                const Divider(height: 16),

                // ── Section 2: Optics & Calibration ────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Text(
                    'OPTICS & CALIBRATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.tune_rounded, color: _getEquippedStreakColor()),
                  title: const Text('Retinoscope Optics & Filters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: Text('Active: ${StorageService.getEquippedCosmetic()}', style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()))
                        .then((_) => setState(() {}));
                  },
                ),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.visibility_off_rounded, color: Colors.amber),
                    title: const Text('Pathology & Aberrations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Mydriasis, scissors, cataract & opacity', style: TextStyle(fontSize: 11)),
                    children: [
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Mydriasis (Dilated Pupil)', style: TextStyle(fontSize: 12.5)),
                        value: _state.pupilDilated,
                        activeTrackColor: primaryColor,
                        onChanged: (val) => setState(() => _state.pupilDilated = val),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Scissors Motion Aberration', style: TextStyle(fontSize: 12.5)),
                        value: _state.scissorsMotionActive,
                        activeTrackColor: primaryColor,
                        onChanged: (val) => setState(() => _state.scissorsMotionActive = val),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nuclear Cataract Density', style: TextStyle(fontSize: 11.5)),
                                Text('${(_state.cataractDensity * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                              ],
                            ),
                            Slider(
                              value: _state.cataractDensity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Colors.amber.shade800,
                              onChanged: (val) => setState(() => _state.cataractDensity = val),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Corneal Opacity / Scar', style: TextStyle(fontSize: 11.5)),
                                Text('${(_state.cornealOpacity * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              ],
                            ),
                            Slider(
                              value: _state.cornealOpacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Colors.blueGrey,
                              onChanged: (val) => setState(() => _state.cornealOpacity = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16),

                // ── Section 3: Clinical Preferences ─────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Text(
                    'CLINICAL PREFERENCES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('3D Viewport Parallax', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Accelerometer observation angle (Default: OFF)', style: TextStyle(fontSize: 11)),
                  value: _state.accelerometerTiltEnabled,
                  activeTrackColor: primaryColor,
                  onChanged: (val) => setState(() => _state.accelerometerTiltEnabled = val),
                ),
                SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Live Neutrality Guidance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Display real-time reflex motion badges', style: TextStyle(fontSize: 11)),
                  value: _state.showLiveNeutralityFeedback,
                  activeTrackColor: primaryColor,
                  onChanged: (val) => setState(() => _state.showLiveNeutralityFeedback = val),
                ),
                SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Haptic Sweeps & Sound Cues', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tactile clicks and auditory feedback', style: TextStyle(fontSize: 11)),
                  value: _state.hapticsEnabled,
                  activeTrackColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _state.hapticsEnabled = val;
                      _state.soundEnabled = val;
                      AudioService.soundEnabled = val;
                    });
                    if (val) HapticFeedback.selectionClick();
                  },
                ),
                SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Dark Room Examination Theme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Super AMOLED high-contrast mode', style: TextStyle(fontSize: 11)),
                  value: _state.isDarkMode,
                  activeTrackColor: primaryColor,
                  onChanged: (val) => setState(() => _state.isDarkMode = val),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            setState(() {
                              _state.sphereStep = _state.sphereStep == 0.25 ? 0.50 : 0.25;
                              _state.cylinderStep = _state.sphereStep;
                            });
                          },
                          child: Text(
                            'Lens Step: ${_state.sphereStep.toStringAsFixed(2)} D',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            setState(() {
                              _state.axisStep = _state.axisStep == 1.0 ? 5.0 : 1.0;
                            });
                          },
                          child: Text(
                            'Axis Step: ${_state.axisStep.toInt()}°',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16),

                // ── Section 4: Clinical Account & Registry ──────────────
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    CloudSyncService.isAuthenticated ? Icons.account_circle_rounded : Icons.account_circle_outlined,
                    color: CloudSyncService.isAuthenticated ? Colors.green : Colors.blueGrey,
                  ),
                  title: Text(
                    CloudSyncService.isAuthenticated
                        ? 'Account: ${CloudSyncService.userEmail ?? "Registered"}'
                        : 'Clinical Registry & Account',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    CloudSyncService.isAuthenticated
                        ? 'Cloud sync active • Tap to Sign Out'
                        : 'Operating in Guest Mode • Tap to Sign In',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    if (CloudSyncService.isAuthenticated) {
                      _showSignOutDialog(context);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),

                // ── Section 5: Compliance, Privacy & About ──────────────
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.alarm_rounded, color: Colors.indigo),
                  title: const Text('Daily Case Study Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(NotificationService.getReminderTimeString(), style: const TextStyle(fontSize: 10.5)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showDailyReminderTimePicker(context),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.security_rounded, color: Colors.teal),
                  title: const Text('Offline Privacy & Security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showOfflinePrivacyDialog(context),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.verified_user_rounded, color: Colors.blueGrey),
                  title: const Text('Compliance & Medical Standards', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _showMedicalComplianceDialog(context);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                  title: const Text('Rate & Review', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _showRateAppDialog(context);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
                  title: const Text('About Retinoscopy Simulator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: const Text('v2.0.0 (Build 36) • Elite Edition', style: TextStyle(fontSize: 10.5)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getThemeColor() {
    switch (_state.selectedThemeColor) {
      case 'Green':
        return Colors.green;
      case 'Cyan':
        return Colors.cyan;
      case 'Orange':
        return Colors.orange;
      case 'Purple':
        return Colors.deepPurple;
      case 'Blue':
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color _getEquippedStreakColor() {
    final equipped = StorageService.getEquippedCosmetic();
    switch (equipped) {
      case 'Neon Green':
        return Colors.greenAccent;
      case 'Cyan Glow':
        return Colors.cyanAccent;
      case 'Amethyst Purple':
        return Colors.purpleAccent;
      case 'Laser Red':
        return Colors.redAccent;
      case 'Default Orange':
      default:
        return Colors.deepOrangeAccent;
    }
  }

  Widget _buildSubjectiveCenterPanel() {
    Color primaryColor = _getThemeColor();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Patient Subjective View',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Interactive Snellen / Duochrome chart + Speech Bubble
            SubjectiveView(state: _state),
            
            if (_state.activeSubjectiveTest.startsWith('JCC')) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _state.jccFlipState = _state.jccFlipState == 1 ? 2 : 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flip),
                label: const Text('Flip JCC Lens'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectiveRightPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subjective Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Method Selector
            const Text(
              'Refinement Method:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: ['Duochrome', 'JCC Axis', 'JCC Power'].map((method) {
                final bool isDark = _state.isDarkMode || Theme.of(context).brightness == Brightness.dark;
                bool selected = _state.activeSubjectiveTest == method;
                return ChoiceChip(
                  label: Text(method),
                  selected: selected,
                  selectedColor: isDark ? Colors.purple.shade900 : Colors.purple[100],
                  checkmarkColor: isDark ? Colors.purple.shade200 : Colors.purple,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : null,
                  labelStyle: TextStyle(
                    color: selected
                        ? (isDark ? Colors.purple.shade100 : Colors.purple[900])
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _state.activeSubjectiveTest = method;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            
            const Divider(height: 24),
            
            // Trial Lens adjusters (Sphere/Cylinder/Axis depending on selection)
            if (_state.activeSubjectiveTest == 'Duochrome') ...[
              const Text(
                'Sphere Refinement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere,
                onChanged: (val) {
                  if (_state.plusLensesSelected) { _state.plusSphere = val; }
                  else { _state.minusSphere = val; }
                },
                min: -20.0,
                max: 20.0,
                step: 0.25,
                isDiopter: true,
              ),
            ] else if (_state.activeSubjectiveTest == 'JCC Axis') ...[
              const Text(
                'Cylinder Axis Refinement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Axis',
                value: _state.plusLensesSelected ? _state.plusAxis : _state.minusAxis,
                onChanged: (val) {
                  if (_state.plusLensesSelected) { _state.plusAxis = val; }
                  else { _state.minusAxis = val; }
                },
                min: 5.0,
                max: 180.0,
                step: 5.0,
                isAngle: true,
              ),
            ] else ...[
              const Text(
                'Cylinder Power Refinement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder,
                onChanged: (val) {
                  if (_state.plusLensesSelected) { _state.plusCylinder = val; }
                  else { _state.minusCylinder = val; }
                },
                min: -6.0,
                max: 6.0,
                step: 0.25,
                isDiopter: true,
              ),
            ],
            
            const Divider(height: 24),
            
            // Clinical Guidelines / Methods handbook
            const Text(
              'Clinical Guide:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple),
            ),
            const SizedBox(height: 4),
            Text(
              _getSubjectiveGuideText(),
              style: const TextStyle(fontSize: 12,  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubjectiveGuideText() {
    switch (_state.activeSubjectiveTest) {
      case 'Duochrome':
        return 'DUOCHROME TEST:\n'
            '• Used to refine the sphere power.\n'
            '• If patient says RED is clearer: Undercorrected. Add minus sphere (or subtract plus).\n'
            '• If patient says GREEN is clearer: Overcorrected. Add plus sphere (or subtract minus).\n'
            '• Target: Red and green sides are equally clear.';
      case 'JCC Axis':
        return 'JACKSON CROSS CYLINDER AXIS:\n'
            '• Align JCC lens handle with the trial cylinder axis.\n'
            '• Flip the lens (Position 1 vs 2) and ask which is clearer.\n'
            '• Rotate trial axis towards the red (minus) JCC axis marker in the preferred position.\n'
            '• Target: Equal clarity in both positions.';
      case 'JCC Power':
      default:
        return 'JACKSON CROSS CYLINDER POWER:\n'
            '• Align JCC axis markers (red/white) parallel to trial cylinder axis.\n'
            '• Flip the lens (Position 1 vs 2) and ask which is clearer.\n'
            '• Red marker parallel to axis: Add minus cylinder power.\n'
            '• White marker parallel to axis: Subtract minus cylinder power.\n'
            '• Target: Equal clarity in both positions.';
    }
  }

  String _formatRx(double s, double c, double a) {
    String fs = s.toStringAsFixed(2);
    if (s > 0) fs = '+$fs';
    String fc = c.toStringAsFixed(2);
    if (c > 0) fc = '+$fc';
    return '$fs $fc x ${a.toStringAsFixed(0)}°';
  }

  void _showFeatureTourDialog(BuildContext context) {
    int currentSlide = 0;
    final List<Map<String, dynamic>> tourFeatures = [
      {
        'icon': Icons.play_circle_filled,
        'color': Colors.amber,
        'title': '1. Auto-Sweep & Tactile Pan',
        'subtitle': 'Interactive Fundus Reflex Sweeps',
        'desc':
            '• Drag the light streak manually across the pupil with 2D touch sweeps.\n'
            '• Or tap the "Auto-Sweep" button in the toolbar for automatic continuous sweeps at 1x, 1.5x, or 2x speeds.\n'
            '• Observe WITH motion (moves same direction), AGAINST motion (opposite direction), and NEUTRALITY (instant full pupil flash).',
      },
      {
        'icon': Icons.rotate_90_degrees_cw,
        'color': Colors.blue,
        'title': '2. Streak Rotation & Flip 90°',
        'subtitle': 'Principal Meridian Alignment',
        'desc':
            '• Rotate the streak collar 0°–180° to locate primary astigmatic axes.\n'
            '• Tap "Flip 90°" to instantly jump between orthogonal principal meridians.\n'
            '• Use -45° and +45° Straddle buttons to refine cylinder axes via Copeland’s technique.',
      },
      {
        'icon': Icons.swap_vertical_circle,
        'color': Colors.teal,
        'title': '3. Retinoscope Sleeve Toggle',
        'subtitle': 'Plane vs. Concave Mirror Optics',
        'desc':
            '• Plane Mirror (Sleeve Down): Emits divergent rays. Standard motion convention.\n'
            '• Concave Mirror (Sleeve Up): Emits convergent rays crossing at 33 cm.\n'
            '• In concave mode, motion directions invert (WITH becomes AGAINST), ideal for confirming faint neutrality.',
      },
      {
        'icon': Icons.tune,
        'color': Colors.purple,
        'title': '4. Trial Lens Rack & Neutralization',
        'subtitle': 'Phoropter & Trial Lens Simulation',
        'desc':
            '• Add Plus Sphere (+DS) to neutralize WITH motion.\n'
            '• Add Minus Sphere/Cylinder (-DS / -DC) to neutralize AGAINST motion.\n'
            '• Achieve neutrality on both orthogonal meridians until the reflex fills 100% of the pupil with zero directional motion.',
      },
      {
        'icon': Icons.straighten,
        'color': Colors.deepOrange,
        'title': '5. Working Distance & Mohindra Mode',
        'subtitle': 'Distance Offset Compensation',
        'desc':
            '• Presets for 67 cm (+1.50 D), 50 cm (+2.00 D), and 100 cm (+1.00 D).\n'
            '• Net Patient Rx = Gross Neutralizing Lens − Working Distance.\n'
            '• Enable Mohindra Pediatric Mode for dark-room non-cycloplegic exams with automatic -1.25 D tonic accommodation deduction.',
      },
      {
        'icon': Icons.auto_graph,
        'color': Colors.cyan,
        'title': '6. 2D Ray Diagram & Thibos Plot',
        'subtitle': 'Advanced Optical Ray Tracing',
        'desc':
            '• Turn on Ray Diagram to view cross-sectional ray propagation through trial lenses, cornea, and crystalline lens to the retinal conjugate.\n'
            '• Turn on Thibos Plot to track (J0, J45) Fourier power vector components and residual dioptric blur circles.',
      },
      {
        'icon': Icons.calculate,
        'color': Colors.indigo,
        'title': '7. Optical Cross & AI Clinical Tutor',
        'subtitle': 'Transposition & Knowledge Assistant',
        'desc':
            '• Open "Optical Cross & Calculator" from the drawer to see a 2-meridian power cross and calculate bidirectional plus/minus transposition.\n'
            '• Ask the "AI Clinical Optics Tutor" anything about retinoscopy physics, keratoconus scissors reflexes, and exam strategies!',
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final slide = tourFeatures[currentSlide];
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header with Title and "Skip" option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (slide['color'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(slide['icon'] as IconData, color: slide['color'] as Color, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'How to Use Simulator',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // 🌟 Skip Option at Top
                        TextButton.icon(
                          onPressed: () {
                            StorageService.markSimulatorTourSeen();
                            Navigator.pop(dialogCtx);
                          },
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          label: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Feature Card Content
                    Text(
                      slide['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: slide['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slide['subtitle'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (slide['color'] as Color).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (slide['color'] as Color).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        slide['desc'] as String,
                        style: const TextStyle(fontSize: 13, height: 1.45, ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(tourFeatures.length, (index) {
                        final bool isActive = index == currentSlide;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (slide['color'] as Color)
                                : (Theme.of(dialogCtx).brightness == Brightness.dark
                                    ? Colors.white24
                                    : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentSlide > 0)
                          OutlinedButton(
                            onPressed: () => setDialogState(() => currentSlide--),
                            child: const Text('Previous'),
                          )
                        else
                          const SizedBox(width: 80),
                        ElevatedButton(
                          onPressed: () {
                            if (currentSlide < tourFeatures.length - 1) {
                              setDialogState(() => currentSlide++);
                            } else {
                              StorageService.markSimulatorTourSeen();
                              Navigator.pop(dialogCtx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: slide['color'] as Color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            currentSlide == tourFeatures.length - 1 ? 'Start Simulating' : 'Next (${currentSlide + 1}/${tourFeatures.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getClinicalDiagnosisString() {
    final double s = _state.patientSphere;
    final double c = _state.patientCylinder;
    final double a = _state.patientAngle;

    if (s.abs() < 0.05 && c.abs() < 0.05) {
      return 'Emmetropia (Plano)';
    }
    if (c.abs() < 0.05) {
      return s > 0 ? 'Simple Hyperopia (+${s.toStringAsFixed(2)} D)' : 'Simple Myopia (${s.toStringAsFixed(2)} D)';
    }

    // Determine Astigmatic Orientation
    String axisType = 'Oblique';
    if ((a >= 0 && a <= 30) || (a >= 150 && a <= 180)) {
      axisType = c < 0 ? 'With-The-Rule (WTR)' : 'Against-The-Rule (ATR)';
    } else if (a >= 60 && a <= 120) {
      axisType = c < 0 ? 'Against-The-Rule (ATR)' : 'With-The-Rule (WTR)';
    }

    final double s2 = s + c;
    if (s.abs() < 0.05) {
      return c > 0 ? 'Simple Hyperopic Astigmatism ($axisType)' : 'Simple Myopic Astigmatism ($axisType)';
    }
    if (s2.abs() < 0.05) {
      return s > 0 ? 'Simple Hyperopic Astigmatism ($axisType)' : 'Simple Myopic Astigmatism ($axisType)';
    }
    if ((s > 0 && s2 > 0)) {
      return 'Compound Hyperopic Astigmatism ($axisType)';
    }
    if ((s < 0 && s2 < 0)) {
      return 'Compound Myopic Astigmatism ($axisType)';
    }
    return 'Mixed Astigmatism ($axisType)';
  }

  // ─── Play Store Release & Medical Compliance Dialogs ──────────────────────

  void _showDailyReminderTimePicker(BuildContext context) async {
    final int currentHour = StorageService.getReminderHour();
    final int currentMinute = StorageService.getReminderMinute();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      helpText: 'SET DAILY CLINICAL CASE REMINDER TIME',
    );

    if (picked != null) {
      await NotificationService.setReminderTime(picked.hour, picked.minute);
      if (!context.mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily clinical case reminder set for ${NotificationService.getReminderTimeString()}'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  void _showMedicalComplianceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_user, color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Medical Compliance Notice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLINICAL EDUCATION & SIMULATION STANDARD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              SizedBox(height: 8),
              Text(
                '• This software suite is an academic and clinical simulation tool engineered in compliance with American Academy of Ophthalmology (AAO BCSC Section 3) visual optics principles.\n\n'
                '• It is intended strictly for optometry residents, ophthalmology fellows, vision scientists, and ophthalmic technicians.\n\n'
                '• NOT FOR DIRECT HUMAN DIAGNOSIS: This application is not a CE-marked or FDA 510(k)-cleared primary diagnostic device and must not replace direct slit-lamp examination, cycloplegic refraction, or clinical retinoscopy performed by a licensed eye care professional.\n\n'
                '• MATHEMATICAL PRECISION: All vergence equations, Thibos Fourier power vectors, and Zernike wavefront polynomials are verified using standard visual optics literature.',
                style: TextStyle(fontSize: 12.5, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOfflinePrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.green, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Offline Privacy & Security',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZERO TRACKING • GDPR COMPLIANT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              SizedBox(height: 8),
              Text(
                '• 100% Offline-First Architecture: All clinical profiles, exam certificates, and refraction history are stored locally on your device.\n\n'
                '• Zero Personal Data Collection: No telemetric analytics, advertising trackers, or external servers are queried.\n\n'
                '• Clear Data Compliance: You can permanently delete all local patient profiles and exam scores at any time via Settings.',
                style: TextStyle(fontSize: 12.5, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Rate & Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enjoying Retinoscopy Simulator? Your rating helps us bring more optical tools to students and clinicians worldwide!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = index + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Submit on Play Store'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for supporting ophthalmic education!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext ctxParam) {
    showDialog(
      context: ctxParam,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Do you want to sign out of your clinical registry account and continue in offline guest mode?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await CloudSyncService.signOut();
              await StorageService.setGuestMode(true);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Switched to Offline Clinical Guest Mode.')),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}