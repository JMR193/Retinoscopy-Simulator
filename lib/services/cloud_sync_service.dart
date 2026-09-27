import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudSyncService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get currentUserId => _auth.currentUser?.uid;
  static User? get currentUser => _auth.currentUser;
  static bool get isAuthenticated => _auth.currentUser != null && !_auth.currentUser!.isAnonymous;
  static String? get userEmail => _auth.currentUser?.email;

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  static Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
    }
  }

  static String sanitizeUserName(String name) {
    // Strip control chars, HTML/tags, trim and cap at 30 chars
    final cleaned = name.replaceAll(RegExp(r'[<>/\\{}|[\]\n\r\t]'), '').trim();
    if (cleaned.isEmpty) {
      return 'Optometrist';
    }
    return cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
  }

  static Future<void> syncLocalDataToCloud(int xp, int streak, String userName, {int gems = 0}) async {
    try {
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }
      final user = _auth.currentUser;
      if (user != null) {
        // Sanitize and clamp values to reasonable clinical bounds
        final safeXp = xp.clamp(0, 1000000);
        final safeGems = gems.clamp(0, 100000);
        final safeStreak = streak.clamp(0, 3650);
        final safeName = sanitizeUserName(userName);

        await _firestore.collection('users').doc(user.uid).set({
          'xp': safeXp,
          'gems': safeGems,
          'studyStreak': safeStreak,
          'userName': safeName,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore Sync Error: $e');
    }
  }

  static Stream<QuerySnapshot> getGlobalLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(100)
        .snapshots();
  }
}
