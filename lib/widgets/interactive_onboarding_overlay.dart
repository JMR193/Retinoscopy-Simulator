import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/retinoscopy_state.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import 'realistic_eye.dart';

/// Interactive Onboarding Tutorial Modal / Guided Overlay
/// Designed for beginner ophthalmology, optometry, and vision science students.
/// Covers:
/// 1. Streak beam movement (WITH vs. AGAINST motion)
/// 2. Identifying the Neutral Point (Flash phenomenon)
/// 3. Trial lens selection (Plus vs. Minus neutralization rules)
/// 4. Working distance compensation (Gross to Net Rx)
/// 5. Guided beginner case launcher
class InteractiveOnboardingOverlay extends StatefulWidget {
  final VoidCallback? onDismiss;

  const InteractiveOnboardingOverlay({super.key, this.onDismiss});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => const InteractiveOnboardingOverlay(),
    );
  }

  @override
  State<InteractiveOnboardingOverlay> createState() => _InteractiveOnboardingOverlayState();
}

class _InteractiveOnboardingOverlayState extends State<InteractiveOnboardingOverlay> with TickerProviderStateMixin {
  int _currentStage = 0;
  final int _totalStages = 5;

  // Stage 1 Interactive State (Streak & Reflex Sweeping)
  double _stage1BeamOffset = 0.0;
  bool _stage1IsHyperopia = true; // true = With, false = Against

  // Stage 2 Interactive State (Neutrality Flash)
  bool _stage2IsNeutral = false;
  late AnimationController _pulseController;

  // Stage 3 Interactive State (Trial Lens Dialer)
  double _stage3TrialLens = 0.0;
  final double _stage3TargetGross = 2.00; // Requires +2.00 D to neutralize

  // Stage 4 Interactive State (Working Distance Slider)
  final double _stage4Gross = 3.50;
  double _stage4WD = 1.50; // 67 cm (+1.50 D)

  // Stage 5 Selected Starter Case
  int _selectedStarterCase = 0; // 0 = Hyperopia, 1 = Myopia, 2 = Astigmatism


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStage() {
    AudioService.playTick();
    if (_currentStage < _totalStages - 1) {
      setState(() {
        _currentStage++;
      });
    } else {
      _finishTutorial();
    }
  }

  void _prevStage() {
    AudioService.playTick();
    if (_currentStage > 0) {
      setState(() {
        _currentStage--;
      });
    }
  }

  void _finishTutorial() {
    StorageService.markSimulatorTourSeen();
    
    // Configure starter case if requested
    final state = context.read<RetinoscopyState>();
    if (_selectedStarterCase == 0) {
      // Hyperopia +2.00 D
      state.patientSphere = 2.00;
      state.patientCylinder = 0.0;
      state.patientAngle = 90.0;
      state.plusLensesSelected = true;
      state.plusSphere = 0.0;
    } else if (_selectedStarterCase == 1) {
      // Myopia -2.00 D
      state.patientSphere = -2.00;
      state.patientCylinder = 0.0;
      state.patientAngle = 90.0;
      state.plusLensesSelected = false;
      state.minusSphere = 0.0;
    } else {
      // Astigmatism +1.00 -2.00 x 90
      state.patientSphere = 1.00;
      state.patientCylinder = -2.00;
      state.patientAngle = 90.0;
      state.plusLensesSelected = true;
      state.plusSphere = 0.0;
    }

    // Enable guidance banner
    state.setProtocol(ClinicalProtocolMode.aaoPlusCyl);

    Navigator.of(context).pop();
    widget.onDismiss?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Guided beginner case loaded! Follow the top banner steps to neutralize.'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top Header & Stage Progress ─────────────────────────────────
            _buildHeader(isDark),

            // ── Main Interactive Stage Content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildStageContent(isDark),
              ),
            ),

            // ── Bottom Navigation & Action Bar ──────────────────────────────
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interactive Retinoscopy Onboarding',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                      ),
                      Text(
                        'Stage ${_currentStage + 1} of $_totalStages: ${_getStageTitle()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.cyanAccent : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Skip Tutorial',
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  StorageService.markSimulatorTourSeen();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step Progress Bar
          Row(
            children: List.generate(_totalStages, (index) {
              final isCompleted = index < _currentStage;
              final isCurrent = index == _currentStage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < _totalStages - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.blue
                        : (isCurrent ? Colors.blue.shade300 : (isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStageTitle() {
    switch (_currentStage) {
      case 0:
        return 'Streak Beam & Reflex Movement';
      case 1:
        return 'Identifying the Neutral Point';
      case 2:
        return 'Trial Lens Selection Rules';
      case 3:
        return 'Working Distance Deduction';
      case 4:
        return 'Launch Starter Practice';
      default:
        return '';
    }
  }

  Widget _buildStageContent(bool isDark) {
    switch (_currentStage) {
      case 0:
        return _buildStage1StreakMovement(isDark);
      case 1:
        return _buildStage2NeutralPoint(isDark);
      case 2:
        return _buildStage3TrialLensSelection(isDark);
      case 3:
        return _buildStage4WorkingDistance(isDark);
      case 4:
        return _buildStage5StarterPractice(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STAGE 1: Streak Beam & Movement (WITH vs. AGAINST) ────────────────────
  Widget _buildStage1StreakMovement(bool isDark) {
    // In Hyperopia (With motion): reflex moves with beam
    // In Myopia (Against motion): reflex moves opposite to beam
    final double reflexOffset = _stage1IsHyperopia ? _stage1BeamOffset : -_stage1BeamOffset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          icon: Icons.lightbulb,
          color: Colors.amber,
          title: 'How Retinoscopy Works',
          text:
              'A retinoscope projects a streak of light into the patient\'s eye. The light reflects off the vascular choroid & retina, creating an illuminated red reflex inside the pupil.\n\n'
              'When you sweep the streak across the eye, the reflex moves either in the SAME direction (WITH motion) or in the OPPOSITE direction (AGAINST motion).',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Interactive Selector: With vs Against
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Hyperopia (WITH Motion)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: _stage1IsHyperopia,
                selectedColor: Colors.green.withValues(alpha: 0.2),
                avatar: Icon(Icons.arrow_forward, size: 16, color: _stage1IsHyperopia ? Colors.green : Colors.grey),
                onSelected: (_) => setState(() => _stage1IsHyperopia = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Myopia (AGAINST Motion)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: !_stage1IsHyperopia,
                selectedColor: Colors.red.withValues(alpha: 0.2),
                avatar: Icon(Icons.arrow_back, size: 16, color: !_stage1IsHyperopia ? Colors.red : Colors.grey),
                onSelected: (_) => setState(() => _stage1IsHyperopia = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mini Interactive Eye Sweep Canvas
        Center(
          child: Column(
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Simulated Eye Pupil
                    Positioned.fill(
                      child: RealisticEye(
                        beamPosition: reflexOffset,
                        streakAngle: 90,
                        reflexWidth: 35,
                        reflexAngle: 90,
                        retinaOpacity: 0.9,
                        reflectionOpacity: 0.8,
                        reflexMotion: _stage1IsHyperopia ? 'with' : 'against',
                        pupilDilated: false,
                        scissorsMotionActive: false,
                      ),
                    ),
                    // External Streak Beam Indicator
                    Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(_stage1BeamOffset * 1.5, 0),
                          child: Container(
                            width: 8,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
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
              const SizedBox(height: 12),
              Text(
                'Drag the streak slider below to test sweeping:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
              ),
              Slider(
                value: _stage1BeamOffset,
                min: -35.0,
                max: 35.0,
                activeColor: Colors.amber.shade700,
                onChanged: (val) {
                  setState(() {
                    _stage1BeamOffset = val;
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_stage1IsHyperopia ? Colors.green : Colors.red).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (_stage1IsHyperopia ? Colors.green : Colors.red).withValues(alpha: 0.4)),
                ),
                child: Text(
                  _stage1IsHyperopia
                      ? 'WITH MOTION: Reflex moves RIGHT when you sweep RIGHT'
                      : 'AGAINST MOTION: Reflex moves LEFT when you sweep RIGHT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _stage1IsHyperopia ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STAGE 2: Identifying the Neutral Point ────────────────────────────────
  Widget _buildStage2NeutralPoint(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          icon: Icons.flash_on,
          color: Colors.amber,
          title: 'The Neutral Point (Flash Phenomenon)',
          text:
              'Neutrality is reached when the patient\'s Far Point is exactly conjugate with the retinoscope peephole.\n\n'
              'At neutrality:\n'
              '1. The reflex has INFINITE apparent speed.\n'
              '2. The pupil fills 100% with instantaneous golden light (Flash).\n'
              '3. There is ZERO perceptible directional movement.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Interactive Before vs At Neutrality Switcher
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Directional Sweep (Not Neutral)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: !_stage2IsNeutral,
                selectedColor: Colors.blue.withValues(alpha: 0.2),
                onSelected: (_) => setState(() => _stage2IsNeutral = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Neutral Point (FLASH)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: _stage2IsNeutral,
                selectedColor: Colors.amber.withValues(alpha: 0.3),
                avatar: const Icon(Icons.flash_on, size: 16, color: Colors.amber),
                onSelected: (_) => setState(() => _stage2IsNeutral = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _stage2IsNeutral ? Colors.amber : Colors.blue.withValues(alpha: 0.3),
                        width: _stage2IsNeutral ? 2 : 1,
                      ),
                      boxShadow: _stage2IsNeutral
                          ? [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: RealisticEye(
                      beamPosition: _stage2IsNeutral ? 0 : 25,
                      streakAngle: 90,
                      reflexWidth: _stage2IsNeutral ? 120 : 30,
                      reflexAngle: 90,
                      retinaOpacity: 0.95,
                      reflectionOpacity: _stage2IsNeutral ? 0.95 : 0.7,
                      reflexMotion: _stage2IsNeutral ? 'neutral' : 'with',
                      pupilDilated: false,
                      scissorsMotionActive: false,
                      pupilFillRatio: _stage2IsNeutral ? 1.0 : 0.35,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _stage2IsNeutral
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _stage2IsNeutral ? Colors.amber : Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _stage2IsNeutral
                      ? '✨ NEUTRAL FLASH: Entire pupil illuminates with maximum brightness!'
                      : 'Directional band moving across pupil — keep dialing lenses to neutralize.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _stage2IsNeutral ? Colors.amber.shade900 : Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STAGE 3: Trial Lens Selection Rules ───────────────────────────────────
  Widget _buildStage3TrialLensSelection(bool isDark) {
    final bool isNeutral = (_stage3TrialLens - _stage3TargetGross).abs() < 0.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          icon: Icons.visibility,
          color: Colors.green,
          title: 'The 2 Golden Rules of Retinoscopy',
          text:
              '1. IF you see WITH motion ➔ Add PLUS (+) Trial Lenses\n'
              '2. IF you see AGAINST motion ➔ Add MINUS (-) Trial Lenses\n\n'
              'As you approach neutrality, the reflex becomes WIDER, FASTER, and BRIGHTER until it flashes.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Interactive Practice: Patient has +2.00 D Hyperopia (WITH Motion)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add Plus lenses until the reflex reaches full neutrality:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLensButton('+0.00 D (Plano)', 0.00),
                  const SizedBox(width: 6),
                  _buildLensButton('+1.00 D', 1.00),
                  const SizedBox(width: 6),
                  _buildLensButton('+2.00 D (Target)', 2.00),
                  const SizedBox(width: 6),
                  _buildLensButton('+3.00 D (Over)', 3.00),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isNeutral ? Colors.amber : Colors.green.withValues(alpha: 0.4)),
                ),
                child: RealisticEye(
                  beamPosition: isNeutral ? 0 : 20,
                  streakAngle: 90,
                  reflexWidth: isNeutral ? 120 : (30 + (_stage3TrialLens * 15)),
                  reflexAngle: 90,
                  retinaOpacity: 0.9,
                  reflectionOpacity: 0.8,
                  reflexMotion: isNeutral ? 'neutral' : (_stage3TrialLens > _stage3TargetGross ? 'against' : 'with'),
                  pupilDilated: false,
                  scissorsMotionActive: false,
                  pupilFillRatio: isNeutral ? 1.0 : 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Current Trial Lens: ${_stage3TrialLens > 0 ? '+' : ''}${_stage3TrialLens.toStringAsFixed(2)} D',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                isNeutral
                    ? '🎉 TARGET NEUTRALITY ACHIEVED! (+2.00 D neutralized the eye)'
                    : (_stage3TrialLens > _stage3TargetGross
                        ? '❌ Overcorrected! You now see AGAINST motion (remove plus).'
                        : '⚠️ Still showing WITH motion. Add more PLUS power.'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isNeutral ? Colors.green : (_stage3TrialLens > _stage3TargetGross ? Colors.red : Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLensButton(String label, double power) {
    final isSelected = (_stage3TrialLens - power).abs() < 0.05;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(60, 34),
        elevation: isSelected ? 2 : 0,
      ),
      onPressed: () {
        AudioService.playTick();
        setState(() {
          _stage3TrialLens = power;
        });
      },
      child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }

  // ─── STAGE 4: Working Distance Compensation ────────────────────────────────
  Widget _buildStage4WorkingDistance(bool isDark) {
    final double netRx = _stage4Gross - _stage4WD;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          icon: Icons.straighten,
          color: Colors.deepOrange,
          title: 'Working Distance Compensation',
          text:
              'Because you are sitting at a finite distance (not infinity), the gross lens in the phoropter makes the eye conjugate to your retinoscope.\n\n'
              'To find the patient\'s true Distance Prescription (Net Rx), subtract the Working Distance Diopters:\n\n'
              '• 67 cm Working Distance = Deduct 1.50 D\n'
              '• 50 cm Working Distance = Deduct 2.00 D\n'
              '• 100 cm (1 meter) = Deduct 1.00 D',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interactive Calculation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gross Neutralizing Lens: +${_stage4Gross.toStringAsFixed(2)} D', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text('WD: -${_stage4WD.toStringAsFixed(2)} D', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('50 cm (-2.00 D)', style: TextStyle(fontSize: 11)),
                    selected: (_stage4WD - 2.00).abs() < 0.05,
                    onSelected: (_) => setState(() => _stage4WD = 2.00),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('67 cm (-1.50 D)', style: TextStyle(fontSize: 11)),
                    selected: (_stage4WD - 1.50).abs() < 0.05,
                    onSelected: (_) => setState(() => _stage4WD = 1.50),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('1 m (-1.00 D)', style: TextStyle(fontSize: 11)),
                    selected: (_stage4WD - 1.00).abs() < 0.05,
                    onSelected: (_) => setState(() => _stage4WD = 1.00),
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text('NET PATIENT REFRACTION (TRUE RX):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${netRx > 0 ? '+' : ''}${netRx.toStringAsFixed(2)} DS',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    Text(
                      '(Gross +${_stage4Gross.toStringAsFixed(2)} D) − (WD +${_stage4WD.toStringAsFixed(2)} D) = ${netRx > 0 ? '+' : ''}${netRx.toStringAsFixed(2)} DS',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STAGE 5: Starter Case Practice Launch ─────────────────────────────────
  Widget _buildStage5StarterPractice(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          icon: Icons.rocket_launch,
          color: Colors.indigo,
          title: 'You are Ready to Practice!',
          text:
              'Pick a guided starter case below to enter the simulation sandbox with live step-by-step assistance.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        _buildStarterCaseCard(
          index: 0,
          title: 'Starter Case 1: Simple Hyperopia (+2.00 DS)',
          subtitle: 'Practice recognizing WITH motion and neutralizing with Plus trial lenses.',
          icon: Icons.add_circle,
          color: Colors.green,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStarterCaseCard(
          index: 1,
          title: 'Starter Case 2: Simple Myopia (-2.00 DS)',
          subtitle: 'Practice recognizing AGAINST motion and neutralizing with Minus trial lenses.',
          icon: Icons.remove_circle,
          color: Colors.red,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStarterCaseCard(
          index: 2,
          title: 'Starter Case 3: Astigmatism (+1.00 -2.00 × 90°)',
          subtitle: 'Practice 2-meridian alignment, 90° axis flip, and cylinder neutralization.',
          icon: Icons.swap_horiz,
          color: Colors.purple,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStarterCaseCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedStarterCase == index;
    return InkWell(
      onTap: () {
        AudioService.playTick();
        setState(() {
          _selectedStarterCase = index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? color : null)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final isLastStage = _currentStage == _totalStages - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Replay info tip
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 15,
                      color: isDark ? Colors.cyanAccent.shade100 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Replay anytime via Help (?) in the top bar',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Back & Next/Finish Buttons
              Row(
                children: [
                  if (_currentStage > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _nextStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStage ? Colors.indigo : Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isLastStage ? Icons.play_arrow : Icons.arrow_forward, size: 16),
                    label: Text(
                      isLastStage ? 'Launch Practice' : 'Next Stage',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
