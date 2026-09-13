import 'dart:ui';
import 'package:flutter/material.dart';
import '../state/retinoscopy_state.dart';

class SubjectiveView extends StatelessWidget {
  final RetinoscopyState state;

  const SubjectiveView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // ── Sub-test selector chips ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Duochrome', 'JCC Axis', 'JCC Power'].map((testName) {
              final isSelected = state.activeSubjectiveTest == testName;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: FilterChip(
                  label: Text(testName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      state.setActiveSubjectiveTest(testName);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ),

        // ── Patient Visual Chart (Snellen / Duochrome) ──────────────────────
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Visual acuity blur simulation
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: state.visualBlurSigma,
                    sigmaY: state.visualBlurSigma,
                  ),
                  child: state.activeSubjectiveTest == 'Duochrome'
                      ? _buildDuochromeChart()
                      : _buildSnellenChart(),
                ),
              ),
              
              // JCC position indicator overlay
              if (state.activeSubjectiveTest.startsWith('JCC'))
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.jccFlipState == 1 ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'JCC Position ${state.jccFlipState} (±0.25)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // ── JCC Interactive Control Toolbar ──────────────────────────────────
        if (state.activeSubjectiveTest.startsWith('JCC')) ...[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.flipJcc,
                    icon: const Icon(Icons.flip_camera_android, size: 18),
                    label: Text('Flip JCC (Pos ${state.jccFlipState == 1 ? 2 : 1})'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (state.activeSubjectiveTest == 'JCC Power') ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => state.adjustJccCylinderWithSphericalEquivalence(0.25),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                          child: const Text('+0.25 DC (SE)'),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          onPressed: () => state.adjustJccCylinderWithSphericalEquivalence(-0.25),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                          child: const Text('-0.25 DC (SE)'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Patient Speech Bubble (Clinical Feedback) ──────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Response (${state.activeSubjectiveTest}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.patientSubjectiveResponse,
                      style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500),
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

  Widget _buildDuochromeChart() {
    return Row(
      children: [
        // Red side
        Expanded(
          child: Container(
            color: const Color(0xFFD32F2F),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('E', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('F P', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('T O Z', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ),
        // Green side
        Expanded(
          child: Container(
            color: const Color(0xFF2E7D32),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('E', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('F P', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('T O Z', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnellenChart() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('E', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('F P', style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('T O Z', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('L P E D', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('P E C F D', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
        ],
      ),
    );
  }
}
