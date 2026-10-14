import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';

/// About Screen — JMR Technologies Retinoscopy Simulator
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  Future<void> _launchUrl(String url) async {
    await SecurityService.safeLaunchUrl(context, url);
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete your test history, profile, and all preferences. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _packageInfo?.version ?? '1.1.0';
    final build = _packageInfo?.buildNumber ?? '2';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('About Retinoscopy Simulator'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── App Logo & Version ────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.remove_red_eye, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Retinoscopy Simulator',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Elite Clinical Edition • Version $version (Build $build)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JMR Technologies',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Medical Disclaimer ─────────────────────────────────────────
            _buildSection(
              icon: Icons.medical_information_outlined,
              iconColor: Colors.orange,
              title: 'Medical Disclaimer',
              content:
                  'This application is designed for educational and training purposes only. '
                  'It is NOT a licensed medical device and must NOT be used for clinical diagnosis, '
                  'patient screening, or any form of medical decision-making.\n\n'
                  'Always consult a qualified ophthalmologist or optometrist for clinical assessments. '
                  'JMR Technologies accepts no liability for any clinical decisions made based on this simulation.',
              contentColor: isDark ? Colors.orange.shade200 : Colors.orange[900],
              backgroundColor: isDark ? Colors.orange.withValues(alpha: 0.12) : Colors.orange[50],
              borderColor: isDark ? Colors.orange.withValues(alpha: 0.35) : Colors.orange[200],
            ),
            const SizedBox(height: 16),

            // ── What This App Does ─────────────────────────────────────────
            _buildSection(
              icon: Icons.school_outlined,
              iconColor: colorScheme.primary,
              title: 'About This App',
              content:
                  'Retinoscopy Simulator provides an interactive, physics-accurate simulation of streak '
                  'retinoscopy for ophthalmology students, optometry residents, and clinical trainers.\n\n'
                  'Features include: real-time red-reflex simulation, oblique astigmatism modeling, '
                  'scissors motion, working distance compensation, subjective refraction tests, '
                  'an offline AI clinical hint engine, and a test mode with scoring history.',
            ),
            const SizedBox(height: 16),

            // ── Privacy Policy ─────────────────────────────────────────────
            _buildSection(
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.green[700]!,
              title: 'Privacy Policy',
              content:
                  'This app does not collect, transmit, or share any personal data. '
                  'All data (test history, preferences) is stored locally on your device only. '
                  'No analytics, no tracking, no advertisements.',
              actionLabel: 'View Full Privacy Policy',
              onAction: () => _launchUrl(
                'https://jmrtech.github.io/retinoscopy-simulator/privacy',
              ),
            ),
            const SizedBox(height: 16),

            // ── Acknowledgments ────────────────────────────────────────────
            _buildSection(
              icon: Icons.favorite_outline,
              iconColor: Colors.red,
              title: 'Acknowledgments',
              content:
                  '• American Academy of Ophthalmology (AAO) Retinoscopy Simulator\n'
                  '• Microsoft Auto-Retinoscopy Research (GitHub)\n'
                  '• Flutter & Dart SDK by Google\n'
                  '• Clinical retinoscopy physics: Keating M.P., "Geometric, Physical, and Visual Optics"\n'
                  '• JMR Technologies development team',
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ─────────────────────────────────────────────
            _buildActionButton(
              icon: Icons.star_rate_rounded,
              label: 'Rate on Play Store',
              color: Colors.amber[700]!,
              onTap: () => _launchUrl(
                'https://play.google.com/store/apps/details?id=com.jmrtech.retinoscopy_simulator',
              ),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              icon: Icons.email_outlined,
              label: 'Contact Support',
              color: colorScheme.primary,
              onTap: () => _launchUrl('mailto:support@jmrtech.com?subject=Retinoscopy Simulator Support'),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Clear All My Data (GDPR)',
              color: Colors.red[700]!,
              onTap: _showClearDataDialog,
            ),
            const SizedBox(height: 32),
            Text(
              '© 2025 JMR Technologies. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Educational use only — not for clinical diagnosis.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[300],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? actionLabel,
    VoidCallback? onAction,
    Color? contentColor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF161618) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: contentColor ?? (isDark ? Colors.white.withValues(alpha: 0.88) : Colors.black87),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
