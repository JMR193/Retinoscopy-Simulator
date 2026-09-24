import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'state/retinoscopy_state.dart';
import 'screens/retinoscopy_simulator_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/patient_profiles_screen.dart';
import 'screens/handbook_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloud_sync_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized in root zone
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage, notifications, and audio safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await CloudSyncService.signInAnonymously();
    await StorageService.init();
    await AudioService.init();
    await NotificationService.init();
    await StorageService.recordStudySession();
  } catch (e) {
    debugPrint('Firebase / StorageService init failed: $e');
  }

  runZonedGuarded(() async {

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
          ..isDarkMode = StorageService.isDarkMode()
          ..accelerometerTiltEnabled = StorageService.isAccelerometerTiltEnabled()
          ..sphereStep = StorageService.getSphereStep()
          ..cylinderStep = StorageService.getCylinderStep()
          ..axisStep = StorageService.getAxisStep()
          ..showLiveNeutralityFeedback = StorageService.getShowLiveNeutralityFeedback(),
        child: const RetinoscopyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught asynchronous error: $error\n$stack');
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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
            scaffoldBackgroundColor: const Color(0xFFF2F2F7), // Apple iOS Grouped Background
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ).copyWith(
              surface: Colors.white,
              surfaceContainerLowest: Colors.white,
              surfaceContainerLow: const Color(0xFFF2F2F7),
              surfaceContainer: const Color(0xFFE5E5EA),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
              scrolledUnderElevation: 0.5,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(22)), // Samsung One UI Smooth Squircle
                side: BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 1.0),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF000000), // Samsung Super AMOLED Pure Black
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ).copyWith(
              surface: const Color(0xFF161618), // Apple Elevated Dark Gray
              surfaceContainerLowest: const Color(0xFF000000),
              surfaceContainerLow: const Color(0xFF121214),
              surfaceContainer: const Color(0xFF1C1C1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xDD000000),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              scrolledUnderElevation: 0.5,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF161618),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(22)), // Samsung One UI Smooth Squircle
                side: BorderSide(color: Colors.white.withValues(alpha: 0.09), width: 1.0),
              ),
            ),
          ),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StorageService.isFirstLaunch()
              ? const OnboardingScreen()
              : const AuthWrapper(),
        );
      },
    );
  }

  static Color _seedColor(String name) {
    switch (name) {
      case 'Green':  return const Color(0xFF34C759); // Apple System Green
      case 'Cyan':   return const Color(0xFF32ADE6); // Apple System Cyan
      case 'Orange': return const Color(0xFFFF9500); // Apple System Orange
      case 'Purple': return const Color(0xFFAF52DE); // Apple System Purple
      default:       return const Color(0xFF007AFF); // Apple / Samsung System Blue
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading spinner if we are waiting for the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData || StorageService.isGuestMode()) {
          // User is signed in or has chosen offline clinical guest mode
          return const AppShell();
        } else {
          // User is not signed in and has not selected guest mode
          return const LoginScreen();
        }
      },
    );
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
    final retinoscopyState = context.watch<RetinoscopyState>();
    if (retinoscopyState.requestedAppTab != null) {
      final targetTab = retinoscopyState.requestedAppTab!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != targetTab) {
          setState(() => _selectedIndex = targetTab);
        }
        retinoscopyState.clearRequestedAppTab();
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: isLandscape
          ? null // Auto-hide bottom navigation bar in landscape to fit everything on a single screen
          : ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xCC121214) : const Color(0xCCF8F8F9),
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIndex = i);
                    },
                    backgroundColor: Colors.transparent,
                    indicatorColor: isDarkMode ? colorScheme.primary.withValues(alpha: 0.25) : colorScheme.primary.withValues(alpha: 0.15),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    elevation: 0,
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
                ),
              ),
            ),
    );
  }
}
