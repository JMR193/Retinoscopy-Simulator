import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.name,
    required this.age,
    required this.notes,
    required this.sphere,
    required this.cylinder,
    required this.axis,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      notes: json['notes'] as String,
      sphere: (json['sphere'] as num).toDouble(),
      cylinder: (json['cylinder'] as num).toDouble(),
      axis: (json['axis'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      'n': name,
      'a': age,
      's': sphere,
      'c': cylinder,
      'x': axis,
      't': notes,
    };
    return 'retino://case?d=${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  /// Parses a compact shareable case payload string
  static PatientProfile? fromQrPayload(String payload) {
    try {
      final uri = Uri.parse(payload.trim());
      final d = uri.queryParameters['d'];
      if (d == null || d.isEmpty) {
        return null;
      }
      final jsonStr = utf8.decode(base64Url.decode(d));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PatientProfile(
        name: (map['n'] as String?) ?? 'Imported Case',
        age: (map['a'] as num?)?.toInt() ?? 25,
        sphere: (map['s'] as num?)?.toDouble() ?? 0.0,
        cylinder: (map['c'] as num?)?.toDouble() ?? 0.0,
        axis: (map['x'] as num?)?.toDouble() ?? 90.0,
        notes: (map['t'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
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
