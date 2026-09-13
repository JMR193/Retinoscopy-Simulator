import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retinoscopy_simulator/screens/about_screen.dart';
import 'package:retinoscopy_simulator/screens/store_screen.dart';
import 'package:retinoscopy_simulator/services/storage_service.dart';
import 'package:retinoscopy_simulator/widgets/power_cross_view.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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
    await tester.scrollUntilVisible(cobaltFinder, 100);
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
}

