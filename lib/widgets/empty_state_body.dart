import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyStateBody extends StatelessWidget {
  final VoidCallback onCompleteAction;
  final bool isLoading;

  const EmptyStateBody({
    super.key,
    required this.onCompleteAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── Welcome Header ──────────────────────────────
        _WelcomeHeader(),
        const SizedBox(height: 24),

        // ── Stats Bento Grid ────────────────────────────
        _EmptyStatsBento(),
        const SizedBox(height: 24),

        // ── Today's Action Card ─────────────────────────
        _DailyActionCard(
          onCompleteAction: onCompleteAction,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),

        // ── Did You Know Card ───────────────────────────
        _DidYouKnowCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Welcome Header
// ─────────────────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME BACK',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Time for your\nfirst impact.',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: EcoColors.onSurface,
            height: 1.1,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty Stats Bento Grid
// ─────────────────────────────────────────────────────────
class _EmptyStatsBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: EcoColors.tertiary,
                    value: '0',
                    label: 'Day Streak',
                  ),
                ),
                const SizedBox(height: 10),
                // CO2 card
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.co2_rounded,
                    iconColor: EcoColors.primary,
                    value: '0.0',
                    label: 'kg Saved',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right: Start Journey card (wide)
          Expanded(
            child: _StartJourneyCard(),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SmallStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EcoColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: EcoColors.onSurface,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: EcoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartJourneyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EcoColors.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerLowest.withOpacity(0.5),
              border: Border.all(
                color: EcoColors.primary.withOpacity(0.15),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: EcoColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start your journey',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: EcoColors.primary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first task to see your progress bloom.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: EcoColors.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Daily Action Card — empty state
// ─────────────────────────────────────────────────────────
class _DailyActionCard extends StatelessWidget {
  final VoidCallback onCompleteAction;
  final bool isLoading;

  const _DailyActionCard({
    required this.onCompleteAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=800&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: EcoColors.surfaceContainer,
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 48,
                      color: EcoColors.primary,
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00833E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'DAILY CHALLENGE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ditch the Plastic Bottle',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: EcoColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use a reusable water bottle for the entire day. This simple switch prevents about 0.5kg of plastic waste and saves CO₂ from production and transport.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: EcoColors.onSurfaceVariant.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onCompleteAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoColors.primary,
                      foregroundColor: EcoColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete First Action',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Did You Know Card
// ─────────────────────────────────────────────────────────
class _DidYouKnowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoColors.secondaryContainer.withOpacity(0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.secondary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.secondary.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: EcoColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Did you know?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: EcoColors.secondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The average person generates 2.3 kg of CO₂ daily just through food consumption. Small changes like a meatless Monday can reduce your footprint by up to 15%.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: EcoColors.onSecondaryContainer,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
