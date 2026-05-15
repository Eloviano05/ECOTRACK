import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/progress_state.dart';
import '../theme/app_theme.dart';

class ProgressCategoryDetailScreen extends StatelessWidget {
  final ProgressCategoryDetail detail;

  const ProgressCategoryDetailScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _DetailAppBar(title: detail.title),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroMetricCard(detail: detail),
          const SizedBox(height: 20),
          _WeeklyTrendCard(detail: detail),
          const SizedBox(height: 24),
          _ContributionsSection(detail: detail),
          const SizedBox(height: 24),
          _TipCard(detail: detail),
        ],
        ),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _DetailAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: EcoColors.primary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: EcoColors.secondaryContainer,
            child: Text(
              'JD',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: EcoColors.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  final ProgressCategoryDetail detail;

  const _HeroMetricCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              detail.heroIcon,
              size: 80,
              color: EcoColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            children: [
              Text(
                detail.heroLabel.toUpperCase(),
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: EcoColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail.heroValue,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: EcoColors.primary,
                  letterSpacing: -1.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.heroSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: EcoColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EcoColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: EcoColors.onPrimaryFixedVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      detail.trendLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onPrimaryFixedVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  final ProgressCategoryDetail detail;

  const _WeeklyTrendCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Trend',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily conservation (${detail.avgUnit})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    detail.avgPerDay.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: EcoColors.primary,
                    ),
                  ),
                  Text(
                    'Avg/Day',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = detail.weeklyHeights[i].clamp(0.1, 1.0);
                final isPeak = h ==
                    detail.weeklyHeights.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 100 * h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isPeak
                                ? EcoColors.primary
                                : EcoColors.outlineVariant
                                    .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: isPeak
                                ? const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progressWeekdayLabels[i],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isPeak ? FontWeight.w700 : FontWeight.w500,
                            color: isPeak
                                ? EcoColors.primary
                                : EcoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionsSection extends StatelessWidget {
  final ProgressCategoryDetail detail;

  const _ContributionsSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Contributions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EcoColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...detail.contributions.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ContributionTile(contribution: c),
          ),
        ),
      ],
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final ProgressContribution contribution;

  const _ContributionTile({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EcoColors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(contribution.icon, color: EcoColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EcoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contribution.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: EcoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                contribution.amount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.primary,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: EcoColors.outlineVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final ProgressCategoryDetail detail;

  const _TipCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EcoColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.onPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: EcoColors.primaryFixed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'QUICK TIP',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: EcoColors.primaryFixed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                detail.tipTitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.onPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: EcoColors.surfaceContainerLowest,
                  foregroundColor: EcoColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  detail.tipCta,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
