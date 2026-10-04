# System Architecture & Scientific Optics Engine Specification
## Project: Next-Generation Clinical Retinoscopy Simulator & Training Suite
**Document Version:** 2.0.0  
**Language / Framework:** Dart 3.x / Flutter 3.x (Material 3)  
**System Architecture:** Layered Reactive Architecture (Clean / Unidirectional Data Flow)  
**Author:** JMR Tech / Clinical Optics Simulation Team  

---

## 1. High-Level Architectural Pattern

The application follows a clean, decoupled, layered architecture:

```
+-----------------------------------------------------------------------------------+
|                                 1. UI / VIEW LAYER                                |
|   - Screen Composers (RetinoscopySimulatorScreen, ExamScreen, HandbookScreen)     |
|   - High-Performance Custom Canvas Painters (RealisticEye, SturmsConoidPainter)  |
|   - Interactive Clinical Overlays (ReflexMotionGauge, TranspositionCard)          |
|   - First-Time Guided Onboarding (InteractiveOnboardingOverlay)                   |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼ (User Gestures & Intent)
+-----------------------------------------------------------------------------------+
|                        2. APPLICATION & STATE MANAGEMENT                          |
|   - RetinoscopyState (ChangeNotifier Provider)                                    |
|   - Reactive Getters & Mutators (beamPosition, streakAngle, trialLensPowers)      |
|   - Global Theme Provider (isDarkMode persistence)                                |
|   - Navigation Coordination & Viewport State                                      |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼ (Evaluates Mathematical Models)
+-----------------------------------------------------------------------------------+
|                     3. DOMAIN OPTICAL PHYSICS & MATH ENGINE                       |
|   - Spherocylindrical Dioptric Tensor & Matrix Solver (Keating / Harris)          |
|   - Thibos Fourier Power Vector Decomposition (M, J0, J45)                        |
|   - Sturm's Conoid Interval & Circle of Least Confusion (COLC) Geometry           |
|   - Continuous Reflex Telemetry (Hyperbolic Velocity, Luminance, Pupil Fill)      |
|   - Astigmatic Break & Skew Trigonometric Evaluators                              |
|   - Copeland Straddle Equilibrium Engine                                          |
|   - Dynamic Retinoscopy Manager (MEM, Nott, Mohindra Pediatric, Bell)             |
|   - Atypical Reflex Generators (Keratoconic Scissors, Oil-Droplet, Cataract)     |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼ (State Persistence & Verification)
+-----------------------------------------------------------------------------------+
|                             4. DATA & SERVICES LAYER                              |
|   - StorageService (SharedPreferences / Offline-First Cache)                      |
|   - CloudSyncService (Cloud Firestore Synchronizer)                               |
|   - AudioService (Haptic & Audible Dial Detents)                                  |
|   - CertificateService (Vector PDF CME Certificate Generator)                     |
|   - RetinoscopyAIEngine (Heuristic Pedagogical Guidance & Real-time Hints)        |
+-----------------------------------------------------------------------------------+
```

---

## 2. Domain Optics & Mathematical Engine Specifications

### 2.1 Spherocylindrical Power Matrix Formulation
In ophthalmic physiological optics, a spherocylinder lens power $S / C \times \alpha$ along an arbitrary sweep meridian angle $\theta_{sweep}$ is computed using the symmetric $2 \times 2$ dioptric power tensor $\mathbf{F}$:

$$\mathbf{F} = \begin{pmatrix} F_{xx} & F_{xy} \\ F_{yx} & F_{yy} \end{pmatrix} = \begin{pmatrix} S + C \sin^2 \alpha & -\frac{1}{2} C \sin(2\alpha) \\ -\frac{1}{2} C \sin(2\alpha) & S + C \cos^2 \alpha \end{pmatrix}$$

The refractive power along any sweep vector $\mathbf{u}(\theta) = (\cos \theta, \sin \theta)^T$ is evaluated via:
$$P(\theta) = \mathbf{u}^T \mathbf{F} \mathbf{u} = S + C \sin^2(\theta - \alpha)$$

### 2.2 Thibos Fourier Power Vector Space
To perform linear additions without coordinate singularities at the $180^\circ / 0^\circ$ axis boundary, the engine translates lens powers into the orthonormal Fourier basis space $\mathbf{f} = (M, J_0, J_{45})^T$:

$$M = S + \frac{C}{2}$$
$$J_0 = -\frac{C}{2} \cos(2\alpha)$$
$$J_{45} = -\frac{C}{2} \sin(2\alpha)$$

The Total Dioptric Blur metric ($B$) represents the Euclidean distance from optical emmetropia in diopter space:
$$B = \sqrt{M^2 + J_0^2 + J_{45}^2}$$

### 2.3 Continuous Reflex Telemetry Equations
In real-time Canvas rendering, reflex motion is parameterized continuously:
1. **Net Vergence Error ($P_{net}$):**
   $$P_{net} = P_{patient}(\theta_{sweep}) - \left[ P_{trial}(\theta_{sweep}) - WD \right]$$
2. **Angular Sweep Velocity ($V_{reflex}$):**
   $$V_{reflex} = V_{base} \cdot \left( \frac{1}{0.12 + 0.38 \cdot |P_{net}|} \right) \in [0.60, \, 4.80]$$
   *(Near neutrality $|P_{net}| < 0.15\text{ D}$, the reflex velocity accelerates asymptotically toward infinity, creating the instantaneous "Flash Point").*
3. **Reflex Luminance / Brilliance ($I_{reflex}$):**
   $$I_{reflex} = \left( \frac{1.0}{1.0 + 0.70 \cdot |P_{net}|} \right) \cdot (1 - 0.75 \delta_{cataract}) \cdot (1 - 0.60 \delta_{cornea})$$
4. **Pupillary Aperture Fill Factor ($W_{fill}$):**
   $$W_{fill} = \left( \frac{1.0}{1.0 + 0.85 \cdot |P_{net}|} \right) \in [0.12, \, 1.00]$$
5. **Astigmatic Break Displacement Angle ($\Delta \theta_{break}$):**
   $$\Delta \theta_{break} = \left[ (\theta_{streak} - \alpha) \pmod{180^\circ} \right] \cdot \min\left(1.0, \, \frac{|C|}{3.5}\right)$$

### 2.4 Sturm's Conoid 3D Geometry
Light refracted through an astigmatic eye creates two orthogonal focal lines and an intermediate circular blur:
- **Anterior Focal Line ($F_1$):** Strongest converging meridian ($D_1 = \max(M_1, M_2)$).
- **Posterior Focal Line ($F_2$):** Weakest converging meridian ($D_2 = \min(M_1, M_2)$).
- **Interval of Sturm:** $\Delta f = |f_1 - f_2| = \frac{|C|}{D_1 D_2}$.
- **Circle of Least Confusion ($COLC$):** The dioptric midpoint where rays cross with circular symmetry:
  $$D_{COLC} = \frac{D_1 + D_2}{2} = M$$

---

## 3. Presentation & Rendering Architecture

### 3.1 Custom Canvas Rendering Pipeline
All optical rendering occurs inside dedicated `CustomPainter` widgets surrounded by `RepaintBoundary` wrappers to ensure 60/120 FPS performance on high-refresh mobile and desktop displays:

1. **`RealisticEyePainter` (`lib/widgets/realistic_eye.dart`):**
   - Renders multi-layered physiological eye anatomy: scleral vascularization, limbus transition gradient, trabecular iris crypts, pupil aperture clipping path, catoptric Purkinje light reflections, and fundus retro-illumination red glow.
   - Projects the retinoscope streak across the face and pupil, applying trigonometric break angles and lateral skew offsets.
2. **`SturmsConoidPainter` (`lib/widgets/sturms_conoid_view.dart`):**
   - Projects 3D incident collimated ray bundles through a refractive lens plane onto the retina with a dynamic perspective tilt matrix ($0^\circ\text{--}60^\circ$).
   - Renders labeled focal lines ($F_1, F_2$), the Circle of Least Confusion, and the Retinal Plane.
3. **`ReflexMotionGauge` (`lib/widgets/reflex_motion_gauge.dart`):**
   - Real-time telemetry HUD displaying animated motion direction indicators (WITH, AGAINST, FLASH, SCISSORS), circular velocity progress, luminance percentage, and break angles.

---

### 3.2 First-Time User Onboarding Lifecycle

```
App Launch (Simulator Tab)
        │
        ▼
StorageService.hasSeenSimulatorTour()
        │
   ┌────┴─────────────────────────┐
   ▼                              ▼
(true)                          (false)
Bypass Onboarding         Display InteractiveOnboardingOverlay
                                  │
                                  ▼
                          5-Stage Interactive Mini-Lab:
                          1. Beam Sweeping & With/Against Motion
                          2. Neutral Flash Identification
                          3. Trial Lens Wheel Neutralization
                          4. Working Distance Deduction (-1.50 D)
                          5. Starter Case Selection & Launch
                                  │
                                  ▼
                          User Completes or Taps "Don't Show Again"
                                  │
                                  ▼
                          StorageService.markSimulatorTourSeen()
                          (Persisted to SharedPreferences / Storage)
                                  │
                                  ▼
                          Overlay Vanishes Permanently
                          (Re-accessible anytime via AppBar Help '?')
```

---

## 4. State Management & Data Flow

The application utilizes `provider` with `RetinoscopyState` serving as the central `ChangeNotifier`:
- **Unidirectional Data Flow:** User actions (dragging streak, dialing phoropter wheel, toggling mirror) mutate private state variables and trigger `notifyListeners()`.
- **Selective Repainting:** Widgets bind only to relevant slices of state using `context.select(...)` or `Consumer<RetinoscopyState>` to prevent redundant tree rebuilds.
- **Global Theme Synchronization:** Dark/light mode state is managed centrally via `RetinoscopyState.isDarkMode`, automatically updating `MaterialApp(themeMode: ...)` and persisting via `StorageService.setDarkMode(...)`.

---

## 5. Persistence, Security & Offline-First Strategy

- **Offline-First Storage:** User progress, exam scores, case completions, and theme preferences are stored locally via `SharedPreferences`.
- **Cloud Synchronization:** When authenticated via `AuthService` (Firebase Auth), `CloudSyncService` executes two-way incremental sync with Cloud Firestore.
- **Privacy Compliance:** No personally identifiable health data is collected. Student usernames and exam scores use anonymized identifiers.

---

## 6. Testing & Quality Assurance Architecture

The test suite enforces mathematical rigor and UI stability:
1. **Clinical & Mathematical Unit Tests (`test/retinoscopy_clinical_test.dart`):**
   - 28 automated test specifications covering:
     - Pure spherical error validation and axis insensitivity.
     - Single-form and dual-form prescription submissions.
     - Gross neutral point calculation and spherocylindrical transposition invariance ($M_1/M_2$).
     - Thibos Fourier power vector decompositions.
     - Copeland straddle illuminance balance.
     - Hyperbolic reflex velocity calculations.
2. **Widget & Screen Integration Tests (`test/widget_test.dart`):**
   - 6 end-to-end widget tests verifying:
     - Phoropter lens dial responsiveness.
     - `SturmsConoidView` 3D rendering and tilt scrub controls.
     - `ReflexMotionGauge` live telemetry updates.
     - `SpherocylinderTranspositionCard` clipboard and loading actions.
     - Simulator screen composition and navigation safety.
3. **Static Analysis Enforcement:**
   - 0 compiler warnings, 0 lints, strictly adhering to `flutter_lints` and Effective Dart documentation standards.
