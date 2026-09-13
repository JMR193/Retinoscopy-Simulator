import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Clinical Notification & Daily Practice Reminder Service
/// Handles daily case alerts, clinical study reminders, and exam milestones.
/// Designed with offline resilience and zero-tracking privacy.
class NotificationService {
  /// Initialize notification service at app startup
  static Future<void> init() async {
    // Intentionally empty for now, can be expanded for local notifications
  }

  /// Check if daily practice reminders are enabled
  static bool isDailyReminderEnabled() {
    return StorageService.getDailyReminderEnabled();
  }

  /// Toggle daily practice reminder
  static Future<void> setDailyReminderEnabled(bool enabled) async {
    await StorageService.setDailyReminderEnabled(enabled);
  }

  /// Get formatted reminder time (e.g., "09:00 AM")
  static String getReminderTimeString() {
    final hour = StorageService.getReminderHour();
    final minute = StorageService.getReminderMinute();
    final hStr = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final mStr = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$hStr:$mStr $period';
  }

  /// Set reminder time
  static Future<void> setReminderTime(int hour, int minute) async {
    await StorageService.setReminderTime(hour, minute);
  }

  /// Displays an in-app clinical daily notification toast/banner
  static void showInAppClinicalNotification({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onTap();
                },
                child: const Text('OPEN', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  /// Get daily clinical practice quote/case prompt
  static Map<String, String> getDailyCasePrompt() {
    final cases = [
      {
        'title': 'Daily Case: Pediatric Latent Hyperopia (+3.50 D)',
        'desc': 'High hyperopia with sluggish WITH motion reflex. Neutralize with Plus lenses.',
      },
      {
        'title': 'Daily Case: High Myopia & Staphyloma (-8.00 D)',
        'desc': 'Rapid AGAINST motion reflex. Check sleeve flip to confirm Far Point position.',
      },
      {
        'title': 'Daily Case: Keratoconus Scissors Motion',
        'desc': 'Dual-blade opposing reflex motion. Identify the principal apical meridian.',
      },
      {
        'title': 'Daily Case: With-The-Rule Astigmatism (90° / 180°)',
        'desc': 'Align streak along 90°, neutralize, then rotate 90° to neutralize cylinder.',
      },
      {
        'title': 'Daily Case: Oblique Astigmatism (+2.00 -2.00 × 45°)',
        'desc': 'Use Copeland ±45° straddle refinement to locate exact astigmatic axis.',
      },
    ];

    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return cases[dayOfYear % cases.length];
  }
}
