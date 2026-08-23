import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/retinoscopy_state.dart';

/// AI Clinical Optics Tutor Screen — JMR Technologies
/// Interactive offline clinical assistant for ophthalmic optics & retinoscopy masterclass.
class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '👋 Hello! I am your AI Clinical Optics & Retinoscopy Tutor.\n\n'
          'I can help you master streak retinoscopy physics, meridional lens neutralization, astigmatic phenomena (Break, Skew, Copeland Straddle), Mohindra pediatric protocols, Thibos Fourier power vectors, and optical cross math.\n\n'
          '💡 Tap any suggested topic below or type your question!',
      'time': 'Just now',
    }
  ];

  final List<String> _suggestedTopics = [
    'Analyze My Active Simulation',
    'How do I neutralize With vs Against motion?',
    'Explain Copeland Straddling Technique',
    'What causes the Break Phenomenon?',
    'Mohindra Pediatric Retinoscopy Protocol',
    'Optics of Plane vs Concave Mirror',
    'Scissors Motion & Keratoconus',
    'How to calculate Optical Cross & Transposition?',
    'Jackson Cross-Cylinder (JCC) Principles',
    'Duochrome Red-Green Balance Physics',
    'Quiz Me on Clinical Optics',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(String query) {
    if (query.trim().isEmpty) return;

    final String userText = query.trim();
    _queryController.clear();

    setState(() {
      _messages.add({
        'isUser': true,
        'text': userText,
        'time': 'Now',
      });
    });

    final retinoscopyState = Provider.of<RetinoscopyState>(context, listen: false);
    final String response = _generateClinicalResponse(userText, retinoscopyState);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': response,
            'time': 'Now',
          });
        });
        _scrollToBottom();
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateClinicalResponse(String query, RetinoscopyState state) {
    final lower = query.toLowerCase();

    // 1. Live Simulation Diagnostic Analysis
    if (lower.contains('analyze') || lower.contains('active') || lower.contains('current simulation')) {
      final double ps = state.patientSphere;
      final double pc = state.patientCylinder;
      final double pa = state.patientAngle;
      final double wd = state.workingDistance;
      final double ts = state.plusLensesSelected ? state.plusSphere : state.minusSphere;
      final double tc = state.plusLensesSelected ? state.plusCylinder : state.minusCylinder;
      final double ta = state.plusLensesSelected ? state.plusAxis : state.minusAxis;
      final String motion = state.reflexMotion;

      final double grossSphereRequired = ps + wd;
      final double netSphere = ts - wd;

      return '🔬 **Live Clinical Simulation Analysis**:\n\n'
          '• **Patient True Rx**: ${ps > 0 ? '+' : ''}${ps.toStringAsFixed(2)} DS ${pc != 0 ? '${pc.toStringAsFixed(2)} DC × ${pa.toStringAsFixed(0)}°' : '(Spherical)'}\n'
          '• **Working Distance**: ${wd.toStringAsFixed(2)} D (${wd > 0 ? (100 / wd).round() : 0} cm)\n'
          '• **Active Trial Lens**: ${ts > 0 ? '+' : ''}${ts.toStringAsFixed(2)} DS ${tc != 0 ? '${tc.toStringAsFixed(2)} DC × ${ta.toStringAsFixed(0)}°' : ''}\n'
          '• **Observed Reflex**: **${motion.toUpperCase()} MOTION** (${state.reflexWidth.abs().toStringAsFixed(1)} px width, at ${state.reflexAngle.toStringAsFixed(0)}° meridian)\n\n'
          '📋 **Next Step Guidance**:\n'
          '${motion == 'neutral' ? '🌟 **Meridian is Neutralized!** All emergent rays are conjugate at your peephole.' : motion == 'with' ? '➕ You have **WITH motion**. The ocular far point is behind the retinoscope. Add **PLUS sphere** to neutralize.' : '➖ You have **AGAINST motion**. Emergent rays cross in front of the peephole. Add **MINUS sphere** to neutralize.'}\n\n'
          '💡 **Target Gross Neutralizing Lens**: ${grossSphereRequired > 0 ? '+' : ''}${grossSphereRequired.toStringAsFixed(2)} DS\n'
          '💡 **Net Refraction Formula**: Gross (${ts.toStringAsFixed(2)} D) − Working Distance (${wd.toStringAsFixed(2)} D) = **${netSphere > 0 ? '+' : ''}${netSphere.toStringAsFixed(2)} DS**';
    }

    // 2. With vs Against Motion
    if (lower.contains('with') || lower.contains('against') || lower.contains('neutralize')) {
      return '🔄 **With vs. Against Motion Neutralization (AAO Protocol)**:\n\n'
          '1. **WITH Motion** (Direct):\n'
          '   • **Cause**: Far point of the eye is *behind* the retinoscope peephole (Hyperopia, or Myopia less than working distance).\n'
          '   • **Action**: Add **PLUS lenses (+)** to bring the far point forward to the retinoscope plane.\n\n'
          '2. **AGAINST Motion** (Inverted):\n'
          '   • **Cause**: Far point is *in front* of the retinoscope peephole (Myopia greater than working distance, e.g. > 1.50 D at 67 cm).\n'
          '   • **Action**: Add **MINUS lenses (−)** to push the far point back to the retinoscope plane.\n\n'
          '3. **NEUTRALITY FLASH**:\n'
          '   • **Sign**: The pupil completely floods with light, infinite apparent velocity, no edge translation.\n'
          '   • **Formula**: Net Rx = Gross Neutralizing Lens − Working Distance Offset (e.g. −1.50 D at 67 cm).';
    }

    // 3. Astigmatic Break Phenomenon
    if (lower.contains('break') || lower.contains('collinear')) {
      return '💥 **The Break Phenomenon (Axis Misalignment)**:\n\n'
          '• **Definition**: When the light streak is oriented off the principal astigmatic meridian, the internal fundus reflex shears and breaks away from the external facial streak.\n'
          '• **Optical Cause**: The eye has two orthogonal meridians of different refractive power. Oblique incident light is refracted along the principal meridian of least/greatest power rather than the streak direction.\n\n'
          '🎯 **Clinical Pearl**: Slowly rotate the retinoscope sleeve until the external streak and internal reflex form an unbroken, continuous straight line. That confirms the exact principal cylinder axis!';
    }

    // 4. Copeland Straddle Technique
    if (lower.contains('straddle') || lower.contains('copeland')) {
      return '🎯 **Copeland’s ±45° Straddling Technique (Axis Refinement)**:\n\n'
          'Invented by Jack Copeland, this is the most sensitive clinical test for cylinder axis verification:\n\n'
          '1. Position the trial cylinder at the estimated axis α.\n'
          '2. Straddle the streak **45° to the left** (α − 45°) and observe reflex thickness & brightness.\n'
          '3. Straddle the streak **45° to the right** (α + 45°) and observe reflex thickness & brightness.\n\n'
          '⚖️ **Equilibrium Rule**:\n'
          '• **Both sides equal width & brilliance** ➡️ Cylinder axis is 100% accurate!\n'
          '• **Unequal width** ➡️ Rotate the trial cylinder axis toward the *narrower and brighter* straddle orientation.';
    }

    // 5. Mohindra Pediatric Near Retinoscopy
    if (lower.contains('mohindra') || lower.contains('pediatric') || lower.contains('infant') || lower.contains('child')) {
      return '👶 **Mohindra Pediatric Near Retinoscopy Protocol**:\n\n'
          'Used for infants, uncooperative children, or patients where cycloplegia is contraindicated:\n\n'
          '• **Environment**: Completely dark room (extinguish all ambient lights).\n'
          '• **Working Distance**: Exactly **50 cm** (+2.00 D vergence) monocularly.\n'
          '• **Fixation**: Child fixates directly on the retinoscope filament bulb.\n'
          '• **Tonus Compensation Factor**: In the dark, the eye rests at its "dark focus" of accommodation (~0.75 D). Therefore, deduct only **−1.25 D** (instead of −2.00 D) from the gross neutralization.\n\n'
          '📝 **Net Rx Formula**: Net Rx = Gross Neutralizing Lens − 1.25 D.';
    }

    // 6. Plane vs Concave Mirror Optics
    if (lower.contains('mirror') || lower.contains('sleeve') || lower.contains('concave') || lower.contains('plane')) {
      return '🪞 **Retinoscope Sleeve: Plane vs. Concave Mirror Optics**:\n\n'
          '• **Plane Mirror (Sleeve DOWN)**:\n'
          '  - Condensing lens is positioned far from the filament.\n'
          '  - Emits **divergent** rays (virtual source behind mirror).\n'
          '  - Normal motion conventions: Hyperopia = WITH motion, Myopia = AGAINST motion.\n\n'
          '• **Concave Mirror (Sleeve UP)**:\n'
          '  - Condensing lens moves close to filament.\n'
          '  - Emits **convergent** rays crossing at ~33 cm in front of the retinoscope.\n'
          '  - Inverts all apparent motion: Hyperopia = AGAINST motion, Myopia = WITH motion.\n\n'
          '💡 **Clinical Tip**: Slide the sleeve UP near neutrality to confirm the flash point—the reflex will reverse directions cleanly!';
    }

    // 7. Scissors Motion & Keratoconus
    if (lower.contains('scissor') || lower.contains('keratoconus') || lower.contains('aberration') || lower.contains('irregular')) {
      return '✂️ **Scissors Motion & Spherical Aberrations**:\n\n'
          '• **Appearance**: Two separate reflex bands appear at opposite margins of the pupil and close together like blades of a pair of scissors when swept.\n'
          '• **Etiology**: Asymmetrical optical power across the pupillary aperture:\n'
          '  - Keratoconus (steep central conical cornea)\n'
          '  - Pellucid Marginal Degeneration\n'
          '  - Large dilated pupils with positive spherical aberration\n'
          '  - Tilted intraocular lenses (IOLs) or decentered LASIK ablations\n\n'
          '🎯 **Neutralization Strategy**: Bracket and neutralize exclusively the **central 2–3 mm visual axis** reflex, completely ignoring the peripheral aberrated reflex.';
    }

    // 8. Optical Cross & Transposition
    if (lower.contains('transposition') || lower.contains('cross') || lower.contains('formula') || lower.contains('spherical equivalent')) {
      return '🧮 **Optical Cross & Transposition Master Formula**:\n\n'
          'To transpose a prescription between Plus-Cylinder and Minus-Cylinder forms:\n\n'
          '1. **New Sphere** = Sphere + Cylinder\n'
          '2. **New Cylinder** = −Cylinder (reverse algebraic sign)\n'
          '3. **New Axis** = Axis ± 90° (ensure between 1° and 180°)\n'
          '4. **Spherical Equivalent (SE)** = Sphere + (Cylinder / 2)\n\n'
          '📐 **Example**:\n'
          '+2.00 DS −3.00 DC × 75° ➡️\n'
          '• New Sphere: +2.00 + (−3.00) = **−1.00 DS**\n'
          '• New Cylinder: −(−3.00) = **+3.00 DC**\n'
          '• New Axis: 75° + 90° = **165°**\n'
          '• Final Rx: **−1.00 DS +3.00 DC × 165°** (SE = +0.50 DS)';
    }

    // 9. JCC & Duochrome
    if (lower.contains('jcc') || lower.contains('duochrome') || lower.contains('jackson') || lower.contains('red-green')) {
      return '👁️ **Subjective Refinement: Duochrome & Jackson Cross-Cylinder (JCC)**:\n\n'
          '• **Duochrome (Bichrome) Test**:\n'
          '  - Based on chromatic aberration of the eye (60 D refractive power creates ~1.25 D chromatic dispersion between red 656 nm and green 530 nm).\n'
          '  - **Red Clearer** ➡️ Image focused in front of retina (Myopic / Under-corrected) ➡️ Add **Minus power** (−0.25 D).\n'
          '  - **Green Clearer** ➡️ Image focused behind retina (Hyperopic / Over-minus) ➡️ Add **Plus power** (+0.25 D).\n'
          '  - **Equal Clarity** ➡️ Exact spherical conjugacy on retina.\n\n'
          '• **Jackson Cross-Cylinder (JCC)**:\n'
          '  - JCC Axis Refinement: Align JCC handle with trial cylinder axis. Flip position 1 vs 2. Rotate axis toward the red (minus) dots.\n'
          '  - JCC Power Refinement: Align red/white dots with trial axis. Add ±0.25 DC; maintain spherical equivalent with 1:2 sphere compensation.';
    }

    // 10. Clinical Quiz Master
    if (lower.contains('quiz') || lower.contains('test me') || lower.contains('question')) {
      return '🎓 **Clinical Board Exam Challenge**:\n\n'
          '**Question**: You are performing plane-mirror retinoscopy at 67 cm (+1.50 D WD). Along the 90° meridian, you neutralize WITH motion with +4.00 DS. When swept along the 180° meridian, you observe AGAINST motion and neutralize it by adding −2.00 DC at 90°.\n\n'
          '**What is the patient’s final Net Refraction?**\n'
          'A) +4.00 DS −2.00 DC × 90°\n'
          'B) +2.50 DS −2.00 DC × 90°\n'
          'C) +2.50 DS +2.00 DC × 180°\n'
          'D) Both B and C are correct (Transposed forms)\n\n'
          '💬 *Reply with your answer or ask for the step-by-step breakdown!*';
    }

    // 11. General Fallback with intelligent context
    return '🔍 **Clinical Optics Intelligence**:\n\n'
        'You asked about: *"$query"*\n\n'
        'Remember the **3 Cardinal Rules of Streak Retinoscopy**:\n'
        '1. **Speed Rule**: Far from neutrality, reflex is slow. Approaching neutrality, apparent velocity becomes infinite.\n'
        '2. **Width Rule**: The reflex narrows and sharpens maximally when aligned with a principal astigmatic meridian.\n'
        '3. **Brightness Rule**: The reflex reaches peak golden brilliance at the neutrality flash point.\n\n'
        '💡 Would you like to explore **Meridional Neutralization**, **Optical Transposition**, or **Copeland Straddling**?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('AI Clinical Optics Tutor'),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Suggested Topic Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _suggestedTopics.map((topic) {
                  final bool isHighlight = topic.contains('Analyze') || topic.contains('Quiz');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: isHighlight ? Icon(topic.contains('Analyze') ? Icons.analytics : Icons.quiz, size: 14, color: isHighlight ? colorScheme.primary : null) : null,
                      label: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                          color: isHighlight ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      backgroundColor: isHighlight ? colorScheme.primaryContainer.withValues(alpha: 0.6) : colorScheme.surface,
                      onPressed: () => _handleSend(topic),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                final bool isUser = msg['isUser'] as bool;
                final Color bubbleBg = isUser
                    ? colorScheme.primary
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
                final Color textColor = isUser
                    ? colorScheme.onPrimary
                    : (isDark ? Colors.white : const Color(0xFF0F172A));

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bubbleBg,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Query Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Ask about retinoscopy physics, active simulation...',
                        hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: Icon(Icons.send, color: colorScheme.onPrimary, size: 18),
                      onPressed: () => _handleSend(_queryController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
