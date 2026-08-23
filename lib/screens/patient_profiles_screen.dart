import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_profile.dart';
import '../state/retinoscopy_state.dart';
import '../widgets/qr_code_dialog.dart';

class PatientProfilesScreen extends StatefulWidget {
  const PatientProfilesScreen({super.key});

  @override
  State<PatientProfilesScreen> createState() => _PatientProfilesScreenState();
}

class _PatientProfilesScreenState extends State<PatientProfilesScreen> {
  List<PatientProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });
    final List<PatientProfile> loaded = await PatientProfileService.loadAll();
    setState(() {
      _profiles = loaded;
      _isLoading = false;
    });
  }

  void _showImportDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.blue),
              SizedBox(width: 8),
              Text('Import Case Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste a shared retino:// case link or payload below:'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'retino://case?d=...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final input = textController.text.trim();
                final profile = PatientProfile.fromQrPayload(input);
                if (profile != null) {
                  await PatientProfileService.save(profile);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (mounted) {
                    _loadProfiles();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully imported "${profile.name}" (${profile.formattedRx})')),
                    );
                  }
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Invalid case format or QR link.')),
                    );
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfile(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this profile?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await PatientProfileService.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile deleted')),
        );
      }
      await _loadProfiles();
    }
  }

  void _showAddEditDialog([PatientProfile? profile]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AddEditProfileForm(
            profile: profile,
            onSave: (PatientProfile p) async {
              await PatientProfileService.save(p);
              if (context.mounted) {
                Navigator.of(context).pop();
                _loadProfiles();
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profiles'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            tooltip: 'Import Case (QR / Link)',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _showImportDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('No patient profiles yet. Tap + to add one.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _profiles.length,
      itemBuilder: (BuildContext context, int index) {
        final PatientProfile profile = _profiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () {
              context.read<RetinoscopyState>().loadPatientRx(
                    sphere: profile.sphere,
                    cylinder: profile.cylinder,
                    axis: profile.axis,
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loaded "${profile.name}" (${profile.formattedRx}) into simulator!'),
                  backgroundColor: Colors.green[700],
                ),
              );
            },
            title: Text('${profile.name}, Age ${profile.age}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(profile.formattedRx, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
                const SizedBox(height: 4),
                Text('Created: ${profile.createdAt.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                if (profile.notes.isNotEmpty)
                  Text(
                    profile.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: 'Share QR Code',
                  icon: const Icon(Icons.qr_code_2, color: Colors.blue),
                  onPressed: () {
                    QrCodeDialog.show(context, profile);
                  },
                ),
                IconButton(
                  tooltip: 'Practice on this Patient',
                  icon: const Icon(Icons.play_circle_fill, color: Colors.green),
                  onPressed: () {
                    context.read<RetinoscopyState>().loadPatientRx(
                          sphere: profile.sphere,
                          cylinder: profile.cylinder,
                          axis: profile.axis,
                        );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Loaded "${profile.name}" into simulator!'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Edit Profile',
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showAddEditDialog(profile);
                  },
                ),
                IconButton(
                  tooltip: 'Delete Profile',
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteProfile(profile.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddEditProfileForm extends StatefulWidget {
  final PatientProfile? profile;
  final void Function(PatientProfile) onSave;

  const _AddEditProfileForm({
    this.profile,
    required this.onSave,
  });

  @override
  State<_AddEditProfileForm> createState() => _AddEditProfileFormState();
}

class _AddEditProfileFormState extends State<_AddEditProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _notesController;
  
  late double _sphere;
  late double _cylinder;
  late double _axis;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _ageController = TextEditingController(text: widget.profile?.age.toString() ?? '');
    _notesController = TextEditingController(text: widget.profile?.notes ?? '');
    
    _sphere = widget.profile?.sphere ?? 0.0;
    _cylinder = widget.profile?.cylinder ?? 0.0;
    _axis = widget.profile?.axis ?? 90.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final PatientProfile newProfile = PatientProfile(
        id: widget.profile?.id,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        notes: _notesController.text.trim(),
        sphere: _sphere,
        cylinder: _cylinder,
        axis: _axis,
        createdAt: widget.profile?.createdAt,
      );
      widget.onSave(newProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.profile == null ? 'Add Profile' : 'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age cannot be empty';
                  }
                  final int? age = int.tryParse(value.trim());
                  if (age == null || age <= 0) {
                    return 'Age must be > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Text('Sphere'),
                        Slider(
                          value: _sphere,
                          min: -20.0,
                          max: 20.0,
                          divisions: 160,
                          label: _sphere.toStringAsFixed(2),
                          onChanged: (double value) {
                            setState(() {
                              _sphere = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Text('Cylinder'),
                        Slider(
                          value: _cylinder,
                          min: -6.0,
                          max: 6.0,
                          divisions: 48,
                          label: _cylinder.toStringAsFixed(2),
                          onChanged: (double value) {
                            setState(() {
                              _cylinder = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Text('Axis'),
                        Slider(
                          value: _axis,
                          min: 5.0,
                          max: 180.0,
                          divisions: 35,
                          label: _axis.toStringAsFixed(0),
                          onChanged: (double value) {
                            setState(() {
                              _axis = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
