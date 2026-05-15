import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/eco_tip.dart';
import '../theme/app_theme.dart';

class TipDetailScreen extends StatefulWidget {
  final EcoTip tip;
  const TipDetailScreen({super.key, required this.tip});

  @override
  State<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<TipDetailScreen> {
  late List<bool> _completed;
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.tip.steps.map((s) => s.completed).toList();
  }

  void _toggleStep(int i) => setState(() => _completed[i] = !_completed[i]);

  void _markRead() {
    setState(() => _markedRead = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Tip saved to your library!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: EcoColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;

    return Scaffold(
      backgroundColor: EcoColors.surface,
      appBar: _DetailAppBar(title: tip.title),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── Hero image ──────────────────────────────────
          _HeroImage(tip: tip),
          const SizedBox(height: 28),

          // ── Summary ─────────────────────────────────────
          Text(
            tip.summary,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: EcoColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // ── Impact metric card ──────────────────────────
          _ImpactCard(savingsLabel: tip.savingsLabel),
          const SizedBox(height: 32),

          // ── Steps ───────────────────────────────────────
          Text(
            'What you can do',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: EcoColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            tip.steps.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StepCard(
                step: tip.steps[i],
                completed: _completed[i],
                onTap: () => _toggleStep(i),
              ),
            ),
          ),
        ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: _MarkReadBar(
        marked: _markedRead,
        onTap: _markedRead ? null : _markRead,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────
class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _DetailAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: EcoColors.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.share_outlined, color: EcoColors.primary),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: EcoColors.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero image with icon overlay
// ─────────────────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final EcoTip tip;
  const _HeroImage({required this.tip});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.08),
                BlendMode.darken,
              ),
              child: Image.network(
                tip.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: EcoColors.surfaceContainer,
                  child: Icon(tip.icon, size: 64, color: EcoColors.primary),
                ),
              ),
            ),
            // Green tint overlay
            Container(
              decoration: BoxDecoration(
                color: EcoColors.primary.withOpacity(0.08),
              ),
            ),
            // Center icon badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(tip.icon, color: EcoColors.primary, size: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Impact metric card
// ─────────────────────────────────────────────────────────
class _ImpactCard extends StatelessWidget {
  final String savingsLabel;
  const _ImpactCard({required this.savingsLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoColors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Leaf icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: const Icon(Icons.eco_rounded,
                color: EcoColors.onSecondaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EST. SAVINGS',
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: EcoColors.onSecondaryContainer.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  savingsLabel,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: EcoColors.onSecondaryContainer,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.trending_down_rounded,
            color: EcoColors.onSecondaryContainer,
            size: 32,
            shadows: [Shadow(color: Colors.black12, blurRadius: 4)],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Individual step card (tappable checkbox)
// ─────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final TipStep step;
  final bool completed;
  final VoidCallback onTap;

  const _StepCard({
    required this.step,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed ? EcoColors.primary : EcoColors.outlineVariant,
            width: completed ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: completed ? EcoColors.primary : EcoColors.outline,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: EcoColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EcoColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sticky bottom CTA bar
// ─────────────────────────────────────────────────────────
class _MarkReadBar extends StatelessWidget {
  final bool marked;
  final VoidCallback? onTap;

  const _MarkReadBar({required this.marked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(
              marked ? Icons.check_rounded : Icons.done_all_rounded,
              size: 20,
            ),
            label: Text(
              marked ? 'Tip Saved!' : 'Mark Tip as Read',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  marked ? EcoColors.surfaceContainerHigh : EcoColors.primary,
              foregroundColor:
                  marked ? EcoColors.outline : EcoColors.onPrimary,
              shape: const StadiumBorder(),
              elevation: marked ? 0 : 3,
              shadowColor: EcoColors.primary.withOpacity(0.30),
            ),
          ),
        ),
      ),
    );
  }
}
