import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/profile_state.dart';
import '../theme/app_theme.dart';

class AchievementDetailScreen extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailScreen({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.surface,
      appBar: AppBar(
        backgroundColor: EcoColors.background,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          achievement.detailTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          _HeroSection(achievement: achievement),
          const SizedBox(height: 32),
          Text(
            'Level ${achievement.level + 1} Requirements',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: EcoColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ...achievement.requirements.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequirementCard(requirement: r),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Back to Profile',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoColors.onSurface,
                backgroundColor: EcoColors.surfaceContainerHigh,
                side: BorderSide(
                  color: EcoColors.outlineVariant.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final Achievement achievement;

  const _HeroSection({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: EcoColors.secondaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: EcoColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            achievement.icon,
            size: 64,
            color: EcoColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          achievement.detailTitle,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: EcoColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                size: 18,
                color: achievement.iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Level ${achievement.level}',
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EcoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EcoColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Level ${achievement.level + 1}',
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${achievement.progressCurrent}/${achievement.progressTotal} Actions',
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: EcoColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: achievement.progressFraction,
                  minHeight: 12,
                  backgroundColor: EcoColors.surfaceVariant,
                  color: EcoColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.progressHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: EcoColors.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final AchievementRequirement requirement;

  const _RequirementCard({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final isNext = requirement.isNext;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNext
            ? EcoColors.surfaceContainer
            : EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? EcoColors.primary.withValues(alpha: 0.2)
              : EcoColors.outlineVariant.withValues(alpha: 0.3),
          width: isNext ? 2 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isNext)
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: EcoColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Icon(
            requirement.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: requirement.completed
                ? EcoColors.primary
                : EcoColors.outline,
            size: 22,
          ),
            const SizedBox(width: 12),
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight:
                        isNext ? FontWeight.w700 : FontWeight.w500,
                    color: EcoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requirement.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: EcoColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isNext
                    ? EcoColors.primary
                    : EcoColors.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                requirement.pointsLabel,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      isNext ? EcoColors.onPrimary : EcoColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
