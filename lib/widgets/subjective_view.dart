import 'dart:ui';
import 'package:flutter/material.dart';
import '../state/retinoscopy_state.dart';

class SubjectiveView extends StatelessWidget {
  final RetinoscopyState state;

  const SubjectiveView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Patient Snellen / Duochrome chart display
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Chart Background
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
              
              // Purkinje/Lens outline overlay representation if JCC active
              if (state.activeSubjectiveTest.startsWith('JCC'))
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'JCC Position: ${state.jccFlipState}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Patient Speech Bubble (Feedback)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient says:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.patientSubjectiveResponse,
                      style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
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
            color: Colors.red[600],
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('E', style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('F P', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('T O Z', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ),
        // Green side
        Expanded(
          child: Container(
            color: Colors.green[600],
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('E', style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('F P', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('T O Z', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black)),
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
          Text('E', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('F P', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('T O Z', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('L P E D', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
          Text('P E C F D', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 4)),
        ],
      ),
    );
  }
}
