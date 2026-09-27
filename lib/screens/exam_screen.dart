import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/certificate_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../state/retinoscopy_state.dart';
import '../widgets/social_share_modal.dart';
import 'leaderboard_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _RxCase {
  final double sphere;
  final double cylinder;
  final double axis;
  final double workingDistance;
  final String patientAge;
  final String clinicalScenario;

  _RxCase({
    required this.sphere,
    required this.cylinder,
    required this.axis,
    this.workingDistance = 1.50,
    required this.patientAge,
    required this.clinicalScenario,
  });

  double get grossM1 => sphere + workingDistance;
  double get grossM2 => sphere + cylinder + workingDistance;
  double get axisM1 => axis;
  double get axisM2 => (axis + 90) > 180 ? axis - 90 : axis + 90;

  @override
  String toString() {
    return '${sphere > 0 ? '+' : ''}${sphere.toStringAsFixed(2)} / ${cylinder.toStringAsFixed(2)} x ${axis.toInt()}°';
  }
}

class _ExamScreenState extends State<ExamScreen> {
  static const int _totalCases = 10;
  static const int _timePerCase = 120;

  final List<_RxCase> _cases = [];
  int _currentIndex = 0;
  int _timeRemaining = _timePerCase;
  final List<Map<String, dynamic>> _answers = [];
  bool _examComplete = false;
  Timer? _timer;
  int _score = 0;

  final TextEditingController _s1Ctrl = TextEditingController();
  final TextEditingController _c1Ctrl = TextEditingController();
  final TextEditingController _a1Ctrl = TextEditingController();
  final TextEditingController _s2Ctrl = TextEditingController();
  final TextEditingController _c2Ctrl = TextEditingController();
  final TextEditingController _a2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateCases();
    _startTimer();
  }

  void _generateCases() {
    final Random rand = Random();
    _cases.clear();
    final scenarios = [
      'Pre-School Vision Screening (With-The-Rule Astigmatism)',
      'High Myopic Astigmatism Refinement',
      'Hyperopic Astigmatism Neutralization',
      'Adolescent Progressive Myopia Evaluation',
      'Oblique Mixed Astigmatism Challenge',
      'Adult Refractive Examination',
      'Pediatric Dark-Room Retinoscopy Case',
      'Against-The-Rule Astigmatic Straddle',
      'Post-Cycloplegic Objective Refraction',
      'Clinical Board Exam Master Case',
    ];
    final ages = ['Age: 4 y/o', 'Age: 16 y/o', 'Age: 24 y/o', 'Age: 32 y/o', 'Age: 45 y/o', 'Age: 8 y/o', 'Age: 19 y/o', 'Age: 28 y/o', 'Age: 52 y/o', 'Age: 12 y/o'];

    for (int i = 0; i < _totalCases; i++) {
      double sphere = -6.0 + (rand.nextInt(49) * 0.25);
      double cylinder = -(rand.nextInt(11) * 0.25);
      double axis = 5.0 + (rand.nextInt(36) * 5);
      double wd = (i % 3 == 0) ? 2.00 : 1.50; // 50 cm or 67 cm
      _cases.add(_RxCase(
        sphere: sphere,
        cylinder: cylinder,
        axis: axis,
        workingDistance: wd,
        patientAge: ages[i % ages.length],
        clinicalScenario: scenarios[i % scenarios.length],
      ));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = _timePerCase;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    AudioService.playTimeout();
    _recordAnswer(skipped: true);
    _advanceToNext();
  }

  void _advanceToNext() {
    _s1Ctrl.clear();
    _c1Ctrl.clear();
    _a1Ctrl.clear();
    _s2Ctrl.clear();
    _c2Ctrl.clear();
    _a2Ctrl.clear();

    if (_currentIndex < _totalCases - 1) {
      setState(() {
        _currentIndex++;
      });
      _startTimer();
    } else {
      _finishExam();
    }
  }

  void _finishExam() {
    _timer?.cancel();
    int correctCount = 0;
    for (int i = 0; i < _answers.length; i++) {
      final answer = _answers[i];
      final bool isCorrect = answer['correct'] == true;
      if (isCorrect) {
        correctCount++;
      }
      if (i < _cases.length) {
        StorageService.addHistoryEntry(
          sphere: _cases[i].sphere,
          cylinder: _cases[i].cylinder,
          axis: _cases[i].axis,
          correct: isCorrect,
        );
      }
    }
    
    // Clinical Competency CME Reward calculation
    int xpReward = correctCount * 300;
    
    if (correctCount == _totalCases && _totalCases > 0) {
      // Perfect Score Bonus!
      xpReward += 1000;
    }
    
    StorageService.addXp(xpReward);

    setState(() {
      _score = correctCount;
      _examComplete = true;
    });
  }

  bool _checkAnswer(
    double s1, double c1, double a1,
    double s2, double c2, double a2,
    double refS, double refC, double refA,
    {bool form2Entered = true},
  ) {
    if (refC.abs() < 0.05) {
      // Pure spherical error: Axis does not affect power
      bool match1 = (s1 - refS).abs() < 0.13 && c1.abs() < 0.13;
      bool match2 = (s2 - refS).abs() < 0.13 && c2.abs() < 0.13;
      return match1 || (form2Entered && match2);
    }
    double refS2 = refS + refC;
    double refC2 = -refC;
    double refA2 = refA + 90.0 > 180.0 ? refA - 90.0 : refA + 90.0;

    bool checkSingleRx(double s, double c, double a, double targetS, double targetC, double targetA) {
      final double axisDiff = RetinoscopyState.calculateAxisDifference(a, targetA);
      final double axisTolerance = targetC.abs() >= 0.50 ? 5.0 : 10.0;
      return (s - targetS).abs() < 0.13 &&
             (c - targetC).abs() < 0.13 &&
             axisDiff <= axisTolerance;
    }

    bool form1MatchesStandard = checkSingleRx(s1, c1, a1, refS, refC, refA);
    bool form1MatchesTransposed = checkSingleRx(s1, c1, a1, refS2, refC2, refA2);

    if (!form2Entered) {
      // Student entered single valid prescription in Form 1
      return form1MatchesStandard || form1MatchesTransposed;
    }

    bool form2MatchesStandard = checkSingleRx(s2, c2, a2, refS, refC, refA);
    bool form2MatchesTransposed = checkSingleRx(s2, c2, a2, refS2, refC2, refA2);

    bool isStandardMatch = form1MatchesStandard && form2MatchesTransposed;
    bool isTransposedMatch = form1MatchesTransposed && form2MatchesStandard;

    return isStandardMatch || isTransposedMatch;
  }

  void _recordAnswer({bool skipped = false}) {
    final _RxCase currentCase = _cases[_currentIndex];
    
    if (skipped) {
      AudioService.playWrong();
      _answers.add({
        'caseIndex': _currentIndex,
        'correct': false,
        'skipped': true,
        'userAnswer': 'Skipped',
        'correctRx': currentCase.toString(),
      });
      return;
    }

    final double s1 = double.tryParse(_s1Ctrl.text) ?? 0.0;
    final double c1 = double.tryParse(_c1Ctrl.text) ?? 0.0;
    final double a1 = double.tryParse(_a1Ctrl.text) ?? 0.0;
    final double s2 = double.tryParse(_s2Ctrl.text) ?? 0.0;
    final double c2 = double.tryParse(_c2Ctrl.text) ?? 0.0;
    final double a2 = double.tryParse(_a2Ctrl.text) ?? 0.0;

    final bool hasForm2 = _s2Ctrl.text.trim().isNotEmpty ||
                          _c2Ctrl.text.trim().isNotEmpty ||
                          _a2Ctrl.text.trim().isNotEmpty;

    final bool isCorrect = _checkAnswer(
      s1, c1, a1, s2, c2, a2,
      currentCase.sphere, currentCase.cylinder, currentCase.axis,
      form2Entered: hasForm2,
    );
    
    if (isCorrect) {
      AudioService.playSuccess();
    } else {
      AudioService.playWrong();
    }

    String userAnswerStr;
    if (hasForm2) {
      userAnswerStr = '${s1.toStringAsFixed(2)} / ${c1.toStringAsFixed(2)} x ${a1.toInt()} AND ${s2.toStringAsFixed(2)} / ${c2.toStringAsFixed(2)} x ${a2.toInt()}';
    } else {
      userAnswerStr = '${s1.toStringAsFixed(2)} / ${c1.toStringAsFixed(2)} x ${a1.toInt()}';
    }
    
    _answers.add({
      'caseIndex': _currentIndex,
      'correct': isCorrect,
      'skipped': false,
      'userAnswer': userAnswerStr,
      'correctRx': currentCase.toString(),
    });
  }

  void _submitAnswer() {
    _recordAnswer(skipped: false);
    _advanceToNext();
  }

  void _skipCase() {
    _recordAnswer(skipped: true);
    _advanceToNext();
  }

  Future<bool> _onWillPop() async {
    if (_examComplete) {
      return true;
    }
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Exam?'),
          content: const Text('Your progress will be lost. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _s1Ctrl.dispose();
    _c1Ctrl.dispose();
    _a1Ctrl.dispose();
    _s2Ctrl.dispose();
    _c2Ctrl.dispose();
    _a2Ctrl.dispose();
    super.dispose();
  }

  Color _getTimerColor() {
    if (_timeRemaining < 30) {
      return Colors.red;
    } else if (_timeRemaining < 60) {
      return Colors.orange;
    }
    return Colors.green;
  }
  
  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _retakeExam() {
    setState(() {
      _answers.clear();
      _score = 0;
      _currentIndex = 0;
      _examComplete = false;
      _generateCases();
      _startTimer();
    });
  }

  void _shareResults() {
    final String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final int percent = (_score / _totalCases * 100).toInt();
    final String candidateName = StorageService.getUserName();
    final String displayName = candidateName.isEmpty ? 'Clinical Candidate' : candidateName;
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('📋 JMR Technologies — Retinoscopy Simulator');
    buffer.writeln('Exam Report & Clinical Competency Assessment');
    buffer.writeln('Candidate: $displayName');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Final Score: $_score/$_totalCases ($percent%)');
    buffer.writeln('─' * 32);
    
    for (int i = 0; i < _answers.length; i++) {
      final Map<String, dynamic> ans = _answers[i];
      final String status = ans['correct'] == true ? '✓ Pass' : '✗ Review';
      final String correctRx = ans['correctRx'] as String;
      buffer.writeln('Case ${i + 1}: $status (Target: $correctRx)');
    }
    buffer.writeln('');
    buffer.writeln('Verified via Retinoscopy Simulator Pro • #Optometry #RetinoscopyExam');

    SocialShareModal.show(
      context: context,
      title: 'Share Exam Report',
      subtitle: 'Score: $_score/$_totalCases ($percent%) • $dateStr',
      shareText: buffer.toString(),
      type: ShareType.examReport,
    );
  }

  Widget _buildActiveExam() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentCase = _cases[_currentIndex];

    return Column(
      children: [
        LinearProgressIndicator(value: (_currentIndex + 1) / _totalCases, color: colorScheme.primary),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                backgroundColor: colorScheme.primaryContainer,
                label: Text(
                  'Case ${_currentIndex + 1} of $_totalCases',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Case #${_currentIndex + 1}: ${currentCase.clinicalScenario}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentCase.patientAge,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.remove_red_eye, color: Colors.blue, size: 16),
                          SizedBox(width: 6),
                          Text('Objective Retinoscopy Findings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Working Distance: ${currentCase.workingDistance.toStringAsFixed(2)} D (${(100 / currentCase.workingDistance).round()} cm)',
                        style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        '• Meridian 1 (${currentCase.axisM1.toInt()}°): Neutralized at Gross ${currentCase.grossM1 > 0 ? '+' : ''}${currentCase.grossM1.toStringAsFixed(2)} DS',
                        style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      ),
                      Text(
                        '• Meridian 2 (${currentCase.axisM2.toInt()}°): Neutralized at Gross ${currentCase.grossM2 > 0 ? '+' : ''}${currentCase.grossM2.toStringAsFixed(2)} DS',
                        style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Question: Deduct working distance and write the patient’s final Net Rx in Primary Form (Form 1). Transposed Form (Form 2) is optional:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Form 1 Inputs
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Form 1 (Primary Prescription — Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _s1Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Sphere (DS)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _c1Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Cyl (DC)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _a1Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Axis (°)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Form 2 Inputs
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Form 2 (Transposed Prescription — Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _s2Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Sphere (DS)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _c2Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Cyl (DC)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _a2Ctrl, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Axis (°)', border: OutlineInputBorder(), isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submitAnswer,
                  icon: const Icon(Icons.check_circle_outline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Submit & Evaluate Answer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _skipCase,
                  style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
                  child: const Text('Skip Case (Mark as Incomplete)'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final int percent = (_score / _totalCases * 100).toInt();
    String gradeLabel;
    Color gradeColor;
    if (percent >= 90) {
      gradeLabel = 'Excellent';
      gradeColor = Colors.green;
    } else if (percent >= 70) {
      gradeLabel = 'Good';
      gradeColor = Colors.blue;
    } else if (percent >= 50) {
      gradeLabel = 'Fair';
      gradeColor = Colors.orange;
    } else {
      gradeLabel = 'Needs Practice';
      gradeColor = Colors.red;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: gradeColor.withValues(alpha: 0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_score/$_totalCases',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 14),
                  Chip(
                    label: Text(gradeLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: gradeColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // --- Clinical Competency Credits ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 6),
                  Text('+${_score * 50} Clinical CME Points', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(width: 16),
                  const Icon(Icons.verified_outlined, color: Colors.teal, size: 20),
                  const SizedBox(width: 6),
                  Text('$percent% Accuracy Index', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
              const SizedBox(height: 12),
              // Competency Domains
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDomainPill('Spherical', percent >= 80 ? 'Master' : 'Review', percent >= 80 ? Colors.green : Colors.orange),
                  _buildDomainPill('Astigmatism', percent >= 70 ? 'Proficient' : 'Practice', percent >= 70 ? Colors.blue : Colors.red),
                  _buildDomainPill('Transposition', percent >= 90 ? 'Expert' : 'Good', percent >= 90 ? Colors.purple : Colors.amber[800]!),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _answers.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> ans = _answers[index];
              final bool isCorrect = ans['correct'] == true;
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDark ? const Color(0xFF1E293B) : colorScheme.surface,
                child: ListTile(
                  leading: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  title: Text(
                    'Case ${index + 1}: ${index < _cases.length ? _cases[index].clinicalScenario : ''}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colorScheme.onSurface),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Target Net Rx: ${ans['correctRx']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                        Text('• Your Submission: ${ans['userAnswer']}', style: TextStyle(color: isCorrect ? colorScheme.onSurface : Colors.redAccent, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        if (percent >= 90) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  CertificateService.generateAndShare(
                    candidateName: StorageService.getUserName(),
                    score: _score,
                    totalCases: _totalCases,
                  );
                },
                icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                label: const Text('Download Clinical Certificate (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade800 : Colors.indigo[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                },
                icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                label: const Text('View Global Clinical Leaderboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retakeExam,
                  child: const Text('Retake Exam'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _shareResults,
                  child: const Text('Share Results'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _examComplete,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_examComplete ? 'Exam Results' : 'Exam Mode — Case ${_currentIndex + 1}/$_totalCases'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Global Leaderboard',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              },
            ),
          ],
        ),
        body: _examComplete ? _buildResults() : _buildActiveExam(),
      ),
    );
  }

  Widget _buildDomainPill(String domain, String rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(domain, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(rating, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

