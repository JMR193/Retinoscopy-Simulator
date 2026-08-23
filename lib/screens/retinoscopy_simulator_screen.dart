import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/retinoscopy_state.dart';
import '../services/ai_engine.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/realistic_eye.dart';
import '../widgets/trial_lens_overlay.dart';
import '../widgets/subjective_view.dart';
import '../widgets/optical_ray_diagram.dart';
import '../widgets/thibos_vector_plot.dart';
import 'about_screen.dart';
import 'patient_profiles_screen.dart';
import 'exam_screen.dart';
import 'ar_mode_screen.dart';
import 'optical_calculator_screen.dart';
import 'ai_tutor_screen.dart';
import 'history_screen.dart';
import 'handbook_screen.dart';

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

  bool? _testResult;
  bool _showTestFeedback = false;

  final RetinoscopyAIEngine _aiEngine = RetinoscopyAIEngine();
  AIHint? _currentHint;

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
        _showFeatureTourDialog(context);
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
    if (mounted) {
      _updateAIHint(shouldSetState: true);
    }
  }

  @override
  void dispose() {
    _autoSweepController.dispose();
    _state.removeListener(_onStateChange);
    _userSphere1Controller.dispose();
    _userCylinder1Controller.dispose();
    _userAxis1Controller.dispose();
    _userSphere2Controller.dispose();
    _userCylinder2Controller.dispose();
    _userAxis2Controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    double s1 = double.tryParse(_userSphere1Controller.text) ?? 0.0;
    double c1 = double.tryParse(_userCylinder1Controller.text) ?? 0.0;
    double a1 = double.tryParse(_userAxis1Controller.text) ?? 0.0;
    double s2 = double.tryParse(_userSphere2Controller.text) ?? 0.0;
    double c2 = double.tryParse(_userCylinder2Controller.text) ?? 0.0;
    double a2 = double.tryParse(_userAxis2Controller.text) ?? 0.0;

    bool correct = _state.checkAnswer(
      userSphere1: s1,
      userCylinder1: c1,
      userAxis1: a1,
      userSphere2: s2,
      userCylinder2: c2,
      userAxis2: a2,
    );

    if (correct) {
      AudioService.playSuccess();
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
    _userSphere1Controller.clear();
    _userCylinder1Controller.clear();
    _userAxis1Controller.clear();
    _userSphere2Controller.clear();
    _userCylinder2Controller.clear();
    _userAxis2Controller.clear();
    setState(() {
      _showTestFeedback = false;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isWide = screenSize.width > 900 || isLandscape;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Retinoscopy Simulator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3),
            ),
            Text(
              _state.isExploreMode ? 'Explore & Neutralize' : 'Clinical Test Mode',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Feature Tour & Guide',
            onPressed: () => _showFeatureTourDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Clinical Case Generator',
            onPressed: () => _showRandomCaseDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Clinical Tools & Menu',
            onSelected: (value) {
              switch (value) {
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
                    Icon(_state.showTutorial ? Icons.school : Icons.school_outlined, color: Colors.indigo, size: 18),
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
                            FilterChip(
                              label: const Text('Subjective Refraction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              selected: _state.subjectiveModeActive,
                              selectedColor: Colors.purple[100],
                              checkmarkColor: Colors.purple,
                              onSelected: (val) {
                                _state.subjectiveModeActive = val;
                              },
                            ),
                          ],
                        ),
                        if (_state.showTutorial) ...[
                          const SizedBox(height: 6),
                          _buildTutorialBanner(),
                        ],
                        const SizedBox(height: 6),
                        // 3-Column Single-Screen Dashboard in Landscape
                        Expanded(
                          child: _state.subjectiveModeActive
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 3, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildLeftPanel())),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 4, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildSubjectiveCenterPanel())),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 3, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildSubjectiveRightPanel())),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 3, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildLeftPanel())),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 4, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildCenterPanel())),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 3, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildRightPanel())),
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
                            FilterChip(
                              label: const Text('Subjective Refraction', style: TextStyle(fontWeight: FontWeight.bold)),
                              selected: _state.subjectiveModeActive,
                              selectedColor: Colors.purple[100],
                              checkmarkColor: Colors.purple,
                              onSelected: (val) {
                                _state.subjectiveModeActive = val;
                              },
                            ),
                          ],
                        ),
                        if (_state.showTutorial) ...[
                          const SizedBox(height: 16),
                          _buildTutorialBanner(),
                        ],
                        const SizedBox(height: 16),
                        if (_state.subjectiveModeActive)
                          Column(
                            children: [
                              _buildSubjectiveCenterPanel(),
                              const SizedBox(height: 16),
                              _buildLeftPanel(),
                              const SizedBox(height: 16),
                              _buildSubjectiveRightPanel(),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildCenterPanel(),
                              const SizedBox(height: 16),
                              _buildLeftPanel(),
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
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : Colors.black87,
        ),
      ),
      selected: active,
      selectedColor: _getThemeColor(),
      backgroundColor: Colors.grey[200],
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
            const Text(
              'Patient Refraction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_state.isExploreMode) ...[
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
              _buildValueAdjustmentRow(
                label: 'Working Distance',
                value: _state.workingDistance,
                onChanged: (val) => _state.workingDistance = val,
                min: 0.0,
                max: 2.0,
                step: 0.5,
                isDiopter: true,
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
                      'Refractive Error Forms (Transpositions)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDarkMode ? Colors.cyanAccent : Colors.indigo),
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
              Text(
                'Write Patient Net Prescription:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildTestRxFields(),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('AAO Clinical Presets (0–13)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAAOPresetsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRxFields() {
    final bool isDarkMode = _state.isDarkMode;
    Widget buildField(String label, TextEditingController controller, double min, double max) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: label,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form 1 (Primary):',
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
          'Form 2 (Transposed):',
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
                    Text(
                      _testResult == true ? 'Correct! Neutralization Verified.' : 'Incorrect Prescription. Check Transposition.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _testResult == true ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                if (_testResult == false) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Target Answers:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDarkMode ? Colors.white : Colors.red[900]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Form 1: ${_formatRx(_state.correctSphere1, _state.correctCylinder1, _state.correctAxis1)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  Text(
                    'Form 2: ${_formatRx(_state.correctSphere2, _state.correctCylinder2, _state.correctAxis2)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ],
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (isDiopter && (max - min) >= 4.0) ...[
                IconButton(
                  icon: const Icon(Icons.fast_rewind, size: 18),
                  tooltip: '-1.00 D',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AudioService.playTick();
                    double newValue = (value - 1.00).clamp(min, max);
                    onChanged(newValue);
                  },
                ),
              ],
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  AudioService.playTick();
                  double newValue = value - step;
                  if (newValue < min) {
                    if (isAngle) { newValue = max; }
                    else { newValue = min; }
                  }
                  onChanged(newValue);
                },
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formattedValue,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                visualDensity: VisualDensity.compact,
                onPressed: () {
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
                IconButton(
                  icon: const Icon(Icons.fast_forward, size: 18),
                  tooltip: '+1.00 D',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
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

  // --- Center Panel: Interactive Eye Simulator ---
  Widget _buildCenterPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Eye Simulator View',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                final double size = math.min(constraints.maxWidth, isLandscape ? 220.0 : 300.0);
                return Center(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Realistic procedural Eye Simulator
                        Positioned.fill(
                          child: RealisticEye(
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
                            velocityFactor: _state.reflexVelocityFactor,
                            illuminance: _state.reflexIlluminance,
                            pupilApertureRatio: _state.customPupilAperture,
                            fundusLuminanceMultiplier: _state.customFundusLuminance,
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
                            child: Stack(
                              children: [
                                // Light Beam
                                Center(
                                  child: Transform.translate(
                                    offset: Offset(
                                      _state.beamPosition * math.cos((_state.streakAngle - 90) * math.pi / 180),
                                      _state.beamPosition * math.sin((_state.streakAngle - 90) * math.pi / 180),
                                    ),
                                    child: Transform.rotate(
                                      angle: (_state.streakAngle - 90) * math.pi / 180,
                                      child: Container(
                                        width: 16,
                                        height: size * 2.2,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                                              blurRadius: 14,
                                              spreadRadius: 3,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFFF9C4).withValues(alpha: 0.85),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0x00FFF176),
                                              Color(0x66FFE082),
                                              Color(0xDDFFF59D),
                                              Color(0xFFFFFFFF), // White-hot filament center
                                              Color(0xDDFFF59D),
                                              Color(0x66FFE082),
                                              Color(0x00FFF176),
                                            ],
                                            stops: [0.0, 0.20, 0.38, 0.50, 0.62, 0.80, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Quick Streak Orientation & Working Distance Toolbar
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                // 🌟 Auto-Sweep Controller Chip
                ActionChip(
                  avatar: Icon(
                    _isAutoSweep ? Icons.pause_circle : Icons.play_circle,
                    size: 16,
                    color: _isAutoSweep ? Colors.amberAccent : Colors.blue,
                  ),
                  label: Text(
                    _isAutoSweep ? 'Auto-Sweep' : 'Auto-Sweep',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isAutoSweep ? Colors.amberAccent : null,
                    ),
                  ),
                  backgroundColor: _isAutoSweep ? Colors.amber.withValues(alpha: 0.2) : null,
                  onPressed: _toggleAutoSweep,
                ),
                if (_isAutoSweep)
                  ActionChip(
                    label: Text('${_autoSweepSpeed}x', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (_autoSweepSpeed == 1.0) {
                        _setAutoSweepSpeed(1.5);
                      } else if (_autoSweepSpeed == 1.5) {
                        _setAutoSweepSpeed(2.0);
                      } else {
                        _setAutoSweepSpeed(1.0);
                      }
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.swap_vert, size: 16),
                  label: const Text('90° (V)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _state.streakAngle = 90.0,
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('180° (H)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _state.streakAngle = 180.0,
                ),
                ActionChip(
                  avatar: const Icon(Icons.flip, size: 15),
                  label: const Text('Flip 90°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _state.flipStreakAxis90(),
                ),
                PopupMenuButton<double>(
                  tooltip: 'Oblique & Straddle Angles',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 14, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        Text('More Angles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onSelected: (angle) {
                    if (angle == -45) {
                      _state.straddleAxis(-1);
                    } else if (angle == 450) {
                      _state.straddleAxis(1);
                    } else {
                      _state.streakAngle = angle;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 45.0, child: Text('45° Oblique Meridian')),
                    const PopupMenuItem(value: 135.0, child: Text('135° Oblique Meridian')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: -45.0, child: Text('-45° Copeland Straddle')),
                    const PopupMenuItem(value: 450.0, child: Text('+45° Copeland Straddle')),
                  ],
                ),
                FilterChip(
                  avatar: Icon(_state.sleeveUp ? Icons.arrow_upward : Icons.arrow_downward, size: 15),
                  label: Text(_state.sleeveUp ? 'Concave Mirror' : 'Plane Mirror', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _state.sleeveUp,
                  onSelected: (val) => _state.sleeveUp = val,
                ),
                FilterChip(
                  avatar: const Icon(Icons.auto_graph, size: 15, color: Colors.cyanAccent),
                  label: const Text('Ray Diagram', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _state.isRayDiagramVisible,
                  onSelected: (_) => _state.toggleRayDiagram(),
                ),
                FilterChip(
                  avatar: const Icon(Icons.scatter_plot, size: 15, color: Colors.purpleAccent),
                  label: const Text('Thibos Plot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _state.isVectorPlotVisible,
                  onSelected: (_) => _state.toggleVectorPlot(),
                ),
                FilterChip(
                  avatar: const Icon(Icons.child_care, size: 15, color: Colors.amberAccent),
                  label: const Text('Mohindra Pediatric', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _state.isMohindraMode,
                  onSelected: (_) => _state.toggleMohindraMode(),
                ),
                ActionChip(
                  avatar: const Icon(Icons.list_alt, size: 15),
                  label: const Text('AAO Presets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAAOPresetsDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Working Distance Quick Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Working Dist: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ChoiceChip(
                  label: const Text('50 cm (+2.00 D)', style: TextStyle(fontSize: 11)),
                  selected: (_state.workingDistance - 2.00).abs() < 0.05,
                  onSelected: (_) => _state.setWorkingDistancePreset(50),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('67 cm (+1.50 D)', style: TextStyle(fontSize: 11)),
                  selected: (_state.workingDistance - 1.50).abs() < 0.05,
                  onSelected: (_) => _state.setWorkingDistancePreset(67),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('1 m (+1.00 D)', style: TextStyle(fontSize: 11)),
                  selected: (_state.workingDistance - 1.00).abs() < 0.05,
                  onSelected: (_) => _state.setWorkingDistancePreset(100),
                ),
              ],
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
                child: Row(
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
              ),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge(
                  'Reflex Motion',
                  _state.reflexMotion == 'neutral'
                      ? 'NEUTRAL FLASH'
                      : (_state.reflexMotion == 'with' ? 'WITH (+ LENS)' : 'AGAINST (- LENS)'),
                  _state.reflexMotion == 'neutral'
                      ? Colors.amber.shade800
                      : (_state.reflexMotion == 'with' ? Colors.green : Colors.red),
                ),
                _buildInfoBadge('Reflex Width', '${_state.reflexWidth.abs().toStringAsFixed(1)} px', Colors.orange),
                _buildInfoBadge('Reflex Meridian', '${_state.reflexAngle.toStringAsFixed(0)}°', Colors.blue),
              ],
            ),
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
            style: TextStyle(fontSize: 12, height: 1.45, color: Colors.black87),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trial Lenses (Phoropter)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Plus vs Minus Lenses Tab
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _state.plusLensesSelected = true,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _state.plusLensesSelected ? Colors.green : Colors.grey[200],
                      foregroundColor: _state.plusLensesSelected ? Colors.white : Colors.black87,
                      elevation: _state.plusLensesSelected ? 2 : 0,
                    ),
                    child: const Text('Plus Lenses'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _state.plusLensesSelected = false,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_state.plusLensesSelected ? Colors.red : Colors.grey[200],
                      foregroundColor: !_state.plusLensesSelected ? Colors.white : Colors.black87,
                      elevation: !_state.plusLensesSelected ? 2 : 0,
                    ),
                    child: const Text('Minus Lenses'),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_state.plusLensesSelected) ...[
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.plusSphere,
                onChanged: (val) => _state.plusSphere = val,
                min: -20.0,
                max: 20.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.plusCylinder,
                onChanged: (val) => _state.plusCylinder = val,
                min: -6.0,
                max: 6.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Axis',
                value: _state.plusAxis,
                onChanged: (val) => _state.plusAxis = val,
                min: 5.0,
                max: 180.0,
                step: 5.0,
                isAngle: true,
              ),
            ] else ...[
              _buildValueAdjustmentRow(
                label: 'Sphere Power',
                value: _state.minusSphere,
                onChanged: (val) => _state.minusSphere = val,
                min: -20.0,
                max: 20.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Power',
                value: _state.minusCylinder,
                onChanged: (val) => _state.minusCylinder = val,
                min: -6.0,
                max: 6.0,
                step: 0.25,
                isDiopter: true,
              ),
              _buildValueAdjustmentRow(
                label: 'Cylinder Axis',
                value: _state.minusAxis,
                onChanged: (val) => _state.minusAxis = val,
                min: 5.0,
                max: 180.0,
                step: 5.0,
                isAngle: true,
              ),
            ],
            const Divider(height: 20),
            // Live Gross & Net Power Summary Card
            Builder(
              builder: (context) {
                final double ts = _state.plusLensesSelected ? _state.plusSphere : _state.minusSphere;
                final double tc = _state.plusLensesSelected ? _state.plusCylinder : _state.minusCylinder;
                final double ta = _state.plusLensesSelected ? _state.plusAxis : _state.minusAxis;
                final double netS = ts - _state.workingDistance;

                return Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.teal, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Active Lens Powers (In Phoropter)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gross Retinoscopy: ${_formatRx(ts, tc, ta)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Net Refraction (${_state.workingDistance.toStringAsFixed(2)} D WD): ${_formatRx(netS, tc, ta)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900),
                      ),
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
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text(
                'Pathology Simulation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Simulate cataracts & corneal media opacities',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nuclear Cataract Density', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('${(_state.cataractDensity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _state.cataractDensity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: Colors.amber[800],
                        onChanged: (val) => _state.cataractDensity = val,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Corneal Opacity / Scar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('${(_state.cornealOpacity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _state.cornealOpacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: Colors.blueGrey,
                        onChanged: (val) => _state.cornealOpacity = val,
                      ),
                    ],
                  ),
                ),
              ],
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
                      Text(steps[idx]['desc']!, style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.black87)),
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
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.looks_one, color: Colors.green),
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
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF8E1),
                    child: Icon(Icons.looks_two, color: Colors.amber),
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
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.looks_3, color: Colors.red),
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
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(Icons.remove_red_eye, color: Colors.purple),
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
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
                      itemBuilder: (_, idx) {
                        final bool isSelected = _state.selectedPreset == idx;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                            foregroundColor: isSelected ? Colors.white : Colors.black87,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Step ${_state.currentInstructionStep + 1} of 10',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
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
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
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
    Color primaryColor = _getThemeColor();
    return Drawer(
      child: Column(
        children: [
          // Medical Suite Branding Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: EyePainter(
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
            accountName: const Text(
              'Retinoscopy Medical Suite',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('Ophthalmic Optics & Refraction Engine'),
          ),

          // Clinical Suite Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'CLINICAL SUITE & TOOLS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline, color: Colors.blue),
                  title: const Text('Patient Profiles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Custom clinical refractive records', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PatientProfilesScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.quiz_outlined, color: Colors.orange),
                  title: const Text('Exam Assessment Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Timed 10-case Board competency exam', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExamScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined, color: Colors.teal),
                  title: const Text('Optical Cross & Calculator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('2-meridian cross & power transposition', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OpticalCalculatorScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.psychology_outlined, color: Colors.deepPurple),
                  title: const Text('AI Clinical Optics Tutor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Offline ophthalmic physics assistant', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiTutorScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: Colors.indigo),
                  title: const Text('Clinical Handbook', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Retinoscopy physics & procedural guides', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HandbookScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.amber),
                  title: const Text('Exam History & Certificate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Track scores & generate certificates', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined, color: Colors.cyan),
                  title: const Text('AR Retinoscopy Trainer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Live camera reticle streak trainer', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ARModeScreen()),
                    );
                  },
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'REALISTIC OPTICAL PHYSICS & CALIBRATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Base Pupil Aperture Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${(_state.customPupilAperture * 10).toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      Slider(
                        value: _state.customPupilAperture,
                        min: 0.25,
                        max: 0.85,
                        divisions: 12,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          _state.customPupilAperture = val;
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fundus Luminance & Glow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${(_state.customFundusLuminance * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      Slider(
                        value: _state.customFundusLuminance,
                        min: 0.50,
                        max: 2.00,
                        divisions: 15,
                        activeColor: Colors.orange,
                        onChanged: (val) {
                          _state.customFundusLuminance = val;
                        },
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: const Text('Reset Optical Physics to Default', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        onPressed: () {
                          _state.resetOpticalPhysicsToDefault();
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'OPTICAL PATHOLOGY & ABERRATIONS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mydriasis (Dilated Pupil)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enlarges pupillary aperture for wide sweeps', style: TextStyle(fontSize: 11)),
                  value: _state.pupilDilated,
                  activeTrackColor: primaryColor, activeThumbColor: primaryColor,
                  onChanged: (val) => _state.pupilDilated = val,
                ),
                SwitchListTile(
                  title: const Text('Scissors Aberration Motion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Simulates keratoconus dual-blade motion', style: TextStyle(fontSize: 11)),
                  value: _state.scissorsMotionActive,
                  activeTrackColor: primaryColor, activeThumbColor: primaryColor,
                  onChanged: (val) => _state.scissorsMotionActive = val,
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'PREFERENCES & AUDIO FEEDBACK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Haptic Touch Sweeps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tactile vibration during streak sweeps', style: TextStyle(fontSize: 11)),
                  value: _state.hapticsEnabled,
                  activeTrackColor: primaryColor, activeThumbColor: primaryColor,
                  onChanged: (val) => _state.hapticsEnabled = val,
                ),
                SwitchListTile(
                  title: const Text('Clinical Sound Cues', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Auditory feedback for dials, neutrality & exams', style: TextStyle(fontSize: 11)),
                  value: _state.soundEnabled,
                  activeTrackColor: primaryColor, activeThumbColor: primaryColor,
                  onChanged: (val) {
                    _state.soundEnabled = val;
                    AudioService.soundEnabled = val;
                    if (val) {
                      AudioService.playTick();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('High-contrast dark clinical theme', style: TextStyle(fontSize: 11)),
                  value: _state.isDarkMode,
                  activeTrackColor: primaryColor, activeThumbColor: primaryColor,
                  onChanged: (val) => _state.isDarkMode = val,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: ['Blue', 'Green', 'Cyan', 'Orange', 'Purple'].map((colorName) {
                      Color color = Colors.blue;
                      if (colorName == 'Green') color = Colors.green;
                      if (colorName == 'Cyan') color = Colors.cyan;
                      if (colorName == 'Orange') color = Colors.orange;
                      if (colorName == 'Purple') color = Colors.deepPurple;

                      bool selected = _state.selectedThemeColor == colorName;

                      return ChoiceChip(
                        label: Text(colorName),
                        selected: selected,
                        selectedColor: color,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (val) {
                          if (val) {
                            _state.selectedThemeColor = colorName;
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
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
        return Colors.blue;
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: ['Duochrome', 'JCC Axis', 'JCC Power'].map((method) {
                bool selected = _state.activeSubjectiveTest == method;
                return ChoiceChip(
                  label: Text(method),
                  selected: selected,
                  selectedColor: Colors.purple[100],
                  checkmarkColor: Colors.purple,
                  labelStyle: TextStyle(
                    color: selected ? Colors.purple[900] : Colors.black87,
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
              style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
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
                        style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
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
                            color: isActive ? (slide['color'] as Color) : Colors.grey[300],
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
}
