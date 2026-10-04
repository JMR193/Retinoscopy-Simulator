# Product Requirements Document (PRD)
## Project: Next-Generation Clinical Retinoscopy Simulator & Training Suite
**Document Version:** 2.0.0  
**Target Audience:** Ophthalmology Residents, Optometry Students, Pediatric Optometrists, Refractionists, Vision Science Researchers  
**Status:** Approved for Production Deployment  
**Lead Architecture & Medical Engineering:** JMR Tech / Clinical Optics Simulation Team  

---

## 1. Executive Summary & Product Vision

### 1.1 Mission Statement
To provide an authentic, physics-based, interactive clinical simulation platform that bridges the pedagogical gap between textbook physiological optics and real-world retinoscopic examination. The simulator empowers learners and clinicians to develop instinctive motor reflexes, precise axis alignment, and rigorous diagnostic acumen across distance static retinoscopy, dynamic accommodative techniques, and complex irregular astigmatic phenomena.

### 1.2 Target User Personas
1. **Ophthalmology Residents & Optometry Students:**
   - Need: Rapidly master streak manipulation, with/against motion discrimination, neutral flash identification, and gross-to-net spherocylindrical transposition.
   - Pain Point: Scarcity of clinical training eyes with diverse refractive errors, patient fatigue during prolonged student sweeps, and difficulty visualizing conjugate optical planes.
2. **Pediatric & Vision Therapy Clinicians:**
   - Need: Master non-cycloplegic pediatric protocols (Mohindra near technique) and dynamic accommodative lag/lead assessments (MEM, Nott, Bell).
   - Pain Point: Infants and uncooperative children do not tolerate trial frames or prolonged static distance fixation.
3. **Clinical Educators & Board Examiners:**
   - Need: Standardized, reproducible assessment scenarios (OSCE cases) with objective tracking of student sweeps, axis accuracy, and elapsed time.
   - Pain Point: Subjective evaluation of student retinoscopy skills in live clinic without telemetry feedback.

---

## 2. Core Functional Requirements (FR)

### 2.1 Optical & Physical Simulation Engine (FR-OPT)
- **FR-OPT-01 (Continuous Wave Vergence):** The simulator must model emergent wave vergence continuously based on conjugate retinal foci ($M_R$).
- **FR-OPT-02 (Hyperbolic Velocity Scaling):** Reflex sweep velocity must scale asymptotically according to:
  $$V_{reflex} \propto \frac{1}{|P_{net}|} = \frac{1}{|(P_{patient} + P_{trial}) - WD|}$$
  Approaching infinite velocity ("Flash Point") when $|P_{net}| < 0.15\text{ D}$.
- **FR-OPT-03 (Dynamic Aperture Filling):** Reflex width must model intrapupillary flood:
  $$W_{fill} = \frac{1}{1.0 + 0.85 \cdot |P_{net}|} \in [0.12, 1.00]$$
- **FR-OPT-04 (Mirror Mode Inversion):**
  - *Plane Mirror Mode (Sleeve Down):* Divergent beam; sweeps with/against motion standard.
  - *Concave Mirror Mode (Sleeve Up):* Convergent beam crossing in front of instrument; reverses apparent motion direction (*with* becomes *against*, *against* becomes *with*).
- **FR-OPT-05 (Astigmatic Break Phenomenon):** When the streak is oriented off-axis from a principal meridian ($|\theta_{streak} - \alpha| > 0^\circ$), the intrapupillary reflex must visually shear and disalign from the external facial streak.
- **FR-OPT-06 (Copeland Straddle Refinement):** Moving the streak $\pm 45^\circ$ from the cylinder axis must simulate differential reflex thickness and brilliance, achieving axis equilibrium when the error is $< 2.5^\circ$.
- **FR-OPT-07 (Atypical & Pathology Reflexes):**
  - *Scissors Reflex:* Parabolic split-beam opposing motion modeling spherical aberration ($Z_4^0$) and keratoconus.
  - *Oil-Droplet Reflex (Charleux’s Sign):* Central circular dark annular retro-illumination droplet modeling lenticonus.
  - *Media Extinction:* Nuclear cataract density (NS1–NS4) and corneal opacities causing light scatter, dimming, and central scotomas.

---

### 2.2 Clinical Protocols & Workflows (FR-PRO)
- **FR-PRO-01 (AAO 5-Step Plus-Cylinder Protocol):** Guided step-by-step clinical pathway:
  1. Working distance compensation.
  2. $360^\circ$ principal meridian identification.
  3. Sphere neutralization along least with-motion meridian.
  4. Orthogonal $+90^\circ$ plus-cylinder neutralization.
  5. Copeland straddle axis refinement and net deduction.
- **FR-PRO-02 (Optometric Minus-Cylinder Protocol):** Guided pathway neutralizing most with-motion meridian with sphere, then neutralizing remaining against-motion with minus cylinder.
- **FR-PRO-03 (Mohindra Pediatric Near Technique):** Dark-field protocol at $50\text{ cm}$ with $-1.25\text{ D}$ tonic accommodation subtraction factor.
- **FR-PRO-04 (Dynamic Retinoscopy - MEM & Nott):** Accommodative lag/lead measurement under $+2.50\text{ D}$ reading demand ($40\text{ cm}$).
- **FR-PRO-05 (Dual-Meridian Neutral Points Capture):** Direct capture of Gross $M_1$ and Gross $M_2$ with automated algebraic derivation of Final Net Spherocylinder Prescriptions.

---

### 2.3 Educational HUD & Optical Analytics (FR-HUD)
- **FR-HUD-01 (Sturm's Conoid 3D Visualizer):** Real-time canvas ray bundle displaying anterior/posterior focal lines ($F_1, F_2$), Circle of Least Confusion ($COLC$), Interval of Sturm, and automated AAO astigmatism classification with $0^\circ\text{--}60^\circ$ 3D tilt controls.
- **FR-HUD-02 (Reflex Motion Gauge HUD):** Real-time clinical telemetry showing motion type (WITH / AGAINST / NEUTRAL / SCISSORS), velocity progress, photometric brilliance, pupil aperture fill, and break displacement angle.
- **FR-HUD-03 (Spherocylinder Transposition Lab):** Side-by-side Plus-Cyl vs Minus-Cyl conversion cards with algebraic proof steps ($S'=S+C, C'=-C, \alpha'=\alpha\pm90^\circ, SE=S+C/2$) and one-tap phoropter loading.
- **FR-HUD-04 (Thibos Fourier Power Vector HUD):** $M, J_0, J_{45}$ vector decomposition with 2D Jackson Cross-Cylinder scatter plot and overall dioptric blur metric $B = \sqrt{M^2 + J_0^2 + J_{45}^2}$.
- **FR-HUD-05 (2-Meridian Power Cross):** Orthogonal optical cross displaying dioptric powers along principal axes.

---

### 2.4 User Experience, Onboarding & Ergonomics (FR-UX)
- **FR-UX-01 (First-Time Interactive Onboarding):**
  - First-time launch automatically displays an interactive 5-stage mini-lab (`InteractiveOnboardingOverlay`):
    1. Sweeping & Beam Mechanics.
    2. Neutrality Flash Identification.
    3. Trial Lens Wheel Neutralization.
    4. Working Distance Offset Compensation.
    5. Curated Starter Case Selection.
  - Automatically records completion in persistent storage (`StorageService.markSimulatorTourSeen()`) and vanishes.
  - Re-accessible at any time via the AppBar `Help` action.
- **FR-UX-02 (Unified 2-Row Control Deck):** Consolidated Material 3 control dock reducing vertical sprawl by 60% with instant access to collar angles, mirror mode, auto-sweep speeds, working distance presets, and optical tools.
- **FR-UX-03 (Global Theme Synchronization):** Real-time reactive theme toggling (`RetinoscopyState.toggleDarkMode()`) propagating across all views, dialogs, drawers, and tabs with darkroom-optimized high-contrast palettes.
- **FR-UX-04 (Single-Form & Dual-Form Exam Submissions):** Intelligent grading accommodating both single valid prescription entries (Form 1) and dual-form submissions (Form 1 + Form 2) with spherical axis invariance.

---

## 3. Non-Functional Requirements (NFR)

- **NFR-PERF-01 (Frame Rate):** 60 FPS continuous rendering during touch drags, collar rotations, and automated sweeps on standard mobile, tablet, and web browsers.
- **NFR-REL-01 (Crash-Free Rate):** Zero unhandled runtime exceptions; all navigation operations safely guarded against root navigator pop crashes.
- **NFR-PLAT-01 (Cross-Platform):** Single codebase targeting Android (APK/AAB), iOS, macOS, Windows, Linux, and modern Web (CanvasKit / WebGL).
- **NFR-SEC-01 (Privacy & Storage):** Zero unencrypted telemetry; local offline-first persistence with optional cloud sync supporting strict student privacy standards.

---

## 4. Competitive Analysis & Feature Differentiation

| Capability | AAO Web Simulator | EyeDock Refraction | Generic VR Simulators | **Our Retinoscopy Suite** |
| :--- | :--- | :--- | :--- | :--- |
| **Physics Model** | Lookup table | Discrete sprites | Approximation | First-principles wave vergence & tensor math |
| **Velocity Scale** | Stepped | Fixed speed tiers | Fixed speed tiers | Continuous Hyperbolic ($V \propto 1/|P_{net}|$) |
| **Concave Mirror** | No | No | No | Full optical reversal (sleeve-up) |
| **Break & Skew** | No | Static | Scripted | Exact trigonometric angular split & lateral shear |
| **Copeland Straddle** | No | No | No | Interactive $\pm 45^\circ$ thickness & brilliance delta |
| **Scissors & Keratoconus**| No | No | Rare | Dual-blade parabolic split with pupil-diameter scaling |
| **Dynamic Retinoscopy** | No | No | No | MEM, Nott, Mohindra Pediatric, Bell protocols |
| **Sturm's Conoid 3D** | No | No | No | Interactive 3D Perspective Ray-Tracing Canvas |
| **Cost & Availability** | Free (Web only) | Paid Subscription | \$1,000–\$30,000 | **Free / Open Source, Cross-Platform** |

---

## 5. Release Milestones & Lifecycle

- **v1.0.0 (Core Engine):** Static distance streak retinoscopy, basic trial lenses, working distance offsets.
- **v1.1.0 (Clinical Expansion):** AAO clinical protocols, optical ray diagrams, Thibos Fourier vectors, Copeland straddle view.
- **v1.2.0 (Dual Meridian & Theming):** Gross neutral points capture ($M_1/M_2$), single-form smart grading, global dark/light theme sync, Material 3 2-row control dock.
- **v1.3.0 (Optics HUD & Build Hardening):** Sturm's Conoid 3D view, Reflex Motion Gauge HUD, Spherocylinder Transposition Card, Kotlin in-process build resolution.
- **v2.0.0 (Production Master):** Comprehensive PRD, Architecture documentation, Zernike wavefront expansion roadmap, full release APK stability.
