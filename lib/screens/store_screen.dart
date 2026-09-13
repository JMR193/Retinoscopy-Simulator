import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class RetinoscopeOpticsItem {
  final String id;
  final String name;
  final String subtitle;
  final String clinicalIndication;
  final Color color;
  final String colorTemp;
  final IconData icon;

  const RetinoscopeOpticsItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.clinicalIndication,
    required this.color,
    required this.colorTemp,
    required this.icon,
  });
}

/// Clinical Retinoscope Illumination & Filter Optics Calibration Screen
typedef OpticsCalibrationScreen = StoreScreen;

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const List<RetinoscopeOpticsItem> _opticsList = [
    RetinoscopeOpticsItem(
      id: 'Default Orange',
      name: 'Halogen HPX 3.5V (Standard)',
      subtitle: 'Welch Allyn / Heine Standard Incandescent',
      clinicalIndication: 'Authentic 3200K warm tungsten-halogen. Gold-standard baseline for fundus reflex visibility and neutrality recognition.',
      color: Colors.deepOrangeAccent,
      colorTemp: '3,200 K Warm',
      icon: Icons.lightbulb,
    ),
    RetinoscopeOpticsItem(
      id: 'Cyan Glow',
      name: 'Daylight Clinical LED (5500K)',
      subtitle: 'Modern High-CRI Ophthalmic LED',
      clinicalIndication: 'Neutral daylight spectrum with razor-sharp streak edges. Superior contrast for detecting subtle scissors movement.',
      color: Colors.cyanAccent,
      colorTemp: '5,500 K Cool',
      icon: Icons.wb_sunny_outlined,
    ),
    RetinoscopeOpticsItem(
      id: 'Neon Green',
      name: 'Red-Free / Green Optical Filter',
      subtitle: 'Vascular & Retinal Contrast Filter',
      clinicalIndication: 'Absorbs red fundus reflectance to sharpen reflex boundaries and maximize pupil margin visibility in small pupils.',
      color: Colors.greenAccent,
      colorTemp: '530 nm Bandpass',
      icon: Icons.remove_red_eye_outlined,
    ),
    RetinoscopeOpticsItem(
      id: 'Amethyst Purple',
      name: 'Cobalt Contrast Filter',
      subtitle: 'Short-Wavelength Media Filter',
      clinicalIndication: 'Enhances corneal surface alignment and aids in delineating reflex motion across nuclear cataractous haze.',
      color: Colors.purpleAccent,
      colorTemp: '450 nm Cobalt',
      icon: Icons.lens_blur_outlined,
    ),
    RetinoscopeOpticsItem(
      id: 'Laser Red',
      name: 'Polarizing Anti-Glare Filter',
      subtitle: 'Specular Reflection Attenuator',
      clinicalIndication: 'Dampens corneal reflex glare (Purkinje images) when evaluating high astigmatic meridians or aphakic patients.',
      color: Colors.redAccent,
      colorTemp: 'Linear Polarized',
      icon: Icons.filter_tilt_shift,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final equipped = StorageService.getEquippedCosmetic();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Retinoscope Illumination & Optics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ophthalmic Optical Calibration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select authentic clinical bulb technologies and optical filters used in diagnostic streak retinoscopes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._opticsList.map((item) {
            final bool isEquipped = equipped == item.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isEquipped ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isEquipped ? item.color : Colors.transparent,
                  width: isEquipped ? 2 : 0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: item.color, width: 2),
                          ),
                          child: Icon(item.icon, color: item.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: item.color.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            item.colorTemp,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.clinicalIndication,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isEquipped)
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: item.color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Active Calibration',
                                style: TextStyle(
                                  color: item.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Equip Calibration'),
                            onPressed: () async {
                              await StorageService.unlockCosmetic(item.id);
                              await StorageService.equipCosmetic(item.id);
                              setState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Calibrated to ${item.name}'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
