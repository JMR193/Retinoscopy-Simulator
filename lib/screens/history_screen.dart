import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../widgets/social_share_modal.dart';

/// Test History Screen — JMR Technologies Retinoscopy Simulator
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = StorageService.getHistory();
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all test history and reset your accuracy stats?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.clearHistory();
      setState(() => _history = []);
    }
  }

  String _formatRx(double s, double c, double a) {
    String sphereStr = '${s >= 0 ? '+' : ''}${s.toStringAsFixed(2)}';
    String cylStr = '${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)}';
    return '$sphereStr DS $cylStr DC × ${a.toStringAsFixed(0)}°';
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _shareHistory() async {
    if (_history.isEmpty) return;
    final total = StorageService.getTotalTests();
    final correct = StorageService.getTotalCorrect();
    final accuracy = StorageService.getAccuracyPercent();
    final String candidateName = StorageService.getUserName();
    final String displayName = candidateName.isEmpty ? 'Clinical Optometrist' : candidateName;

    final buffer = StringBuffer();
    buffer.writeln('📊 Retinoscopy Simulator — JMR Technologies');
    buffer.writeln('Clinical Test History & Competency Summary');
    buffer.writeln('Practitioner: $displayName');
    buffer.writeln('Total Assessments: $total | Correct: $correct | Overall Accuracy: ${accuracy.toStringAsFixed(1)}%');
    buffer.writeln('─' * 36);

    for (final entry in _history.take(20)) {
      final ts = _formatTimestamp(entry['timestamp'] as String? ?? '');
      final rx = _formatRx(
        (entry['sphere'] as num).toDouble(),
        (entry['cylinder'] as num).toDouble(),
        (entry['axis'] as num).toDouble(),
      );
      final result = (entry['correct'] as bool) ? '✓' : '✗';
      buffer.writeln('$ts | $result | $rx');
    }
    buffer.writeln('');
    buffer.writeln('Master retinoscopy skills with Retinoscopy Simulator Pro! #Optometry');

    SocialShareModal.show(
      context: context,
      title: 'Share Clinical History',
      subtitle: '$total Cases • ${accuracy.toStringAsFixed(1)}% Accuracy',
      shareText: buffer.toString(),
      type: ShareType.testHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final totalTests = StorageService.getTotalTests();
    final totalCorrect = StorageService.getTotalCorrect();
    final accuracy = StorageService.getAccuracyPercent();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Test History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy to Clipboard',
              onPressed: _shareHistory,
            ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Stats Header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Total', totalTests.toString(), Icons.quiz_outlined),
                      _buildStatDivider(),
                      _buildStat('Correct', totalCorrect.toString(), Icons.check_circle_outline),
                      _buildStatDivider(),
                      _buildStat(
                        'Accuracy',
                        '${accuracy.toStringAsFixed(1)}%',
                        Icons.analytics_outlined,
                        highlight: accuracy >= 80,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Accuracy Progress Bar ─────────────────────────────────
                if (totalTests > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overall Accuracy', style: theme.textTheme.labelMedium),
                            Text(
                              '${accuracy.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accuracy >= 80 ? Colors.green : accuracy >= 50 ? Colors.orange : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: accuracy / 100.0,
                            minHeight: 10,
                            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accuracy >= 80 ? Colors.green : accuracy >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // ── History List ──────────────────────────────────────────
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No test history yet.',
                                style: theme.textTheme.titleMedium?.copyWith(color: isDark ? Colors.white70 : Colors.grey[500]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Switch to Test Mode and complete a case\nto see your results here.',
                                style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.grey[400]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _history.length,
                          itemBuilder: (context, i) {
                            final entry = _history[i];
                            final correct = entry['correct'] as bool;
                            final sphere = (entry['sphere'] as num).toDouble();
                            final cylinder = (entry['cylinder'] as num).toDouble();
                            final axis = (entry['axis'] as num).toDouble();
                            final timestamp = _formatTimestamp(entry['timestamp'] as String? ?? '');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark
                                      ? (correct ? Colors.green.withValues(alpha: 0.18) : Colors.red.withValues(alpha: 0.18))
                                      : (correct ? Colors.green[50] : Colors.red[50]),
                                  child: Icon(
                                    correct ? Icons.check : Icons.close,
                                    color: isDark
                                        ? (correct ? Colors.greenAccent : Colors.redAccent)
                                        : (correct ? Colors.green[700] : Colors.red[700]),
                                  ),
                                ),
                                title: Text(
                                  _formatRx(sphere, cylinder, axis),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Text(
                                  timestamp,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500]),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (correct ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2))
                                        : (correct ? Colors.green[100] : Colors.red[100]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    correct ? 'Correct' : 'Incorrect',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? (correct ? Colors.greenAccent : Colors.redAccent)
                                          : (correct ? Colors.green[800] : Colors.red[800]),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {bool highlight = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.yellowAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 48, color: Colors.white24);
  }
}
