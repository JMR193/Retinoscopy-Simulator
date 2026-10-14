import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:retinoscopy_simulator/screens/about_screen.dart';
import 'package:retinoscopy_simulator/screens/store_screen.dart';
import 'package:retinoscopy_simulator/services/storage_service.dart';
import 'package:retinoscopy_simulator/widgets/power_cross_view.dart';
import 'package:retinoscopy_simulator/widgets/sturms_conoid_view.dart';
import 'package:retinoscopy_simulator/widgets/reflex_motion_gauge.dart';
import 'package:retinoscopy_simulator/widgets/spherocylinder_transposition_card.dart';
import 'package:retinoscopy_simulator/state/retinoscopy_state.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'Retinoscopy Simulator',
      packageName: 'com.jmr.retinoscopy',
      version: '2.5.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await StorageService.init();
  });

  testWidgets('1. AboutScreen renders clinical version and medical standards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About Retinoscopy Simulator'), findsOneWidget);
    expect(find.textContaining('Elite Clinical Edition'), findsWidgets);
  });

  testWidgets('2. OpticsCalibrationScreen renders authentic filters', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OpticsCalibrationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retinoscope Illumination & Optics'), findsOneWidget);
    expect(find.text('Halogen HPX 3.5V (Standard)'), findsOneWidget);
    expect(find.text('Daylight Clinical LED (5500K)'), findsOneWidget);

    final cobaltFinder = find.text('Cobalt Contrast Filter');
    await tester.scrollUntilVisible(cobaltFinder, 300);
    expect(cobaltFinder, findsOneWidget);
  });

  testWidgets('3. PowerCrossView renders dual meridians properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PowerCrossView(
              sphere: 1.50,
              cylinder: -2.00,
              axis: 90,
              workingDistance: 1.50,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PowerCrossView), findsOneWidget);
    expect(find.text('2-Meridian Optical Power Cross'), findsOneWidget);
    expect(find.text('Meridian 1'), findsOneWidget);
    expect(find.text('Meridian 2'), findsOneWidget);
    expect(find.text('Net: +1.50 D @ 90°'), findsOneWidget);
    expect(find.text('Net: -0.50 D @ 180°'), findsOneWidget);
  });

  testWidgets('4. SturmsConoidView renders 3D ray conoid and astigmatic classification', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SturmsConoidView(
              sphere: 1.00,
              cylinder: -2.50,
              axis: 90.0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SturmsConoidView), findsOneWidget);
    expect(find.text('Sturm’s Conoid 3D Ray Conoid'), findsOneWidget);
    expect(find.textContaining('Mixed Astigmatism'), findsOneWidget);
    expect(find.textContaining('COLC'), findsWidgets);
    expect(find.textContaining('Interval of Sturm'), findsOneWidget);
  });

  testWidgets('5. ReflexMotionGauge renders real-time motion and velocity telemetry', (WidgetTester tester) async {
    final state = RetinoscopyState();
    state.patientSphere = 2.00;
    state.patientCylinder = 0.0;
    state.workingDistance = 1.50;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReflexMotionGauge(state: state),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ReflexMotionGauge), findsOneWidget);
    expect(find.textContaining('WITH MOTION'), findsWidgets);
    expect(find.text('Reflex Speed'), findsOneWidget);
    expect(find.text('Brilliance / Lux'), findsOneWidget);
    expect(find.text('Pupil Fill / Width'), findsOneWidget);
  });

  testWidgets('6. SpherocylinderTranspositionCard renders reciprocal forms and mathematical proof', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpherocylinderTranspositionCard(
              initialSphere: 1.00,
              initialCylinder: -2.00,
              initialAxis: 90.0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SpherocylinderTranspositionCard), findsOneWidget);
    expect(find.text('Spherocylinder Transposition Lab'), findsOneWidget);
    expect(find.textContaining('+1.00 DS / -2.00 DC × 90°'), findsOneWidget);
    expect(find.textContaining('-1.00 DS / +2.00 DC × 180°'), findsOneWidget);
    expect(find.textContaining('Mathematical Transposition Protocol'), findsOneWidget);
    expect(find.text('Meridian @ 90°'), findsOneWidget);
    expect(find.text('Meridian @ 180°'), findsOneWidget);
  });
}

