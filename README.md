# 👁️ Retinoscopy Simulator & Clinical Ophthalmic Optics Suite

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%2016%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)](#)
[![Tests](https://img.shields.io/badge/Clinical%20Tests-19%2F19%20Passed%20(100%25)-success)](#)
[![Code Quality](https://img.shields.io/badge/Static%20Analysis-0%20Lints-brightgreen)](#)
[![Security](https://img.shields.io/badge/GDPR-Zero%20Tracking%20Offline-blue)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An advanced, peer-reviewed, clinically validated **Streak Retinoscopy & Visual Optics Suite** engineered for ophthalmology residents, optometry fellows, vision scientists, and eye care practitioners. Features realistic physical fundus backscatter shaders, working distance vergence compensation, Copeland straddle axis refinement, Thibos Fourier power vectors, Zernike wavefront analysis, Javal's rule, a 10-case clinical pathology bank, and interactive beginner onboarding.

Developed with clinical precision by **JMR Technologies**.

---

## 🌟 Comprehensive Clinical Feature Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   RETINOSCOPY MEDICAL SIMULATION SUITE                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Patient Refraction  │ 2. Retinoscope Simulator │ 3. Trial Lenses / Rx    │
│    • Quick Presets      │    • 2D Gesture Sweeps   │    • Phoropter Rack     │
│    • Ground Truth Rx   │    • Auto-Sweep Engine   │    • Plus/Minus Mode    │
│    • Master Case Bank  │    • Sleeve Plane/Concave │    • Axis Stepper       │
├────────────────────────┴──────────────────────────┴─────────────────────────┤
│ 4. Optical Analysis & Ray Tracing                                           │
│    • 2D Conjugate Ray Diagram         • Thibos Fourier Power Vectors (M,J0,J45) │
│    • Zernike Wavefront & Strehl Ratio • Javal's Rule Keratometry Analyzer   │
├─────────────────────────────────────────────────────────────────────────────┤
│ 5. Clinical Training & Assessment                                           │
│    • 5-Stage Interactive Onboarding   • Timed 10-Case Board Exam Screen     │
│    • Duochrome RAM-GAP & JCC Logic    • Exportable PDF Clinical Certificate │
│    • Offline AI Clinical Optics Tutor • Daily Clinical Study Streaks        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Functional Modules

### 1. 🎯 3-Stage Ergonomic Simulator Architecture
* **Stage 1: Patient Refraction Panel**: Ground-truth sphere, cylinder, and axis controls with a **1-Tap Quick Presets Bar** (`Plano`, `Myopia -2.00`, `Hyperopia +3.00`, `WTR Astig`, `ATR Astig`, `Oblique`).
* **Stage 2: Retinoscope Simulator Panel**: Procedural fundus backscatter canvas with realistic pupil constriction, incandescent glow, dynamic reflex width, and high-speed auto-sweeping.
* **Stage 3: Trial Lenses (Phoropter) Panel**: Standardized ophthalmic phoropter controls with bi-directional plus/minus sphere dials, cylinder axis notch, and working distance compensation ($50\text{ cm}$, $67\text{ cm}$, $100\text{ cm}$, Mohindra).

### 2. 🎓 5-Stage Interactive Beginner Onboarding Overlay
* **Stage 1: Streak Sweeping Dynamics**: Demonstrates WITH motion (hyperopia) vs. AGAINST motion (myopia) with an interactive mini sweep canvas.
* **Stage 2: Neutral Point Flash**: Visualizes 100% pupillary aperture fill at infinite apparent velocity.
* **Stage 3: Trial Lens Dialing Rules**: Interactive trial rack demonstrating the $+ / -$ lens neutralization rules.
* **Stage 4: Working Distance Compensation**: Live visual calculation of Gross $\rightarrow$ Net Distance Rx.
* **Stage 5: Starter Case Sandbox**: 1-tap launcher into beginner clinical practice scenarios with active step-by-step guidance.

### 3. 🏥 Curated Clinical Master Case Bank (10 Verified Pathologies)
Includes 10 standard ophthalmic board scenarios with instant simulator loading and encrypted QR payload sharing:
1. **Emmetropia (Plano)**: Standard baseline normal reflex.
2. **Simple Myopia ($-2.50\text{ DS}$)**: Rapid against-motion reflex.
3. **Latent Hyperopia ($+4.00\text{ DS}$)**: Sluggish with-motion requiring high plus power.
4. **With-The-Rule Astigmatism ($+1.00\text{ DS } -2.00\text{ DC } \times 180^\circ$)**: 2-meridian orthogonal neutralization.
5. **Against-The-Rule Astigmatism ($-1.00\text{ DS } -1.50\text{ DC } \times 90^\circ$)**: Steep vertical corneal curvature.
6. **Oblique Astigmatism ($+2.00\text{ DS } -2.00\text{ DC } \times 45^\circ$)**: Demonstrates the Break phenomenon.
7. **Keratoconus (Scissors Motion)**: Dual-blade opposing shearing reflex.
8. **Pediatric Amblyopia Risk ($+5.50\text{ DS } -3.00\text{ DC } \times 90^\circ$)**: High anisometropic refractive error.
9. **Pseudophakic IOL Eye ($+0.50\text{ DS } -0.75\text{ DC } \times 175^\circ$)**: Post-cataract monofocal IOL.
10. **High Myopic Staphyloma ($-8.00\text{ DS } -1.00\text{ DC } \times 15^\circ$)**: Posterior pole elongation.

### 4. 🔬 Advanced Wavefront Optics & Mathematical Analyzers
* **Zernike Wavefront Expansion ($Z_n^m$)**: Calculates Defocus RMS ($Z_2^0$), Astigmatic RMS ($Z_2^{\pm 2}$), Higher-Order Spherical Aberration ($Z_4^0$), and Maréchal Strehl Ratio optical acuity index across $2\text{--}8\text{ mm}$ pupils:
  $$\text{Strehl Ratio} \approx \exp\left(-\left(\frac{2\pi \cdot \text{RMS}_{\text{total}}}{\lambda}\right)^2\right) \quad (\lambda = 0.55\ \mu\text{m})$$
* **Javal's Rule Corneal Astigmatism Predictor**: Computes total refractive astigmatism from Keratometric readings ($K_1, K_2$):
  $$A_{\text{total}} = 1.25 \cdot (K_{\text{vertical}} - K_{\text{horizontal}}) \pm 0.50\text{ D}$$
* **Thibos Fourier Power Vectors**: Transforms spherocylindrical prescriptions into orthogonal Jackson Cross-Cylinder vector components ($M, J_0, J_{45}$):
  $$M = S + \frac{C}{2}, \quad J_0 = -\frac{C}{2}\cos(2\alpha), \quad J_{45} = -\frac{C}{2}\sin(2\alpha)$$
* **Copeland $\pm 45^\circ$ Straddle Refinement**: Verifies cylinder axis alignment by assessing reflex brightness and thickness symmetry across orthogonal straddle angles.

### 5. 🔔 Notifications, Study Streaks & Offline Compliance
* **Daily Clinical Case of the Day**: Scheduled study reminders with custom time picker.
* **Daily Practice Streak Tracker**: Flame badge tracking consecutive days of clinical training.
* **Zero Tracking & Offline GDPR Privacy**: 100% local storage with zero cloud dependencies or analytics.
* **Medical Compliance & CE/FDA Educational Statement**: Standard academic simulation notice.

---

## 📐 Core Optical Physics Formulas

The simulator evaluates ocular refractive power along any arbitrary meridian angle $\theta$ using **Euler's Spherocylindrical Relation**:

$$P(\theta) = S + C \cdot \sin^2(\theta - \alpha)$$

Where:
* $S$ = Spherical power (Diopters)
* $C$ = Cylindrical power (Diopters)
* $\alpha$ = Cylinder axis angle (Degrees)

The total effective defocus $\Delta D$ at working distance $d_{\text{WD}}$ through trial lenses is:

$$P_{\text{net}}(\theta) = P_{\text{patient}}(\theta) + P_{\text{trial}}(\theta)$$
$$\Delta D = P_{\text{net}}(\theta) - \frac{1}{d_{\text{WD}}}$$

Apparent reflex velocity and pupil fill ratio scale continuously with $\Delta D$:

$$\text{Velocity Factor} = \frac{1}{0.12 + 0.38 \cdot |\Delta D|}, \quad \text{Pupil Fill Ratio} = \frac{1}{1.0 + 0.85 \cdot |\Delta D|}$$

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                               # App entry point, M3 theme & navigation shell
├── models/
│   └── patient_profile.dart                # Patient data model & 10-case Master Case Bank
├── state/
│   └── retinoscopy_state.dart              # Optical vergence engine & clinical state machine
├── services/
│   ├── ai_engine.dart                      # Offline AI clinical reasoning engine
│   ├── audio_service.dart                  # Authentic clinical audio cue synthesizer
│   ├── certificate_service.dart            # PDF Clinical Competency certification generator
│   ├── notification_service.dart           # Daily clinical case reminders & notifications
│   └── storage_service.dart                # Persistent SharedPreferences & study streak storage
├── widgets/
│   ├── interactive_onboarding_overlay.dart # 5-Stage animated beginner onboarding overlay
│   ├── realistic_eye.dart                  # High-performance procedural eye & reflex painter
│   ├── trial_lens_overlay.dart             # 3D trial frame with dynamic power tabs & axis ring
│   ├── optical_ray_diagram.dart            # 2D cross-sectional conjugate ray visualizer
│   ├── thibos_vector_plot.dart             # (J0, J45) Fourier vector space plot
│   ├── power_cross_view.dart               # Dynamic 2-meridian optical power cross
│   ├── protocol_guided_banner.dart         # Step-by-step AAO clinical protocol banner
│   ├── copeland_straddle_view.dart         # Copeland ±45° straddle axis refinement view
│   ├── qr_code_dialog.dart                 # Clinical case QR code generator & reader
│   └── subjective_view.dart                # Subjective Snellen acuity & Duochrome simulation
└── screens/
    ├── retinoscopy_simulator_screen.dart   # Primary 3-stage interactive simulator
    ├── exam_screen.dart                    # Timed 10-case Board competency exam
    ├── patient_profiles_screen.dart        # Dual-tab case manager (Master Bank + Custom)
    ├── optical_calculator_screen.dart      # Transposition, Zernike & Javal's Rule calculator
    ├── handbook_screen.dart                # 7-chapter clinical masterclass reference
    ├── ai_tutor_screen.dart                # AI clinical optics assistant & quiz mode
    ├── ar_mode_screen.dart                 # Camera-based AR reticle trainer
    ├── history_screen.dart                 # Exam score records & analytics
    ├── onboarding_screen.dart              # Interactive student onboarding flow
    └── about_screen.dart                   # Compliance, attribution & data management
```

---

## 🛠️ Getting Started & Installation

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.12.0`)
* [Dart SDK](https://dart.dev/get-dart) (`>= 3.0.0`)
* Android Studio / VS Code with Flutter extension
* Java 17 / JDK 17 (Target SDK 36, Android 16)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/JMR193/Retinoscopy-Simulator.git

# 2. Navigate to project root
cd Retinoscopy-Simulator

# 3. Install dependencies
flutter pub get

# 4. Run clinical unit tests
flutter test

# 5. Launch app on connected device / emulator
flutter run
```

---

## 📦 Building Android Release Artifacts

```bash
# Build optimized release APK
flutter build apk --release

# Output path:
# build/app/outputs/flutter-apk/app-release.apk

# Build Google Play Store App Bundle (AAB)
flutter build appbundle --release

# Output path:
# build/app/outputs/bundle/release/app-release.aab
```

---

## 🛡️ Medical & Legal Disclaimer

* **Academic & Training Use Only**: This application is an educational simulation suite for optometry and ophthalmology residents, students, and eye care professionals.
* **Not for Primary Human Diagnosis**: This software is not a primary diagnostic medical device and does not replace in-person clinical refraction performed by a licensed practitioner.
* **Zero Tracking Guarantee**: All patient profiles, exam scores, and preferences are stored locally on the user's device. No personal data or telemetry is collected.

---

## 👨‍⚕️ Author & Clinical Attribution

**JMR Technologies**  
*Advancing Ophthalmic Optics & Medical Simulation Worldwide.*  
Licensed under the [MIT License](LICENSE).
