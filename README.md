# 👁️ Retinoscopy Simulator & Clinical Ophthalmic Optics Suite

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Medical%20Optics-Verified-brightgreen)](#)

An advanced, clinically validated **Streak Retinoscopy & Ophthalmic Optics Simulation Suite** designed for ophthalmology residents, optometry students, vision science researchers, and eye care clinicians to master objective refraction, pupillary fundus reflex interpretation, astigmatic neutralization, and optical ray tracing.

Developed with precision by **JMR Technologies**.

---

## 🌟 Key Features

### 1. 🎯 Interactive Streak Retinoscopy Engine
- **Procedural Physical Eye Simulation**: High-fidelity fundus backscatter shaders, physiological pupillary hippus oscillations, and light reflex constriction.
- **Physical Fundus Reflex Dynamics**:
  - **With-Motion**: Far point conjugate behind retinoscope (neutralized with **Plus lenses**).
  - **Against-Motion**: Emergent rays crossing in front of peephole (neutralized with **Minus lenses**).
  - **Neutrality Point Flash**: Instant 100% pupillary cavity incandescent illumination at exact conjugacy.
  - **Astigmatic Signatures**: Models the **Break Phenomenon** (meridional tilt misalignment), **Thickness/Brilliance Variation**, and **Skew Movement**.
  - **Scissors Motion Aberration**: Dual-blade shearing reflex modeling irregular astigmatism and keratoconus.
- **Hardware Retinoscope Controls**:
  - Continuous **0°–180° collar rotation** with quick-snap buttons (0°, 45°, 90°, 135°, 180°) and **Flip 90°** orthogonal toggle.
  - **Sleeve Position Toggle**: Switch between *Plane Mirror* (divergent) and *Concave Mirror* (convergent) optical modes.
  - **Continuous Auto-Sweep Oscillator**: Smooth automatic sweeping at 1.0x, 1.5x, or 2.0x speeds.
  - **Tactile 2D Gesture Sweeps**: Omnidirectional touch pan projecting vectors onto the streak's perpendicular sweep axis.
  - **Working Distance Adjuster**: Standard presets for 67 cm (+1.50 D), 50 cm (+2.00 D), 100 cm (+1.00 D), and pediatric Mohindra protocol.

---

### 2. 🔬 3D Realistic Trial Lens Frame Overlay
- **Authentic Beveled Trial Ring**: Color-coded clinical frame (Olive Green for Plus lenses, Crimson Red for Minus lenses).
- **Dynamic Power Tabs**:
  - **Left Sphere Tab**: Displays signed Sphere power (e.g., +0.50, -1.50).
  - **Right Cylinder Tab**: Displays signed Cylinder power (e.g., +0.25, -0.75).
- **Rotating Cylinder Axis Ring**: Top alignment notch (|) and bottom axis degree badge (90°, 180°, etc.) that pivot seamlessly with cylinder axis angle changes.

---

### 3. 📝 Board-Style Clinical Exam Assessment Mode
- **10-Case Timed Clinical Scenarios**: Patient age, case history, working distance vergence, and explicit Principal Meridian Neutralization findings.
- **Bidirectional Transposition Checking**: Mathematical evaluation of both **Primary Prescription** and **Transposed Prescription** forms with fractional diopter tolerances.
- **Automated Scoring & PDF Certification**: Instant percentage calculation, performance breakdown, and exportable PDF Certificates of Competency.

---

### 4. 🤖 AI Clinical Optics Tutor & Knowledge Base
- **Offline Clinical AI Assistant**: Operates completely offline with zero cloud dependencies.
- **1-Tap Simulation State Analyzer**: Live diagnosis of current pupil reflex, speed, brilliance, sleeve mode, and step-by-step neutralization recommendations.
- **Clinical Knowledge Library**: Comprehensive knowledge on plane vs. concave mirror physics, Copeland straddle technique, Mohindra protocol, and irregular scissors motion.

---

### 5. 📚 Retinoscopy Clinical Masterclass Handbook
Comprehensive 7-chapter clinical curriculum aligned with AAO BCSC and Duke-Elder optics:
1. *Optical Foundations of Streak Retinoscopy* (Illumination, Reflex, Observation).
2. *Working Distance Concept & Vergence Proofs*.
3. *Interpreting the Reflex: Direction, Speed, Brilliance, and Width*.
4. *Astigmatism Phenomena: Break, Thickness, Intensity, and Skew*.
5. *Step-by-Step Neutralization Protocols (Plus & Minus Cylinder)*.
6. *Pediatric Retinoscopy & Mohindra Protocols*.
7. *Troubleshooting Abnormal Reflexes & Optical Aberrations*.

---

### 6. 🧮 2-Meridian Optical Power Cross & Calculator
- Dynamic **2-Meridian Power Cross** rendering principal meridians based on Euler's relation.
- Instant bi-directional transposition between **Minus-Cylinder** and **Plus-Cylinder** formats.
- Real-time calculation of **Spherical Equivalent (SE)** and working distance offsets.

---

### 7. 📊 Thibos Fourier 2D Power Vector Space
- Visualizes (J0, J45) orthogonal and oblique Jackson Cross-Cylinder components.
- Computes overall Dioptric Blur metric B = sqrt(M^2 + J0^2 + J45^2) with concentric blur contour rings.

---

### 8. 🎛️ Optical Physics User Customizations
- **Base Pupil Aperture Size Slider**: Calibrate physiological pupil size from 2.5 mm (miotic) to 8.5 mm (mydriatic), default 5.2 mm.
- **Fundus Luminance & Glow Slider**: Adjust incandescent choroidal backscatter brightness from 50% to 200% (default 100%).
- **1-Tap Reset Button**: **'Reset Optical Physics to Default'** instantly restores exact physiological baselines.

---

### 9. 🎧 Authentic Clinical Audio & Sound System
- **Mechanical Dial Stepper Clicks**: Auditory feedback for lens diopter steps.
- **Neutrality Chime & Success Tone**: Clear tone on achieving exact neutralization.
- **Incorrect Buzzer & Timeout Alerts**: Audio cues for exam submissions and timer countdown.

---

## 🔬 Optical Physics & Mathematical Model

The simulator evaluates ocular refractive power along any arbitrary meridian angle theta using **Euler's Spherocylindrical Formula**:

P(\theta) = S + C \cdot \sin^2(\theta - \alpha)

Where:
- S = Spherical power (Diopters)
- C = Cylindrical power (Diopters)
- alpha = Cylinder axis angle (Radians/Degrees)

The total effective defocus Delta D at the examiner's working distance D_WD through trial lens (S_t, C_t, alpha_t) is computed by:

P_{\text{net}}(\theta) = P_{\text{eye}}(\theta) + P_{\text{trial}}(\theta)

\Delta D = P_{\text{net}}(\theta) - D_{\text{WD}}

Reflex parameters (speed, width, brightness, and offset) dynamically scale as non-linear functions of |Delta D|, accurately reproducing physical optical sensitivity near neutrality:

\text{Speed} = \frac{1}{1 + k_1 \cdot |\Delta D|}, \quad \text{Brilliance} = \frac{1}{1 + k_2 \cdot |\Delta D|^{1.4}}

---

---

## 🛠️ Getting Started & Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.12+ recommended)
- [Dart SDK](https://dart.dev/get-dart) (3.0+)
- Android Studio / VS Code with Flutter extension

### Quick Start

`ash
# 1. Clone the repository
git clone https://github.com/<your-username>/retinoscopy-simulator.git

# 2. Navigate to project root
cd retinoscopy-simulator

# 3. Install dependencies
flutter pub get

# 4. Run static analysis
flutter analyze lib/

# 5. Launch app on connected device / emulator
flutter run
`

---

## 📱 Building Android Release APK / App Bundle

`ash
# Build optimized release APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
`

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👨‍⚕️ Developed By

**JMR Technologies**  
*Advancing Ophthalmic Optics & Medical Simulation Education Worldwide.*
