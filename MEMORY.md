# Retinoscopy Simulator Architectural Memory (MEMORY.md)

## 1. Project Overview & Architecture
The **Retinoscopy Simulator** is a clinical-grade ophthalmic and optometric training platform built in Flutter/Dart. It accurately replicates the optical physics of streak retinoscopy, trial lenses, phoropter mechanisms, subjective refinement, and corneal topography.

### Key Directories & Files:
- **`lib/state/retinoscopy_state.dart`**: Central optical physics engine and state container (Euler's relation, Sturm's conoid, Copeland straddle, Thibos vector space, Javal's rule, and AAO 5-step clinical protocol).
- **`lib/widgets/power_cross_view.dart`**: Interactive 2-Meridian Optical Power Cross visualizer with cardinal protractor ticks, terminal power badges, and light/dark theme adaptation.
- **`lib/widgets/realistic_eye.dart`**: Procedural Canvas painter simulating corneal reflection, fundus reflex velocity, brightness, scissor motion, and media opacities (nuclear cataracts, corneal scars).
- **`lib/widgets/trial_lens_overlay.dart`**: Real-time 3D trial frame and lens overlay.
- **`lib/widgets/protocol_guided_banner.dart`**: Stepper UI for AAO Plus-Cyl and Optometry Minus-Cyl clinical workflows.
- **`lib/screens/optical_calculator_screen.dart`**: Optical calculation laboratory for Dual-Meridian M1/M2 solver, Gross Spherocylinder, Keratometry/Javal's Rule, and Zernike wavefront aberrations.
- **`lib/screens/retinoscopy_simulator_screen.dart`**: Flagship simulation screen integrating realistic eye physics, sweep gestures, auto-sweep oscillator, trial lens dialing, Optics Tools (Ray Tracing, Thibos Vectors, 2-Meridian Optical Cross), and clinical case generators.

---

## 2. Optical Physics & Calculations

### Euler's Relation for Reflex Power:
Power along a swept meridian $\theta_{sweep} = (\theta_{streak} + 90^\circ) \pmod{180^\circ}$:
$$P(\theta_{sweep}) = S + C \sin^2(\theta_{sweep} - \alpha)$$

### Dual Meridian to Spherocylindrical Transposition:
Given two orthogonal principal meridians $M_1$ at axis $\alpha_1$ and $M_2$ at axis $\alpha_2 = \alpha_1 \pm 90^\circ$:
1. Deduct working distance: $N_1 = M_1 - WD$, $N_2 = M_2 - WD$.
2. Identify $N_{low} = \min(N_1, N_2)$ at $\alpha_{low}$ and $N_{high} = \max(N_1, N_2)$ at $\alpha_{high}$.
3. **Plus-Cylinder Form (+Cyl)**:
   - Base Sphere $= N_{low}$ at axis $\alpha_{low}$
   - Cylinder $= N_{high} - N_{low} \ge 0$
   - Axis $= \alpha_{low}$ (the cylinder lens has zero power along $\alpha_{low}$ and adds power along $\alpha_{high}$)
4. **Minus-Cylinder Form (-Cyl)**:
   - Base Sphere $= N_{high}$ at axis $\alpha_{high}$
   - Cylinder $= N_{low} - N_{high} \le 0$
   - Axis $= \alpha_{high}$ (the cylinder lens has zero power along $\alpha_{high}$ and subtracts power along $\alpha_{low}$)
5. **Transposition Invariance**:
   $$(N_{low}) \text{ DS} / (N_{high} - N_{low}) \text{ DC} \times \alpha_{low} \iff (N_{high}) \text{ DS} / (N_{low} - N_{high}) \text{ DC} \times \alpha_{high}$$

---

## 3. AAO 5-Step Protocol Machine
1. **Working Distance Compensation**: Standard 67 cm ($+1.50\text{ D}$) or pediatric Mohindra 50 cm ($+2.00\text{ D}$).
2. **Principal Meridian Isolation**: 360° streak rotation to detect break phenomenon and thickness alignment.
3. **Primary Sphere Neutralization**: Align with least WITH-motion meridian; neutralize with sphere until flash point.
4. **Orthogonal Plus-Cylinder Neutralization**: Rotate streak 90° and add plus cylinder until orthogonal reflex flashes neutral.
5. **Copeland Straddle & Verification**: Sweep $\pm 45^\circ$ to verify equal brilliance/thickness, then record Net Rx.

---

## 4. Architectural Decisions & Quality Gates
- **Dart Analysis**: Must always pass with 0 errors and 0 warnings (`dart analyze lib test`).
- **Test Suite**: Comprehensive optical suite in `test/retinoscopy_clinical_test.dart` covers Emmetropia, Hyperopia, Myopia, WTR/ATR, Break phenomenon, Copeland straddle, Mohindra pediatric, Thibos vectors, JCC, and Dual Meridian solvers.

---

## 5. Dual Meridian Neutral Points & Reactive Navigation (Update 2026-09)
- **Neutral Points vs. Final Net Rx**:
  - Clinicians dial gross neutralizing lenses ($M_1, M_2$) along orthogonal meridians.
  - State provides `patientGrossM1`, `patientM1Axis`, `patientGrossM2`, `patientM2Axis`, `patientNetM1`, `patientNetM2`.
  - `checkMeridianNeutralPoints(...)` verifies gross powers with tolerance and supports inverted input order.
  - Test mode allows toggling between **Dual Meridian Mode** (M1/M2 gross power + axis) and **Direct Net Rx Mode** (Form 1 & 2), with one-tap conversion via `calculateRetinoscopyAnswer(...)`.
- **Global Reactive Navigation**:
  - `RetinoscopyState.requestAppTab(int)` / `clearRequestedAppTab()` allows decoupled tab switching from child views/drawers to `AppShell`.
  - `PatientProfilesScreen` guards `Navigator.pop()` with `canPop()` and requests Tab 0 (Simulator) on Practice click.
  - `HistoryScreen` uses `StorageService.getHistory()` dynamically on build and provides `RefreshIndicator`.

---

## 6. Global Theme Synchronization & Streamlined Material 3 Control Deck (Update 2026-09)
- **Global Dark/Light Mode Architecture**:
  - The Home Page AppBar toggle now calls `RetinoscopyState.toggleDarkMode()`, updating `_isDarkMode`, persisting to `StorageService.setDarkMode()`, and calling `notifyListeners()`.
  - Removed local `Theme(...)` wrapper from `RetinoscopySimulatorScreen`. `MaterialApp` in `lib/main.dart` is globally reactive via `themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light`.
  - Toggling theme on the Home Page immediately updates all screens, tabs, dialogs, and drawers across the entire app.
  - `HandbookScreen` AppBar and TabBar now use adaptive Material 3 surface styling instead of hardcoded saturated blocks.
- **Streamlined Material 3 Clinical Control Deck**:
  - Replaced 3 sprawling rows of 13 loose action chips with a unified 2-row Material 3 Control Deck:
    - **Meridian Quick Bar**: Segmented choice chips (`90° V`, `180° H`, `Flip`, and `Collar...` dropdown).
    - **Mirror Mode Toggle**: Compact `Plane` vs `Concave` filter chip with indicator icons.
    - **Auto-Sweep**: Sleek toggle with inline speed indicator (`1.0x`, `1.5x`, `2.0x`).
    - **Working Distance**: Compact Segmented Choices (`50cm`, `67cm`, `1m`) with diopter tooltips.
    - **Consolidated Tools Popover**: Unified `Tools` button integrating Copeland Straddle (±45°), Clinical Protocols (AAO), 2D Ray Tracing Diagram, Thibos Vector Plot, and 2-Meridian Optical Cross.
  - Reduces vertical control footprint by 60% while preserving 100% of clinical functionality.

---

## 7. Educational Experience & Answer Check Optimization (Update 2026-09)
- **Single-Form vs. Dual-Form Answer Evaluation**:
  - `RetinoscopyState.checkAnswer` and `ExamScreen._checkAnswer` now support `form2Entered: false`, validating Form 1 against either primary target or transposed target.
  - Students are never penalized or graded 0 if they write the correct prescription in Form 1 and omit Form 2.
  - For pure spherical cases, axis difference is optically invariant; matching sphere in either Form 1 or Form 2 is valid.
  - UI updated in `RetinoscopySimulatorScreen` and `ExamScreen` to clearly mark Form 1 as "Primary — Required" and Form 2 as "Transposed — Optional".
- **Arcade Code Elimination**:
  - Obsolete arcade "Gems" references removed from `CloudSyncService`, `StorageService`, `LeaderboardScreen`, and `ProfileSetupScreen`.
  - Schema backwards compatibility with Firestore is preserved via optional default `{int gems = 0}` without exposing arcade artifacts in the UI.

---

## 8. Clinical Optics Widgets Suite (Update 2026-09)
- **`lib/widgets/sturms_conoid_view.dart` (`SturmsConoidView`)**:
  - Interactive 3D perspective Canvas visualizer for Sturm's Conoid.
  - Renders anterior focal line ($F_1$), posterior focal line ($F_2$), Circle of Least Confusion ($COLC$), the Interval of Sturm, and the Retinal Plane.
  - Automatically classifies astigmatism (CMA, SMA, MA, SHA, CHA, Emmetropia) with dynamic color-coded badges and tilt-angle controls.
- **`lib/widgets/reflex_motion_gauge.dart` (`ReflexMotionGauge`)**:
  - Real-time clinical telemetry HUD showing:
    - Motion type with animated direction icons: WITH (+), AGAINST (−), NEUTRAL FLASH (★), SCISSORS (✂).
    - Velocity index metric ($V_{reflex} \propto \frac{1}{|P_{net}|}$, accelerating to flash).
    - Photometric Brilliance / Luminance index (%).
    - Pupil Fill / Width factor.
    - Astigmatic Break Phenomenon angular displacement readout.
- **`lib/widgets/spherocylinder_transposition_card.dart` (`SpherocylinderTranspositionCard`)**:
  - Interactive transposition laboratory providing step-by-step mathematical proofs ($S' = S + C$, $C' = -C$, $\alpha' = \alpha \pm 90^\circ$, $SE = S + C/2$).
  - One-tap clipboard copy and direct simulator / phoropter loading.
- Integrated into `RetinoscopySimulatorScreen` Tools menu and Center Panel.

---

## 9. Build Resolution (Release Kernel Snapshot Fix)
- **`lib/screens/exam_screen.dart`**:
  - Corrected named optional parameter syntax in `_checkAnswer`: changed `{bool form2Entered = true},` to `{bool form2Entered = true}` enclosed properly within the function parameter parentheses.
  - Resolves Dart compiler parsing error `Error: Expected ')' before this` during `flutter build apk --release`.

---

## 10. Research, PRD & Architecture Artifacts, and First-Time UX Hardening
- **Comprehensive Ophthalmic Research Report**:
  - Detailed survey of Copeland streak method, Corboy, Borish, Duke-Elder, AAO BCSC Clinical Optics.
  - Spherocylindrical matrix decomposition, Thibos Fourier power vector space ($M, J_0, J_{45}$), and continuous hyperbolic velocity scaling ($V \propto 1/|P_{net}|$).
  - Dynamic retinoscopy protocols (MEM, Nott, Mohindra Pediatric Near Technique, Bell).
  - Atypical reflexes: keratoconic scissors (Zernike $Z_4^0$), Charleux oil-droplet (lenticonus), dull central cataract extinction, astigmatic break and skew shear.
- **Created Production Artifacts**:
  - `PRD.md`: Formal Product Requirements Document detailing clinical personas, functional requirements (FR-OPT, FR-PRO, FR-HUD, FR-UX), competitive matrices, and non-functional requirements.
  - `ARCHITECTURE.md`: Complete system architecture specification covering the 4-layer clean pattern, mathematical formulations, rendering pipeline, state management, and test architecture.
- **First-Time UX & Screen Optimization**:
  - `InteractiveOnboardingOverlay`: Hardened persistence so completing or dismissing the tutorial unconditionally marks it seen in `StorageService`, ensuring it appears on first launch and gracefully vanishes on subsequent sessions.
  - Retained persistent re-access from the AppBar Menu (`Icons.more_vert` -> Interactive Onboarding) and Help dialogs.
  - Harmonized portrait mode `Subjective Refraction` FilterChip with dark/light theme adaptivity matching landscape mode.

---

## 11. Clinical Handbook Pedagogical Expansion
- **`lib/screens/handbook_screen.dart`**:
  - Added dedicated clinical guides in the **Technique** tab:
    - *Copeland Straddling Refinement (±45° Method)*: Refines cylinder axis precision to within ±2.5° by comparing differential width and brilliance.
    - *Dynamic Retinoscopy (MEM & Nott)*: Objective measurement of accommodative lag/lead under near demand (+2.50 D).
    - *Mohindra Pediatric Dark-Room Near Technique*: Dark-field infant refraction at 50 cm with −1.25 D tonic accommodation deduction.
  - Added specialized chapters in the **Pathology** tab:
    - *Charleux’s Sign (Oil-Droplet Reflex in Lenticonus / Alport Syndrome)*: Conical refractive power discrepancy and retro-illumination droplet optics.
    - *Dense Nuclear Cataract Central Extinction*: Light scatter and paraxial extinction in grade 3–4 nuclear sclerosis.

---

## 12. Security-First Architecture & Engineering Rules (Update 2026-10)
- **Centralized Security Layer (`lib/services/security_service.dart`)**:
  - **Rule 1: No Hardcoded Secrets/Keys**: Compile-time environment secrets accessed strictly via `SecurityService.getEnvironmentSecret(key)` using `String.fromEnvironment`. Zero API keys or private tokens in source code.
  - **Rule 2: Secure Storage Segregation**: Non-sensitive clinical preferences (theme, working distance, study streak) remain crash-resilient in `SharedPreferences`. Sensitive user credentials, sessions, or tokens are segregated and forbidden from `SharedPreferences`.
  - **Rule 3: Secure Network Communication**: HTTPS strictly enforced for all web endpoints (`SecurityService.safeLaunchUrl`). Insecure plain HTTP links are actively blocked. Global error boundaries wrap external calls to prevent raw stack traces, API endpoints, or database structures from leaking to the UI (`SecurityService.getSafeAuthErrorMessage`).
  - **Rule 4: Clean Data Handling & XSS Shield**: All text inputs (candidate names, patient profiles, clinical notes) pass through `SecurityService.sanitizeText` / `sanitizeName` / `sanitizeNotes`, stripping scripts, HTML tags, control characters, and null bytes. Strict RFC 5322 regex validation (`SecurityService.isValidEmail`) enforced before submitting credentials.
  - **Rule 5: Deep Link Security & Biological Clamping**: Incoming deep links (`retino://case?d=...`) validated via `SecurityService.isValidDeepLinkUri` with scheme/host verification and anti-DoS payload length caps (max 4,096 chars). Refractive parameters clamped to safe physiological bounds:
    - Sphere: $[-25.00\text{ D}, +25.00\text{ D}]$
    - Cylinder: $[-15.00\text{ D}, +15.00\text{ D}]$
    - Axis: $[0^\circ, 180^\circ]$ (normalized modulo 180)
    - Age: $[0, 125]$
- **Comprehensive Verification Suite**:
  - `test/security_audit_test.dart`: 14 automated unit tests verifying compile-time secret fallbacks, script/XSS sanitization, email regex, safe auth error mapping, deep link URI verification, biological bounds clamping, and payload DoS rejection.
  - `test/retinoscopy_clinical_test.dart` (28 tests) and `test/widget_test.dart` (6 tests): All 48 project tests pass with 100% success.
  - `dart analyze lib test`: Clean static analysis with 0 errors and 0 warnings.
