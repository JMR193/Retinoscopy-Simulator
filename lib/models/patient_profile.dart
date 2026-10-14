import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/security_service.dart';

class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String notes;
  final double sphere;
  final double cylinder;
  final double axis;
  final DateTime createdAt;

  PatientProfile({
    String? id,
    required String name,
    required int age,
    required String notes,
    required double sphere,
    required double cylinder,
    required double axis,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name = SecurityService.sanitizeName(name),
        age = SecurityService.clampAge(age),
        notes = SecurityService.sanitizeNotes(notes),
        sphere = SecurityService.clampSphere(sphere),
        cylinder = SecurityService.clampCylinder(cylinder),
        axis = SecurityService.clampAxis(axis),
        createdAt = createdAt ?? DateTime.now();

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String?,
      name: SecurityService.sanitizeName(json['name'] as String? ?? 'Patient'),
      age: SecurityService.clampAge(json['age'] as num?),
      notes: SecurityService.sanitizeNotes(json['notes'] as String? ?? ''),
      sphere: SecurityService.clampSphere(json['sphere'] as num?),
      cylinder: SecurityService.clampCylinder(json['cylinder'] as num?),
      axis: SecurityService.clampAxis(json['axis'] as num?),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'notes': notes,
      'sphere': sphere,
      'cylinder': cylinder,
      'axis': axis,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedRx {
    final String sphStr = sphere > 0 ? '+${sphere.toStringAsFixed(2)}' : sphere.toStringAsFixed(2);
    final String cylStr = cylinder > 0 ? '+${cylinder.toStringAsFixed(2)}' : cylinder.toStringAsFixed(2);
    final String axisStr = axis.toStringAsFixed(0);
    return '$sphStr DS $cylStr DC × $axisStr°';
  }

  /// Generates a compact shareable case payload string for QR / text sharing
  String toQrPayload() {
    final Map<String, dynamic> data = {
      'v': 1,
      'n': SecurityService.sanitizeName(name),
      'a': SecurityService.clampAge(age),
      's': SecurityService.clampSphere(sphere),
      'c': SecurityService.clampCylinder(cylinder),
      'x': SecurityService.clampAxis(axis),
      't': SecurityService.sanitizeNotes(notes),
    };
    return 'retino://case?d=${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  /// Parses a compact shareable case payload string with strict security validation
  static PatientProfile? fromQrPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty || trimmed.length > 5000) {
      return null;
    }

    try {
      final uri = Uri.parse(trimmed);
      if (!SecurityService.isValidDeepLinkUri(uri)) {
        return null;
      }

      final d = uri.queryParameters['d'];
      if (d == null || d.isEmpty || d.length > 4096) {
        return null;
      }

      final jsonStr = utf8.decode(base64Url.decode(d));
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final map = decoded;
      return PatientProfile(
        name: SecurityService.sanitizeName((map['n'] as String?) ?? 'Imported Case'),
        age: SecurityService.clampAge(map['a'] as num?),
        sphere: SecurityService.clampSphere(map['s'] as num?),
        cylinder: SecurityService.clampCylinder(map['c'] as num?),
        axis: SecurityService.clampAxis(map['x'] as num?),
        notes: SecurityService.sanitizeNotes((map['t'] as String?) ?? ''),
      );
    } catch (_) {
      // Catch corrupted base64, malformed JSON, format errors securely
      return null;
    }
  }

  /// Curated collection of 10 board-standard clinical cases for students & educators
  static List<PatientProfile> getCuratedMasterLibrary() {
    return [
      PatientProfile(
        id: 'curated_1',
        name: 'Case 1: Baseline Emmetropia',
        age: 22,
        sphere: 0.0,
        cylinder: 0.0,
        axis: 90.0,
        notes: 'Normal healthy student. Neutral reflex observed with working distance trial lens (+1.50 D for 67 cm) in place.',
      ),
      PatientProfile(
        id: 'curated_2',
        name: 'Case 2: Moderate Myopia',
        age: 19,
        sphere: -2.50,
        cylinder: 0.0,
        axis: 90.0,
        notes: 'Complains of distance blur in lecture halls. Shows Against motion in all meridians without trial lenses.',
      ),
      PatientProfile(
        id: 'curated_3',
        name: 'Case 3: Latent Hyperopia',
        age: 14,
        sphere: 3.50,
        cylinder: 0.0,
        axis: 90.0,
        notes: 'Asthenopia and frontal headaches after prolonged reading. Shows slow, wide With motion requiring high plus power.',
      ),
      PatientProfile(
        id: 'curated_4',
        name: 'Case 4: With-The-Rule (WTR) Astigmatism',
        age: 28,
        sphere: 1.00,
        cylinder: -2.00,
        axis: 180.0,
        notes: 'Classic vertical meridian steeper than horizontal. Neutralize horizontal meridian first, then add minus cylinder at 180°.',
      ),
      PatientProfile(
        id: 'curated_5',
        name: 'Case 5: Against-The-Rule (ATR) Astigmatism',
        age: 68,
        sphere: -0.50,
        cylinder: -2.25,
        axis: 90.0,
        notes: 'Elderly patient with horizontal corneal steepening. Notice break phenomenon when sweeping off 90°/180°.',
      ),
      PatientProfile(
        id: 'curated_6',
        name: 'Case 6: Oblique Astigmatism',
        age: 34,
        sphere: 2.00,
        cylinder: -3.00,
        axis: 45.0,
        notes: 'Principal meridians oriented at 45° and 135°. Observe pronounced oblique skew and scissor shear.',
      ),
      PatientProfile(
        id: 'curated_7',
        name: 'Case 7: Keratoconus / Irregular Reflex',
        age: 23,
        sphere: -4.00,
        cylinder: -4.50,
        axis: 65.0,
        notes: 'Advanced corneal ectasia. Observe central pinching scissors motion and asymmetric reflex brilliance.',
      ),
      PatientProfile(
        id: 'curated_8',
        name: 'Case 8: Pediatric Amblyopia Risk',
        age: 4,
        sphere: 5.50,
        cylinder: -1.50,
        axis: 90.0,
        notes: 'High anisometropic hyperopia risk. Recommended to practice Mohindra near dark-room retinoscopy technique.',
      ),
      PatientProfile(
        id: 'curated_9',
        name: 'Case 9: Pseudophakic Monofocal IOL',
        age: 72,
        sphere: 0.50,
        cylinder: -1.25,
        axis: 105.0,
        notes: 'Post-cataract surgery with sharp, bright reflex and small residual astigmatic cylinder.',
      ),
      PatientProfile(
        id: 'curated_10',
        name: 'Case 10: High Degenerative Myopia',
        age: 45,
        sphere: -9.50,
        cylinder: -2.00,
        axis: 15.0,
        notes: 'Severe axial elongation with posterior staphyloma. Reflex is extremely fast and dim; add strong minus spheres first.',
      ),
    ];
  }
}

class PatientProfileService {
  static const String _prefsKey = 'patient_profiles_v1';

  static Future<List<PatientProfile>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_prefsKey);
    if (jsonList == null) {
      return [];
    }
    return jsonList.map((String jsonStr) => PatientProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>)).toList();
  }

  static Future<void> save(PatientProfile p) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<PatientProfile> profiles = await loadAll();
    final int index = profiles.indexWhere((PatientProfile profile) => profile.id == p.id);
    if (index >= 0) {
      profiles[index] = p;
    } else {
      profiles.add(p);
    }
    final List<String> jsonList = profiles.map((PatientProfile profile) => jsonEncode(profile.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  static Future<void> delete(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<PatientProfile> profiles = await loadAll();
    profiles.removeWhere((PatientProfile profile) => profile.id == id);
    final List<String> jsonList = profiles.map((PatientProfile profile) => jsonEncode(profile.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }
}
