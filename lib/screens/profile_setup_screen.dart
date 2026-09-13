import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../main.dart'; // For AppShell

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _enableReminders = true;

  void _finishSetup() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      name = 'Anonymous Optometrist';
    }
    
    await StorageService.setUserName(name);
    await StorageService.setDailyReminderEnabled(_enableReminders);
    
    // Do an initial sync of their name to the cloud
    CloudSyncService.syncLocalDataToCloud(
      StorageService.getXp(), 
      StorageService.getGems(), 
      StorageService.getStudyStreak(), 
      name
    );

    await StorageService.markFirstLaunchDone();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Profile Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_pin, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Enter your name to appear on the Global Leaderboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name or Clinic Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: SwitchListTile(
                title: const Text('Daily Practice Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive a daily clinical case to keep your skills sharp and maintain your streak!'),
                value: _enableReminders,
                onChanged: (val) {
                  setState(() {
                    _enableReminders = val;
                  });
                },
                activeThumbColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _finishSetup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Practicing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
