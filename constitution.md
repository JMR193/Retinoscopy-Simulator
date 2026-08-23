# Project Constitution — Retinoscopy Simulator

**Project Name**: Retinoscopy Simulator  
**Organization**: JMR Technologies  
**Target Package**: `com.jmrtech.retinoscopy_simulator`  
**Platform**: Android & iOS (Flutter 3.x Engine)  
**Governance Framework**: GitHub Spec-Kit (Spec-Driven Development / SDD)  
**Status**: ACTIVE & NON-NEGOTIABLE  

---

## 🏛️ 1. Foundational Invariants & Core Principles

All code modifications, feature designs, architectural decisions, and agent-generated implementations MUST strictly adhere to the following non-negotiable principles:

### Article I: Clinical Optics & Mathematical Fidelity
1. **Ray Vergence Accuracy**: All streak reflex calculations (with-motion, against-motion, neutral) must be derived from the fundamental vergence equation:
   $$\text{Reflex Vergence} = \text{Patient Refractive Error} - \text{Examiner Working Distance Offset}$$
2. **Dual-Form Transposition Verification**: Scoring in test and exam modes must evaluate both plus-cylinder and minus-cylinder transposed Rx forms simultaneously:
   $$(S, C, \theta) \equiv (S + C, -C, (\theta + 90^\circ) \bmod 180^\circ)$$
3. **Scissors Reflex Kinetics**: Spherical aberration and irregular astigmatism must simulate parabolic split-beam motion across opposing meridians.
4. **Physiological Hippus**: Pupil oscillations must maintain subtle harmonic sine-wave variation ($\pm 3\%$) to reflect human biological dynamics.

---

### Article II: Runtime Stability & Zero-Crash Architecture
1. **Root-Zone Initialization**: `WidgetsFlutterBinding.ensureInitialized()` MUST ALWAYS be the first statement executed in `main()` in the root zone before any asynchronous calls.
2. **Crash-Resilient Persistence**: `StorageService` must never throw unhandled `NullCheck` or `PlatformException` errors. In-memory fail-safe fallbacks must operate seamlessly if platform channels are delayed during cold boot.
3. **Android R8 / ProGuard Safety**: Native Java/Kotlin plugin reflection bridges (`SharedPreferences`, `PathProvider`, `SharePlus`, `Printing`) must be preserved against bytecode stripping in release builds.
4. **Error Shielding**: All background tasks and async events must be bounded within `runZonedGuarded` with global `FlutterError.onError` interceptors.

---

### Article III: UI/UX & Rendering Performance
1. **60 FPS Canvas Rendering**: All `CustomPainter` instances (`EyePainter`, `QrPainter`, `SnellenPainter`) must optimize `shouldRepaint` delegates to prevent unnecessary redraw passes.
2. **Adaptive Layout Support**: Fluidly adapt between mobile portrait and 3-panel widescreen landscape for iPad and Android tablets.
3. **Material 3 Dynamic Theming**: Support high-contrast dark theme and 5 curated color palettes (Blue, Green, Cyan, Orange, Purple) without hardcoded text or container colors.

---

### Article IV: Security, Privacy & Google Play Store Compliance
1. **API Level Standard**: Must target the latest Google Play requirement: `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24`.
2. **Network Security**: Strict `cleartextTrafficPermitted="false"` enforced in `network_security_config.xml`. No cleartext HTTP traffic allowed.
3. **Offline-First Privacy & GDPR**: The application must remain 100% functional without internet connectivity. All clinical AI heuristics run locally on-device. Users must have a one-tap option to permanently wipe all stored history and preferences.

---

### Article V: Dart & Flutter Engineering Standards
1. **Zero Analyzer Warnings**: Every commit must pass `flutter analyze lib/` with `0 errors, 0 warnings, 0 lints`.
2. **Modern Flutter Styling**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
3. **Single Quotes & Code Cleanliness**: Single quotes for all string literals unless string interpolation necessitates double quotes; curly braces on all control flow statements.

---

## 🔄 2. Spec-Driven Development (SDD) Lifecycle

```
┌────────────────────────────────────────────────────────┐
│                   SDD LIFECYCLE                        │
├───────────────────┬───────────────────┬────────────────┤
│ 1. Specify        │ 2. Plan & Tasks   │ 3. Implement   │
│ • User Stories    │ • Architecture    │ • Code writing │
│ • Edge Cases      │ • Task Graph      │ • Verification │
│ • Acceptance Crit │ • Dependency Order│ • Static Check │
└───────────────────┴───────────────────┴────────────────┘
```

When implementing new features or major upgrades:
1. Create a formal feature specification in `.specify/specs/<feature_name>/spec.md`.
2. Create an architectural plan and task checklist in `plan.md` and `tasks.md`.
3. Execute tasks atomically according to the task graph.
4. Run `flutter analyze` and release verification before marking tasks complete.
