import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/progress_state.dart';
import '../theme/app_theme.dart';
import 'progress_category_detail_screen.dart';

class ProgressScreen extends StatelessWidget {
  final bool isEmpty;
  final VoidCallback? onGoToDashboard;

  const ProgressScreen({
    super.key,
    required this.isEmpty,
    this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = isEmpty ? emptyProgressMetrics : activeProgressMetrics;
    final weeklyHeights =
        isEmpty ? List.filled(7, 0.05) : activeWeeklyHeights;

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: const _ProgressAppBar(),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _MetricsBento(
            metrics: metrics,
            onMetricTap: isEmpty
                ? null
                : (metric) => _openCategory(context, metric.type),
          ),
          const SizedBox(height: 24),
          if (isEmpty)
            _EmptyStateHero(onGoToDashboard: onGoToDashboard)
          else
            _ActiveOverview(weeklyHeights: weeklyHeights),
          const SizedBox(height: 32),
          _WeeklyActivitySection(
            weeklyHeights: weeklyHeights,
            highlightPeak: !isEmpty,
          ),
        ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, ProgressCategoryType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressCategoryDetailScreen(
          detail: detailForCategory(type),
        ),
      ),
    );
  }
}

class _ProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProgressAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.secondaryContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              'https://i.pravatar.cc/80?img=33',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                size: 18,
                color: EcoColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Progress',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: EcoColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: EcoColors.primary,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _MetricsBento extends StatelessWidget {
  final List<ProgressMetric> metrics;
  final void Function(ProgressMetric)? onMetricTap;

  const _MetricsBento({required this.metrics, this.onMetricTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: metrics.map((m) {
        return _MetricCard(
          metric: m,
          onTap: m.isTappable && onMetricTap != null
              ? () => onMetricTap!(m)
              : null,
        );
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final ProgressMetric metric;
  final VoidCallback? onTap;

  const _MetricCard({required this.metric, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.icon, color: metric.iconColor, size: 24),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: EcoColors.outline.withValues(alpha: 0.8),
                ),
            ],
          ),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.publicSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EcoColors.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EcoColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _EmptyStateHero extends StatelessWidget {
  final VoidCallback? onGoToDashboard;

  const _EmptyStateHero({this.onGoToDashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxWidth * 0.52).clamp(140.0, 200.0);
              return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&q=80',
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => Container(
                      color: EcoColors.secondaryContainer,
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 64,
                        color: EcoColors.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: EcoColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Your impact journey starts here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: EcoColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your first daily action to see your progress bloom. '
            'Every small choice contributes to a greener planet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: EcoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGoToDashboard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Go to Dashboard',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOverview extends StatelessWidget {
  final List<double> weeklyHeights;

  const _ActiveOverview({required this.weeklyHeights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact Overview',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EcoColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a metric above to explore category trends and recent contributions.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: EcoColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewChip(
                icon: Icons.trending_up_rounded,
                label: 'Best day: Wed',
              ),
              const SizedBox(width: 10),
              _OverviewChip(
                icon: Icons.eco_rounded,
                label: '4 actions logged',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OverviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: EcoColors.primaryFixed.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: EcoColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: EcoColors.onPrimaryFixedVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivitySection extends StatelessWidget {
  final List<double> weeklyHeights;
  final bool highlightPeak;

  const _WeeklyActivitySection({
    required this.weeklyHeights,
    required this.highlightPeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Activity',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EcoColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartHeight = (constraints.maxWidth * 0.28)
                      .clamp(72.0, 120.0);
                  return SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final h = weeklyHeights[i].clamp(0.05, 1.0);
                    final isPeak = highlightPeak &&
                        h == weeklyHeights.reduce((a, b) => a > b ? a : b);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: chartHeight * h,
                          decoration: BoxDecoration(
                            color: isPeak
                                ? EcoColors.primary
                                : EcoColors.surfaceVariant
                                    .withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            boxShadow: isPeak
                                ? const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: progressWeekdayLabels
                    .map(
                      (d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: EcoColors.outline,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
