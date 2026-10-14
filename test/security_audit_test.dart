import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:retinoscopy_simulator/services/security_service.dart';
import 'package:retinoscopy_simulator/models/patient_profile.dart';

void main() {
  group('Security Rule 1: Compile-time Secrets & Environment Variables', () {
    test('getEnvironmentSecret defaults safely without crashing or exposing keys', () {
      final secret = SecurityService.getEnvironmentSecret('API_KEY', defaultValue: 'default_safe');
      expect(secret, equals('default_safe'));
    });
  });

  group('Security Rule 3 & 4: Input Sanitization & Clean Data Handling', () {
    test('sanitizeText strips dangerous HTML, script tags, and control characters', () {
      const malicious = '<script>alert("XSS")</script>Dr. John Doe\x00\x1B';
      final clean = SecurityService.sanitizeText(malicious);
      expect(clean.contains('<script>'), isFalse);
      expect(clean.contains('alert'), isFalse);
      expect(clean.contains('\x00'), isFalse);
      expect(clean, equals('Dr. John Doe'));
    });

    test('sanitizeName enforces alphanumeric, hyphens, and max length', () {
      const maliciousName = '<img src=x onerror=alert(1)>Dr. Jane Smith-O\'Connor & Co. #1';
      final cleanName = SecurityService.sanitizeName(maliciousName, maxLength: 30);
      expect(cleanName.contains('<'), isFalse);
      expect(cleanName.contains('>'), isFalse);
      expect(cleanName.length, lessThanOrEqualTo(30));
      expect(cleanName, contains('Dr. Jane Smith-O\'Connor'));
    });

    test('sanitizeNotes strips tags and trims to length', () {
      const longNotes = '<p>Patient exhibits <b>scissors motion</b> with irregular keratoconus.</p>';
      final cleanNotes = SecurityService.sanitizeNotes(longNotes);
      expect(cleanNotes, equals('Patient exhibits scissors motion with irregular keratoconus.'));
    });

    test('isValidEmail accepts valid RFC emails and rejects invalid/injection payloads', () {
      expect(SecurityService.isValidEmail('doctor@hospital.org'), isTrue);
      expect(SecurityService.isValidEmail('optom.smith+clinic@uni.edu'), isTrue);

      expect(SecurityService.isValidEmail(''), isFalse);
      expect(SecurityService.isValidEmail('not-an-email'), isFalse);
      expect(SecurityService.isValidEmail('doctor@'), isFalse);
      expect(SecurityService.isValidEmail('@hospital.org'), isFalse);
      expect(SecurityService.isValidEmail('doctor<script>@hospital.org'), isFalse);
      expect(SecurityService.isValidEmail('doctor@hospital.org; DROP TABLE users;'), isFalse);
    });

    test('Auth error mapper provides user-safe messages without leaking stack traces or internal URLs', () {
      expect(
        SecurityService.getSafeAuthErrorMessage('FirebaseAuthException: [user-not-found]'),
        contains('Invalid email or password'),
      );
      expect(
        SecurityService.getSafeAuthErrorMessage('FirebaseAuthException: [network-request-failed] at https://identitytoolkit.googleapis.com/v1/...'),
        isNot(contains('identitytoolkit.googleapis.com')),
      );
      expect(
        SecurityService.getSafeAuthErrorMessage('FirebaseAuthException: [network-request-failed]'),
        contains('Network connection error'),
      );
    });
  });

  group('Security Rule 5: Deep Link Security & Numerical Bounds Validation', () {
    test('isValidDeepLinkUri accepts valid retino://case deep links', () {
      final uri = Uri.parse('retino://case?d=eyJ2IjoxfQ==');
      expect(SecurityService.isValidDeepLinkUri(uri), isTrue);
    });

    test('isValidDeepLinkUri rejects untrusted schemes and hosts', () {
      expect(SecurityService.isValidDeepLinkUri(Uri.parse('javascript:alert(1)')), isFalse);
      expect(SecurityService.isValidDeepLinkUri(Uri.parse('http://insecure-site.com/case')), isFalse);
      expect(SecurityService.isValidDeepLinkUri(Uri.parse('retino://malicious-host?d=123')), isFalse);
    });

    test('clampSphere clamps extreme and non-finite powers to biological limits', () {
      expect(SecurityService.clampSphere(5.25), equals(5.25));
      expect(SecurityService.clampSphere(-35.0), equals(-25.0));
      expect(SecurityService.clampSphere(999.0), equals(25.0));
      expect(SecurityService.clampSphere(double.nan), equals(0.0));
      expect(SecurityService.clampSphere(double.infinity), equals(0.0));
    });

    test('clampCylinder clamps powers to [-15.00 D, +15.00 D]', () {
      expect(SecurityService.clampCylinder(-2.50), equals(-2.50));
      expect(SecurityService.clampCylinder(-50.0), equals(-15.0));
      expect(SecurityService.clampCylinder(50.0), equals(15.0));
      expect(SecurityService.clampCylinder(null), equals(0.0));
    });

    test('clampAxis normalizes and clamps angle to [0°, 180°]', () {
      expect(SecurityService.clampAxis(45.0), equals(45.0));
      expect(SecurityService.clampAxis(180.0), equals(180.0));
      expect(SecurityService.clampAxis(0.0), equals(180.0));
      expect(SecurityService.clampAxis(270.0), equals(90.0));
      expect(SecurityService.clampAxis(-30.0), equals(150.0));
    });

    test('fromQrPayload successfully decodes valid case payload', () {
      final profile = PatientProfile(
        name: 'Dr. Test Subject',
        age: 30,
        sphere: -2.75,
        cylinder: -1.25,
        axis: 175.0,
        notes: 'Clinical trial patient',
      );
      final payload = profile.toQrPayload();

      final decoded = PatientProfile.fromQrPayload(payload);
      expect(decoded, isNotNull);
      expect(decoded!.name, equals('Dr. Test Subject'));
      expect(decoded.age, equals(30));
      expect(decoded.sphere, equals(-2.75));
      expect(decoded.cylinder, equals(-1.25));
      expect(decoded.axis, equals(175.0));
      expect(decoded.notes, equals('Clinical trial patient'));
    });

    test('fromQrPayload rejects malformed, corrupted, or oversized deep links', () {
      expect(PatientProfile.fromQrPayload(''), isNull);
      expect(PatientProfile.fromQrPayload('retino://case?d=not-valid-base64!!!'), isNull);
      expect(PatientProfile.fromQrPayload('https://randomwebsite.com/hack?d=abc'), isNull);
      expect(PatientProfile.fromQrPayload('retino://case?d='), isNull);

      // Oversized payload DoS check
      final hugePayload = 'retino://case?d=${'A' * 5000}';
      expect(PatientProfile.fromQrPayload(hugePayload), isNull);
    });

    test('fromQrPayload sanitizes injected script tags and clamps out-of-bounds values', () {
      final injectionData = {
        'v': 1,
        'n': '<script>stealTokens()</script>Evil Subject',
        'a': 999, // Out of bounds age
        's': -999.0, // Out of bounds sphere
        'c': 888.0, // Out of bounds cyl
        'x': 540.0, // Out of bounds axis
        't': '<b onmouseover=evil()>Malicious Case Notes</b>',
      };
      final encoded = base64Url.encode(utf8.encode(jsonEncode(injectionData)));
      final payload = 'retino://case?d=$encoded';

      final decoded = PatientProfile.fromQrPayload(payload);
      expect(decoded, isNotNull);
      expect(decoded!.name, isNot(contains('<script>')));
      expect(decoded.name, contains('Evil Subject'));
      expect(decoded.age, equals(125)); // clamped
      expect(decoded.sphere, equals(-25.0)); // clamped
      expect(decoded.cylinder, equals(15.0)); // clamped
      expect(decoded.axis, equals(180.0)); // normalized 540 % 180 = 0 -> 180
      expect(decoded.notes, isNot(contains('<b')));
      expect(decoded.notes, equals('Malicious Case Notes'));
    });
  });
}
