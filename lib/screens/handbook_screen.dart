import 'package:flutter/material.dart';

/// Clinical Handbook Screen — JMR Technologies Retinoscopy Simulator
/// Comprehensive tabbed clinical reference for ophthalmologists and optometrists.
class HandbookScreen extends StatelessWidget {
  const HandbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Clinical Handbook'),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.science_outlined), text: 'Physics'),
              Tab(icon: Icon(Icons.remove_red_eye_outlined), text: 'Technique'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Interpretation'),
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Optics Math'),
              Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Pathology'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PhysicsTab(),
            _TechniqueTab(),
            _InterpretationTab(),
            _OpticsMathTab(),
            _PathologyTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Physics of Retinoscopy
// ─────────────────────────────────────────────────────────────────────────────
class _PhysicsTab extends StatelessWidget {
  const _PhysicsTab();

  @override
  Widget build(BuildContext context) {
    return _HandbookScrollView(sections: const [
      _Section(
        icon: Icons.lightbulb_outline,
        color: Colors.amber,
        title: 'What is Streak Retinoscopy?',
        content:
            'Streak retinoscopy is an objective refraction technique that determines the refractive error '
            'of the eye without requiring patient responses. A linear streak of light is projected into '
            'the patient\'s eye, and the examiner observes the movement of the reflex (red glow) '
            'in the pupil relative to the direction of the streaking motion.',
      ),
      _Section(
        icon: Icons.hub_outlined,
        color: Colors.blue,
        title: 'The Light Path',
        content:
            'A retinoscope contains a light source (incandescent or LED) focused through a condensing '
            'lens system. The beam exits as a converging streak of light. When this streak enters the '
            'patient\'s eye, it illuminates the retina. The retina then acts as a secondary light source, '
            'reflecting light back out through the pupil toward the examiner.\n\n'
            'The direction and speed of this reflected reflex reveals whether the eye is:\n'
            '• Myopic (near-sighted) — against motion\n'
            '• Hyperopic (far-sighted) — with motion\n'
            '• Emmetropic (corrected) — neutral (fills the pupil)',
      ),
      _Section(
        icon: Icons.blur_circular_outlined,
        color: Colors.purple,
        title: 'The Far Point Concept',
        content:
            'The far point (punctum remotum) is the conjugate point of the retina at distance.\n\n'
            '• Emmetrope: far point is at optical infinity\n'
            '• Myope: far point is at a finite distance in front of the eye\n'
            '• Hyperope: far point is behind the eye (virtual)\n\n'
            'Retinoscopy works by identifying when the retinoscope\'s peephole coincides with the '
            'patient\'s far point — at this point, the reflex fills the entire pupil and shows no movement '
            '(neutrality). The power of lenses needed to achieve this equals the refractive error.',
      ),
      _Section(
        icon: Icons.swap_horiz,
        color: Colors.teal,
        title: 'With vs. Against Motion',
        content:
            'WITH Motion: Reflex moves in the SAME direction as the streak sweep.\n'
            '→ The far point is behind the retinoscope (hyperopia, or mild myopia less than working distance).\n'
            '→ Add PLUS lens power to neutralize.\n\n'
            'AGAINST Motion: Reflex moves OPPOSITE to the streak sweep.\n'
            '→ The far point is between the retinoscope and the patient (myopia greater than working distance).\n'
            '→ Add MINUS lens power (or reduce plus) to neutralize.\n\n'
            'NEUTRALITY: Reflex fills the pupil completely. No motion visible.',
      ),
      _Section(
        icon: Icons.settings_outlined,
        color: Colors.grey,
        title: 'Sleeve Position (Plane vs Concave Mirror Mode)',
        content:
            'Modern streak retinoscopes have a moveable sleeve:\n\n'
            'SLEEVE DOWN (Plane mirror): Light diverges from the eye — examiner sees with motion in hyperopia. '
            'This is the standard position for most modern retinoscopes.\n\n'
            'SLEEVE UP (Concave mirror): Light converges — reverses all motion directions. '
            'Used to confirm neutrality or by some examiners as a personal preference.\n\n'
            'Always know your retinoscope\'s default mode before interpreting motion.',
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Technique
// ─────────────────────────────────────────────────────────────────────────────
class _TechniqueTab extends StatelessWidget {
  const _TechniqueTab();

  @override
  Widget build(BuildContext context) {
    return _HandbookScrollView(sections: const [
      _Section(
        icon: Icons.straighten,
        color: Colors.blue,
        title: 'Working Distance',
        content:
            'The examiner must account for the distance between the retinoscope and the patient\'s eye. '
            'This introduces a vergence correction (working distance offset).\n\n'
            'Working Distance Offsets:\n'
            '• 50 cm (20 inches): subtract 2.00 D\n'
            '• 67 cm (26 inches): subtract 1.50 D ← most common\n'
            '• 100 cm (39 inches): subtract 1.00 D\n\n'
            'Formula: Net Rx = Neutralizing Sphere − (1 / Working Distance in meters)',
      ),
      _Section(
        icon: Icons.rotate_right,
        color: Colors.orange,
        title: 'Finding the Principal Meridians',
        content:
            'For astigmatic eyes:\n\n'
            '1. Rotate the streak until the reflex appears brightest, widest, and fastest — this is the '
            '   LEAST astigmatic meridian. Neutralize this with sphere power.\n\n'
            '2. Rotate streak 90° to the other principal meridian. Neutralize the remaining motion with cylinder power.\n\n'
            'The axis of the cylinder is perpendicular to the streak orientation when neutrality is achieved in that meridian.',
      ),
      _Section(
        icon: Icons.verified_user_outlined,
        color: Colors.green,
        title: 'Plus vs. Minus Cylinder Technique',
        content:
            'PLUS CYLINDER (traditional US ophthalmology):\n'
            '1. Find axis with least WITH motion → neutralize with sphere.\n'
            '2. Rotate 90° → neutralize remaining WITH motion with PLUS cylinder.\n\n'
            'MINUS CYLINDER (traditional UK/optometry):\n'
            '1. Find axis with MOST WITH motion → neutralize with sphere.\n'
            '2. Rotate 90° → neutralize AGAINST motion with MINUS cylinder.\n\n'
            'Both techniques yield the same refractive error — just written in different notations.',
      ),
      _Section(
        icon: Icons.child_care,
        color: Colors.purple,
        title: 'Cycloplegic Retinoscopy',
        content:
            'Children and young adults have active accommodation that can mask hyperopia.\n\n'
            'Cycloplegic drops (e.g., cyclopentolate 1%) paralyze accommodation, allowing:\n'
            '• Full latent hyperopia to be measured\n'
            '• Reliable axis determination in infants\n'
            '• Detection of accommodative esotropia\n\n'
            'Pupil dilation also widens the retinoscopy reflex, making it easier to observe. '
            'This is why the simulator includes a "Dilated Pupil" toggle.',
      ),
      _Section(
        icon: Icons.sync_alt,
        color: Colors.deepOrange,
        title: 'Copeland Straddling Refinement (±45° Method)',
        content:
            'Jack Copeland\'s straddling technique refines cylinder axis precision to within ±2.5°:\n\n'
            '1. Neutralize the primary sphere and approximate cylinder axis.\n'
            '2. Rotate the retinoscope streak 45° to the right of the cylinder axis. Sweep and observe reflex width & brightness.\n'
            '3. Rotate the streak 45° to the left of the axis. Sweep and compare.\n\n'
            '• If thickness and brilliance are IDENTICAL on both sides → axis is perfectly accurate (Equilibrium).\n'
            '• If one side is sharper or brighter → rotate the cylinder axis TOWARD the sharper meridian.\n\n'
            'Use the "Copeland Straddle HUD" tool in the simulator to visualize this in real time.',
      ),
      _Section(
        icon: Icons.auto_graph,
        color: Colors.indigo,
        title: 'Dynamic Retinoscopy: MEM & Nott Protocols',
        content:
            'Dynamic retinoscopy objectively quantifies the accommodative response under near visual demand (e.g., 40 cm = +2.50 D):\n\n'
            '• Monocular Estimation Method (MEM):\n'
            '  Patient reads age-appropriate words on a card attached to the retinoscope at 40 cm.\n'
            '  Examiner sweeps horizontal meridian and introduces loose plus/minus lenses for <0.5 s.\n'
            '  Normal lag: +0.50 D to +0.75 D with-motion.\n'
            '  Lag > +0.75 D indicates Accommodative Insufficiency; against-motion indicates Accommodative Excess.\n\n'
            '• Nott\'s Technique (Zero-Lens Method):\n'
            '  Reading target remains fixed at 40 cm. Examiner physically moves backward until neutral flash is reached.\n'
            '  Accommodative Response = 1 / d_neutral (meters). Eliminates lens-induced magnification artifacts.',
      ),
      _Section(
        icon: Icons.nightlight_round,
        color: Color(0xFFFF6F00),
        title: 'Mohindra Pediatric Dark-Room Near Retinoscopy',
        content:
            'For infants, toddlers, or uncooperative children where cycloplegic drops cannot be administered:\n\n'
            '• Total Dark Room: The sole light source is the dim retinoscope filament held at exactly 50 cm.\n'
            '• Abolishes proximal and picture accommodation; leaves only tonic resting accommodation (dark focus ~+0.75 D).\n'
            '• Neutralize both principal meridians quickly.\n'
            '• Mohindra Correction Factor: Subtract -1.25 D (not -2.00 D) from the gross neutralization:\n'
            '  Net Rx = Gross Lens − 1.25 D (for infants < 2 years, some protocols use -1.00 D).',
      ),
      _Section(
        icon: Icons.tips_and_updates_outlined,
        color: Colors.teal,
        title: 'Clinical Tips',
        content:
            '• Always dim room lights to widen the pupil and improve reflex visibility.\n'
            '• Keep the retinoscope perpendicular to the visual axis.\n'
            '• Sweep smoothly and consistently — jerky motions make interpretation harder.\n'
            '• One eye at a time; cover the other eye (or use a fogging lens).\n'
            '• Use the peephole, not the lens aperture, for observation.\n'
            '• If reflex looks dull or foggy: check for cataract, corneal opacity, or excessive media scatter.',
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Interpretation
// ─────────────────────────────────────────────────────────────────────────────
class _InterpretationTab extends StatelessWidget {
  const _InterpretationTab();

  @override
  Widget build(BuildContext context) {
    return _HandbookScrollView(sections: const [
      _Section(
        icon: Icons.visibility,
        color: Colors.blue,
        title: 'Reflex Characteristics at a Glance',
        content:
            '┌────────────────┬───────────────────────────┐\n'
            '│ Observation     │ Interpretation             │\n'
            '├────────────────┼───────────────────────────┤\n'
            '│ Fast, wide reflex  │ Near neutrality         │\n'
            '│ Slow, narrow reflex│ Far from neutrality     │\n'
            '│ Fills pupil        │ Neutralized (Emmetropia)│\n'
            '│ Skewed reflex      │ Oblique astigmatism     │\n'
            '│ Scissors motion    │ High/irregular astigm.  │\n'
            '│ Dull, grey reflex  │ Media opacity           │\n'
            '│ Irregular reflex   │ Keratoconus, scar       │\n'
            '└────────────────┴───────────────────────────┘',
        monospace: true,
      ),
      _Section(
        icon: Icons.cut_outlined,
        color: Colors.red,
        title: 'Scissors Motion (Irregular Astigmatism)',
        content:
            'Scissors motion presents as two split reflex bands moving in opposite directions — like scissor blades opening.\n\n'
            'Causes:\n'
            '• Keratoconus (cone-shaped cornea)\n'
            '• Corneal scarring or irregular astigmatism\n'
            '• Pellucid marginal degeneration\n'
            '• Lenticular changes (nuclear sclerosis)\n'
            '• Spherical aberration at high corrections\n\n'
            'Management: Use Mohindra retinoscopy (distance estimation), rigid gas-permeable lenses, or corneal topography.',
      ),
      _Section(
        icon: Icons.flash_on_outlined,
        color: Colors.amber,
        title: 'The 4 Astigmatic Phenomena',
        content:
            'When examining an astigmatic eye with streak retinoscopy, four distinct optical phenomena occur when off the principal meridian:\n\n'
            '1. BREAK PHENOMENON:\n'
            '   The pupillary reflex band is visibly misaligned or "broken" relative to the external streak of light across the face/iris. It becomes continuous only when aligned with a principal meridian.\n\n'
            '2. SKEW PHENOMENON:\n'
            '   The reflex moves obliquely in a different direction from the sweep across the pupil.\n\n'
            '3. THICKNESS / WIDTH PHENOMENON:\n'
            '   The reflex appears at its narrowest width when the streak is exactly on the principal meridian.\n\n'
            '4. INTENSITY / BRIGHTNESS PHENOMENON:\n'
            '   The reflex reaches peak illuminance and brilliance when aligned with the principal meridian.',
      ),
      _Section(
        icon: Icons.alt_route_outlined,
        color: Colors.deepPurple,
        title: 'Straddling the Axis Technique',
        content:
            'To refine cylinder axis setting in small astigmatic errors:\n\n'
            '1. Rotate the streak 45° to either side of your estimated cylinder axis (e.g. at 45° and 135° for a 90° axis).\n'
            '2. Compare the reflex width in both straddled positions:\n'
            '   • If widths are EQUAL → Axis is precisely accurate.\n'
            '   • If widths are UNEQUAL → Rotate the correcting cylinder axis toward the meridian that produces the narrower reflex.\n'
            '3. Re-check until both 45° straddled positions show identical thickness.',
      ),
      _Section(
        icon: Icons.compare_arrows,
        color: Colors.orange,
        title: 'Oblique Astigmatism — Skew',
        content:
            'When the streak angle does not align with a principal meridian of an astigmatic eye, '
            'the reflex appears oblique (skewed) relative to the streak.\n\n'
            'The greater the angle difference and the higher the cylinder power, the more pronounced the skew.\n\n'
            'To eliminate skew: rotate the streak until reflex appears parallel to the streak — '
            'this identifies the principal meridian.',
      ),
      _Section(
        icon: Icons.child_friendly_outlined,
        color: Colors.green,
        title: 'Refraction by Age Group',
        content:
            'Neonates: +2.00 to +4.00 D hyperopia (expected at birth, decreases with emmetropization)\n\n'
            'Infants (1–3 years): +1.00 to +2.00 D physiological hyperopia\n\n'
            'School age (6–12): Near emmetropia; myopia onset common after age 7\n\n'
            'Adults: Variable; myopia stabilizes; presbyopia begins ~40 years\n\n'
            'Elderly: Increased nuclear myopia from lens sclerosis; higher astigmatism from corneal changes',
      ),
      _Section(
        icon: Icons.local_hospital_outlined,
        color: Colors.purple,
        title: 'Clinical Significance Thresholds',
        content:
            'Referral/prescription thresholds (approximate guidelines):\n\n'
            '• Hyperopia > +3.50 D in children under 3 years → prescribe\n'
            '• Anisometropia > 1.50 D any meridian → amblyopia risk\n'
            '• Astigmatism > 1.50 DC in infants → prescribe\n'
            '• Myopia > −0.50 D if symptomatic → prescribe\n'
            '• Any anisometropia causing strabismus → urgent referral\n\n'
            'These are general guidelines — individual clinical judgment and guidelines from your jurisdiction apply.',
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: Optics Math
// ─────────────────────────────────────────────────────────────────────────────
class _OpticsMathTab extends StatelessWidget {
  const _OpticsMathTab();

  @override
  Widget build(BuildContext context) {
    return _HandbookScrollView(sections: const [
      _Section(
        icon: Icons.calculate_outlined,
        color: Colors.blue,
        title: 'Working Distance Formula',
        content:
            'Net Sphere = Neutralizing Sphere − (1 / Working Distance)\n\n'
            'Example:\n'
            '  Neutralizing lens: +3.50 D\n'
            '  Working distance: 0.67 m\n'
            '  WD offset: 1/0.67 = 1.50 D\n'
            '  Net Sphere = 3.50 − 1.50 = +2.00 D',
        monospace: true,
      ),
      _Section(
        icon: Icons.swap_horiz,
        color: Colors.teal,
        title: 'Transposition (Plus ↔ Minus Cylinder)',
        content:
            'To convert from plus cylinder to minus cylinder form:\n\n'
            '  1. New Sphere = Old Sphere + Old Cylinder\n'
            '  2. New Cylinder = −Old Cylinder\n'
            '  3. New Axis = Old Axis ± 90° (keep in range 1°–180°)\n\n'
            'Example:\n'
            '  +1.50 +1.00 × 90°\n'
            '  → New Sphere: 1.50 + 1.00 = +2.50\n'
            '  → New Cylinder: −1.00\n'
            '  → New Axis: 90 + 90 = 180°\n'
            '  Result: +2.50 −1.00 × 180°',
        monospace: true,
      ),
      _Section(
        icon: Icons.bubble_chart_outlined,
        color: Colors.purple,
        title: 'Power Vector Notation (Thibos et al.)',
        content:
            'Any spherocylindrical Rx (S, C, α) can be represented as a 3D Cartesian power vector:\n\n'
            '  M   = S + C/2         (mean sphere / spherical equivalent)\n'
            '  J₀  = −(C/2)·cos(2α)  (horizontal/vertical cross-cylinder)\n'
            '  J₄₅ = −(C/2)·sin(2α)  (oblique 45°/135° cross-cylinder)\n'
            '  B   = √(M² + J₀² + J₄₅²) (total dioptric blur strength)\n\n'
            'These three components form an orthogonal coordinate system, '
            'allowing vector addition, statistical averaging, and research comparison.',
        monospace: true,
      ),
      _Section(
        icon: Icons.lens_outlined,
        color: Colors.orange,
        title: 'Spherical Equivalent',
        content:
            'SE = Sphere + (Cylinder / 2)\n\n'
            'Example:\n'
            '  −3.00 −1.50 × 90°\n'
            '  SE = −3.00 + (−1.50 / 2) = −3.75 D\n\n'
            'The spherical equivalent is used to:\n'
            '• Prescribe single-vision contact lenses\n'
            '• Estimate functional visual acuity\n'
            '• Compare refractions in myopia control studies',
        monospace: true,
      ),
      _Section(
        icon: Icons.compress_outlined,
        color: Colors.deepOrange,
        title: 'Javal\'s Rule (Keratometry to Refraction)',
        content:
            'Predicts total refractive astigmatism from corneal curvature (K1, K2):\n\n'
            '  Total Astigmatism = 1.25 × (K2 − K1) − 0.50 D ATR\n'
            '  Corneal Radius r = 337.5 / K (mm)\n\n'
            'Rules of Thumb:\n'
            '• Direct With-the-Rule (WTR): Cornea provides majority of astigmatism.\n'
            '• Against-the-Rule (ATR): Lenticular astigmatism (-0.50 D x 90°) adds to corneal cylinder.\n'
            '• Oblique Astigmatism: Principal meridians tilted off 90°/180° by > 20°.',
        monospace: true,
      ),
      _Section(
        icon: Icons.blur_on,
        color: Colors.purple,
        title: 'Zernike Wavefront Aberrations & Strehl Ratio',
        content:
            'Wavefront error W(ρ,θ) decomposed into orthogonal Zernike polynomials Zn^m:\n\n'
            '• Defocus RMS (Z2,0):  RMS_defocus = (Pupil² / 16√3) · |SE|\n'
            '• Astigmatism RMS (Z2,±2): RMS_astig = (Pupil² / 16√6) · |Cyl|\n'
            '• Strehl Ratio (Maréchal): Strehl ≈ exp(-(2π · RMS / λ)²)\n\n'
            'Optical Quality Benchmarks:\n'
            '• Strehl ≥ 0.80: Diffraction-limited (Crisp 20/15 acuity)\n'
            '• Strehl ≥ 0.40: Normal physiological visual quality (20/20)\n'
            '• Strehl < 0.15: Significant optical blur requiring correction.',
        monospace: true,
      ),
      _Section(
        icon: Icons.timeline_outlined,
        color: Colors.red,
        title: 'Vernier / Stiles-Crawford Effect',
        content:
            'The Stiles-Crawford Effect (SCE) causes light entering the pupil peripherally '
            'to stimulate photoreceptors less efficiently than light entering centrally.\n\n'
            'In retinoscopy: at high pupil dilation or large aberrations, peripheral light '
            'paths produce a dimmer reflex. This can cause overestimation of neutralization.\n\n'
            'Account for SCE by:\n'
            '• Using cycloplegic drops (which dilate)\n'
            '• Performing retinoscopy at the optical axis\n'
            '• Cross-checking with subjective refraction',
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5: Pathology
// ─────────────────────────────────────────────────────────────────────────────
class _PathologyTab extends StatelessWidget {
  const _PathologyTab();

  @override
  Widget build(BuildContext context) {
    return _HandbookScrollView(sections: const [
      _Section(
        icon: Icons.warning_amber_outlined,
        color: Colors.orange,
        title: 'Keratoconus',
        content:
            'Irregular scissors motion with variable reflex brightness. '
            'Often seen as an "oil droplet" reflex (Munson\'s sign on gross observation).\n\n'
            'Retinoscopy characteristics:\n'
            '• Rapidly varying reflex angle as streak is swept\n'
            '• Multiple neutral zones (irregular far points)\n'
            '• Asymmetric brightness within pupil\n\n'
            'Refer for corneal topography, Scheimpflug imaging. Rigid GP lenses or corneal cross-linking may be indicated.',
      ),
      _Section(
        icon: Icons.opacity_outlined,
        color: Colors.grey,
        title: 'Cataract',
        content:
            'A dense nuclear sclerotic cataract causes:\n'
            '• Dull, poorly-defined reflex\n'
            '• "Oil droplet" appearance in advanced nuclear cataract\n'
            '• Apparent myopic shift (index myopia from increased nuclear refractive index)\n\n'
            'Cortical cataract: spokelike opacities may create irregular reflex segments.\n\n'
            'Posterior subcapsular (PSC): dramatic reduction in reflex brightness due to light scatter.',
      ),
      _Section(
        icon: Icons.blur_on_outlined,
        color: Colors.blue,
        title: 'Pellucid Marginal Degeneration (PMD)',
        content:
            'Inferior peripheral corneal thinning causing against-the-rule astigmatism.\n\n'
            'Retinoscopy shows:\n'
            '• Scissors or crab-claw reflex pattern\n'
            '• Axis orientation more oblique than keratoconus\n'
            '• Reflex especially distorted in inferior pupil\n\n'
            'Distinguished from keratoconus on topography: PMD has inferior thinning below the cone, not at the apex.',
      ),
      _Section(
        icon: Icons.lens_blur_outlined,
        color: Colors.teal,
        title: 'High Myopia (> −6.00 D)',
        content:
            'Strong against motion, visible even without lenses in place.\n\n'
            'Challenges:\n'
            '• Very narrow working distance required (e.g., 16 cm for −6.00 D)\n'
            '• Or use high minus trial lenses before retinoscopy\n\n'
            'Also watch for:\n'
            '• Lattice degeneration at periphery\n'
            '• Posterior staphyloma (irregular fundus contour → irregular reflex)\n'
            '• Myopic macular degeneration (central scotoma → absent reflex centrally)',
      ),
      _Section(
        icon: Icons.child_care_outlined,
        color: Colors.purple,
        title: 'Amblyopia & Strabismus Screening',
        content:
            'Retinoscopy is the gold standard for detecting anisometropic amblyopia risk:\n\n'
            '• Anisometropia ≥ 1.50 D → prescribe and monitor\n'
            '• Significant astigmatism in one eye → meridional amblyopia risk\n\n'
            'Photo-retinoscopy (Brückner test):\n'
            '• Asymmetric red reflex brightness between eyes\n'
            '• Crescent reflex on the opposite side of the refractive error in the illuminated eye\n'
            '• Rapid screening for anisometropia and media opacity in infants',
      ),
      _Section(
        icon: Icons.water_drop_outlined,
        color: Color(0xFFFF8F00),
        title: 'Charleux’s Sign (Oil-Droplet Reflex in Lenticonus)',
        content:
            'Pathognomonic for anterior or posterior lenticonus (frequently seen in Alport syndrome) and central keratoconus cones:\n\n'
            '• Presentation: Appears as a distinct, dark circular droplet or oil-bubble in the red reflex under retro-illumination.\n'
            '• Mechanism: Extreme refractive power discrepancy between the steep central conical cone (+10.00 D to +20.00 D myopic shift) and the flatter surrounding lens/cornea creates total internal reflection at the steep margin.\n'
            '• Clinical pearl: The central zone exhibits strong against-motion while the periphery shows with-motion.',
      ),
      _Section(
        icon: Icons.visibility_off_outlined,
        color: Color(0xFF8D6E63),
        title: 'Dense Nuclear Cataract Central Extinction',
        content:
            'In grade 3–4 nuclear sclerotic cataracts (NS3–NS4):\n\n'
            '• Central Extinction: Dense nuclear yellowing and protein aggregation absorb and scatter incident light, extinguishing the central 3 mm reflex.\n'
            '• Peripheral Escape: Only a dim, reddish ring escapes through the clearer cortical periphery.\n'
            '• Management: Dilate the pupil, increase the retinoscope illumination to maximum, or rely on subjective pinhole and automated A-scan biometry.',
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI Components
// ─────────────────────────────────────────────────────────────────────────────

class _HandbookScrollView extends StatelessWidget {
  final List<_Section> sections;
  const _HandbookScrollView({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => sections[i].build(context),
    );
  }
}

class _Section {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  final bool monospace;

  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
    this.monospace = false,
  });

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.2)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: isDark ? 0.22 : 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? colorScheme.onSurface : color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: SelectableText(
              content,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1E293B),
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
