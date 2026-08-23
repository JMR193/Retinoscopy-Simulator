import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'state/retinoscopy_state.dart';
import 'screens/retinoscopy_simulator_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/patient_profiles_screen.dart';
import 'screens/handbook_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized in root zone
  WidgetsFlutterBinding.ensureInitialized();

  // Catch and handle all framework-level errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Caught Flutter Error: ${details.exceptionAsString()}');
  };

  runZonedGuarded(() async {
    // Initialize persistent storage and audio safely
    try {
      await StorageService.init();
      await AudioService.init();
    } catch (e) {
      debugPrint('StorageService / AudioService init failed: $e');
    }

    // Set allowed orientations safely
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      debugPrint('Orientation init failed: $e');
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => RetinoscopyState()
          ..workingDistance = StorageService.getPreferredWorkingDistance()
          ..selectedThemeColor = StorageService.getThemeColor()
          ..isDarkMode = StorageService.isDarkMode(),
        child: const RetinoscopyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught asynchronous error: $error\n$stack');
  });
}

class RetinoscopyApp extends StatelessWidget {
  const RetinoscopyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RetinoscopyState>(
      builder: (context, state, _) {
        final seed = _seedColor(state.selectedThemeColor);
        return MaterialApp(
          title: 'Retinoscopy Simulator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: seed,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StorageService.isFirstLaunch()
              ? const OnboardingScreen()
              : const AppShell(),
        );
      },
    );
  }

  static Color _seedColor(String name) {
    switch (name) {
      case 'Green':  return const Color(0xFF388E3C);
      case 'Cyan':   return const Color(0xFF0097A7);
      case 'Orange': return const Color(0xFFF4511E);
      case 'Purple': return const Color(0xFF5E35B1);
      default:       return const Color(0xFF1976D2);
    }
  }
}

/// App Shell — houses the modern Material 3 NavigationBar and five core modules.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    RetinoscopySimulatorScreen(),
    ExamScreen(),
    PatientProfilesScreen(),
    HandbookScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: isLandscape
          ? null // Auto-hide bottom navigation bar in landscape to fit everything on a single screen
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primaryContainer,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.remove_red_eye_outlined),
                  selectedIcon: Icon(Icons.remove_red_eye),
                  label: 'Simulator',
                ),
                NavigationDestination(
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz),
                  label: 'Exam',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Cases',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Handbook',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'History',
                ),
              ],
            ),
    );
  }
}
