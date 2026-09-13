import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import 'social_share_modal.dart';

class ScoreCardGenerator {
  /// Opens the modern Social Share Modal with a live visual preview card
  static void showShareModal(BuildContext context) {
    final int xp = StorageService.getXp();
    final int level = (xp ~/ 1000) + 1;
    final int streak = StorageService.getStudyStreak();
    final int total = StorageService.getTotalTests();
    final double accuracy = StorageService.getAccuracyPercent();
    final String candidateName = StorageService.getUserName();
    final String displayName = candidateName.isEmpty ? 'Clinical Optometrist' : candidateName;

    final String shareText =
        '🎯 Retinoscopy Simulator — Clinical Competency Achievement!\n'
        'Candidate: $displayName\n'
        'Level: Level $level ($xp XP)\n'
        'Clinical Streak: $streak Day Streak 🔥\n'
        'Assessments: $total cases (${accuracy.toStringAsFixed(1)}% Accuracy)\n'
        'Can you beat my score? Download Retinoscopy Simulator by JMR Technologies! #Optometry #Retinoscopy #Ophthalmology';

    SocialShareModal.show(
      context: context,
      title: 'Share Achievement',
      subtitle: 'Share your clinical streak & rank with colleagues',
      shareText: shareText,
      cardPreview: SizedBox(
        width: 260,
        height: 380,
        child: _buildScoreCardWidget(
          level: level,
          streak: streak,
          xp: xp,
          total: total,
          accuracy: accuracy,
          name: displayName,
          scale: 0.85,
        ),
      ),
      onShareImage: () => _generateAndShareImage(context, level, streak, shareText),
      type: ShareType.clinicalCard,
    );
  }

  /// Legacy direct share preserved for backwards compatibility
  static Future<void> shareScoreCard(BuildContext context) async {
    showShareModal(context);
  }

  static Future<void> _generateAndShareImage(
    BuildContext context,
    int level,
    int streak,
    String shareText,
  ) async {
    final GlobalKey repaintBoundaryKey = GlobalKey();
    final int xp = StorageService.getXp();
    final int total = StorageService.getTotalTests();
    final double accuracy = StorageService.getAccuracyPercent();
    final String candidateName = StorageService.getUserName();
    final String displayName = candidateName.isEmpty ? 'Clinical Optometrist' : candidateName;

    final overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: -3000,
          top: -3000,
          child: RepaintBoundary(
            key: repaintBoundaryKey,
            child: _buildScoreCardWidget(
              level: level,
              streak: streak,
              xp: xp,
              total: total,
              accuracy: accuracy,
              name: displayName,
              scale: 1.0,
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final RenderRepaintBoundary boundary =
          repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/retinoscopy_score_card.png').create();
      await file.writeAsBytes(pngBytes);

      overlayEntry.remove();

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          files: [XFile(file.path)],
          subject: 'Retinoscopy Simulator Achievement Card',
        ),
      );
    } catch (e) {
      overlayEntry.remove();
      debugPrint('Failed to share score card: $e');
      SharePlus.instance.share(ShareParams(text: shareText));
    }
  }

  static Widget _buildScoreCardWidget({
    required int level,
    required int streak,
    required int xp,
    required int total,
    required double accuracy,
    required String name,
    double scale = 1.0,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 360 * scale,
        height: 520 * scale,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A0F1D), Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24 * scale),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Decorative Optics Pattern
            Positioned(
              right: -30 * scale,
              top: -30 * scale,
              child: Container(
                width: 140 * scale,
                height: 140 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -40 * scale,
              bottom: -40 * scale,
              child: Container(
                width: 160 * scale,
                height: 160 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Card Contents
            Padding(
              padding: EdgeInsets.all(22.0 * scale),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                        ),
                        child: Icon(Icons.remove_red_eye, color: Colors.cyanAccent, size: 26 * scale),
                      ),
                      SizedBox(width: 10 * scale),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RETINOSCOPY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                          Text(
                            'SIMULATOR PRO',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Candidate Name Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 6 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20 * scale),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: Colors.white70, size: 14 * scale),
                        SizedBox(width: 6 * scale),
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Level Badge with Glow
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 22 * scale, vertical: 12 * scale),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
                      ),
                      borderRadius: BorderRadius.circular(30 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CLINICAL LEVEL $level',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$xp TOTAL XP EARNED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Key Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Streak
                      _buildMetricBox(
                        icon: Icons.local_fire_department,
                        iconColor: Colors.orangeAccent,
                        value: '$streak Days',
                        label: 'STUDY STREAK',
                        scale: scale,
                      ),
                      // Accuracy
                      _buildMetricBox(
                        icon: Icons.track_changes,
                        iconColor: Colors.greenAccent,
                        value: '${accuracy.toStringAsFixed(0)}%',
                        label: 'ACCURACY',
                        scale: scale,
                      ),
                      // Total Cases
                      _buildMetricBox(
                        icon: Icons.verified,
                        iconColor: Colors.cyanAccent,
                        value: '$total',
                        label: 'CASES SOLVED',
                        scale: scale,
                      ),
                    ],
                  ),

                  // Footer Call to Action & Brand
                  Column(
                    children: [
                      Text(
                        'Can you neutralize faster than me?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11 * scale,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'JMR Technologies • Clinical Optometry Education',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 8.5 * scale,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMetricBox({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required double scale,
  }) {
    return Container(
      width: 90 * scale,
      padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22 * scale),
          SizedBox(height: 4 * scale),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 7.5 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
