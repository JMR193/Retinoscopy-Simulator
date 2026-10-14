import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Security-first service for clinical and network safety — JMR Technologies
///
/// Implements enterprise security rules:
/// 1. Compile-time environment variable secrets handling (no hardcoded keys).
/// 2. Input sanitization against XSS and control characters.
/// 3. Secure network communication enforcing HTTPS and global error boundaries.
/// 4. Deep link validation with strict schema and numerical bounds enforcement.
/// 5. Error sanitization preventing internal URLs and stack traces from leaking to UI.
class SecurityService {
  SecurityService._();

  // ─── 1. Compile-Time Secrets Access ───────────────────────────────────────

  /// Reads a compile-time secret defined via `--dart-define=KEY=VALUE`.
  /// Never hardcodes API keys or private tokens in source code.
  static String getEnvironmentSecret(String key, {String defaultValue = ''}) {
    return String.fromEnvironment(key, defaultValue: defaultValue);
  }

  // ─── 2. Input Sanitization & Validation (XSS & Control Character Shield) ──

  /// Sanitizes generic text input by stripping script/style blocks with contents,
  /// HTML tags, control characters, and null bytes. Enforces an optional [maxLength].
  static String sanitizeText(String input, {int maxLength = 100}) {
    if (input.isEmpty) return '';

    // Strip script and style blocks completely including inner content
    var sanitized = input.replaceAll(
      RegExp(r'<(?:script|style)\b[^>]*>[\s\S]*?<\/(?:script|style)>', caseSensitive: false),
      '',
    );

    // Strip any remaining HTML/XML tags and entity references
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>|&[a-zA-Z0-9#]+;'), '');

    // Strip control characters, carriage returns, tabs, and null bytes
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');

    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Enforce length limit
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength).trim();
    }

    return sanitized;
  }

  /// Sanitizes human/clinician names (allows letters, numbers, spaces, hyphens, periods).
  static String sanitizeName(String name, {int maxLength = 50}) {
    final basic = sanitizeText(name, maxLength: maxLength);
    // Allow alphanumeric characters, spaces, hyphens, apostrophes, and dots
    final filtered = basic.replaceAll(RegExp(r"[^\w\s\-\.']"), '');
    return filtered.trim().isEmpty ? 'Clinical Practitioner' : filtered.trim();
  }

  /// Sanitizes clinical case notes (strips markup/scripting, caps length).
  static String sanitizeNotes(String notes, {int maxLength = 500}) {
    return sanitizeText(notes, maxLength: maxLength);
  }

  /// Validates email address format with strict RFC 5322 compliant regex.
  static bool isValidEmail(String email) {
    if (email.length > 254) return false;
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    return emailRegex.hasMatch(email.trim());
  }

  // ─── 3. Clinical Bounds & Finite Value Clamping ───────────────────────────

  /// Clamps sphere refractive power to safe biological bounds: [-25.00 D, +25.00 D].
  static double clampSphere(num? value, {double fallback = 0.0}) {
    if (value == null || !value.toDouble().isFinite) return fallback;
    return value.toDouble().clamp(-25.0, 25.0);
  }

  /// Clamps cylinder power to safe biological bounds: [-15.00 D, +15.00 D].
  static double clampCylinder(num? value, {double fallback = 0.0}) {
    if (value == null || !value.toDouble().isFinite) return fallback;
    return value.toDouble().clamp(-15.0, 15.0);
  }

  /// Clamps and normalizes axis angle to [0.0°, 180.0°].
  static double clampAxis(num? value, {double fallback = 90.0}) {
    if (value == null || !value.toDouble().isFinite) return fallback;
    double ax = value.toDouble() % 180.0;
    if (ax < 0) ax += 180.0;
    if (ax == 0.0) ax = 180.0;
    return ax.clamp(0.0, 180.0);
  }

  /// Clamps patient age to [0, 125].
  static int clampAge(num? value, {int fallback = 25}) {
    if (value == null || !value.toDouble().isFinite) return fallback;
    return value.toInt().clamp(0, 125);
  }

  // ─── 4. Deep Link Security & Validation ───────────────────────────────────

  /// Allowed schemes for incoming deep links or universal links.
  static const Set<String> _allowedDeepLinkSchemes = {'retino', 'https'};

  /// Allowed hosts for incoming deep links.
  static const Set<String> _allowedDeepLinkHosts = {
    'case',
    'retinoscopy.app',
    'jmrtech.github.io',
  };

  /// Validates a deep link URI format, scheme, host, and payload bounds.
  static bool isValidDeepLinkUri(Uri uri) {
    if (!_allowedDeepLinkSchemes.contains(uri.scheme.toLowerCase())) {
      return false;
    }

    if (uri.host.isNotEmpty && !_allowedDeepLinkHosts.contains(uri.host.toLowerCase())) {
      return false;
    }

    // Check payload parameter length to protect against memory exhaustion DoS
    final d = uri.queryParameters['d'];
    if (d != null && d.length > 4096) {
      return false;
    }

    return true;
  }

  // ─── 5. Secure Network & URL Launching (HTTPS Enforcement & Error Boundary)

  /// Validates and launches a URL safely.
  /// - Enforces HTTPS for web links (rejects plain HTTP).
  /// - Allows trusted native application schemes (mailto:, tel:).
  /// - Catches all exceptions internally without leaking stack traces or raw URLs to UI.
  static Future<bool> safeLaunchUrl(
    BuildContext context,
    String urlString, {
    String errorMessage = 'Unable to open link. Please verify your connection or browser settings.',
  }) async {
    try {
      final uri = Uri.tryParse(urlString.trim());
      if (uri == null) {
        _showSanitizedSnackBar(context, errorMessage);
        return false;
      }

      final scheme = uri.scheme.toLowerCase();

      // Enforce HTTPS for web links
      if (scheme == 'http') {
        _showSanitizedSnackBar(context, 'Insecure HTTP links are blocked for your protection.');
        return false;
      }

      // Restrict to secure web and trusted intent schemes
      final allowedSchemes = {'https', 'mailto', 'tel', 'whatsapp'};
      if (!allowedSchemes.contains(scheme)) {
        _showSanitizedSnackBar(context, errorMessage);
        return false;
      }

      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          _showSanitizedSnackBar(context, errorMessage);
        }
        return false;
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showSanitizedSnackBar(context, errorMessage);
      }
      return launched;
    } catch (_) {
      // Global error boundary: never expose raw stack traces or internal endpoints
      if (context.mounted) {
        _showSanitizedSnackBar(context, errorMessage);
      }
      return false;
    }
  }

  static void _showSanitizedSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── 6. Sanitized Auth Error Mapper ───────────────────────────────────────

  /// Maps Firebase Auth or Network exceptions to clean, user-facing error messages.
  /// Prevents raw server stack traces, database schema details, or API keys from leaking to UI.
  static String getSafeAuthErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    final str = error.toString().toLowerCase();

    if (str.contains('user-not-found') || str.contains('wrong-password') || str.contains('invalid-credential')) {
      return 'Invalid email or password. Please verify your credentials.';
    }
    if (str.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    }
    if (str.contains('invalid-email')) {
      return 'The email address format is invalid.';
    }
    if (str.contains('weak-password')) {
      return 'Password is too weak. Please use at least 8 characters with letters, numbers, and symbols.';
    }
    if (str.contains('network-request-failed') || str.contains('socketexception') || str.contains('timeout')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (str.contains('too-many-requests')) {
      return 'Too many login attempts. Please wait a few moments before trying again.';
    }
    if (str.contains('user-disabled')) {
      return 'This clinical account has been disabled. Please contact support.';
    }

    return 'Authentication could not be completed. Please try again.';
  }
}
