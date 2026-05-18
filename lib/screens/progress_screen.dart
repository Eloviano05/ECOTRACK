import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../database_service.dart';
import '../models/progress_state.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences.dart';
import '../theme/app_theme.dart';
import 'challenges_screen.dart';
import 'progress_category_detail_screen.dart';

/// A dynamic progress dashboard bound directly to Firestore SSOT and SQLite logs.
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
    final weeklyHeights =
        isEmpty ? List.filled(7, 0.05) : activeWeeklyHeights;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    Widget buildBody({
      required int tasksCompleted,
      required int currentStreak,
      required Map<String, dynamic>? userData,
    }) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ChallengesBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChallengesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _ImpactCards(
              userData: userData,
              isEmpty: isEmpty,
              onMetricTap: isEmpty
                  ? null
                  : (metric) => _openCategory(context, metric.type),
            ),
            const SizedBox(height: 24),
            if (isEmpty)
              _EmptyStateHero(onGoToDashboard: onGoToDashboard)
            else
              _ActiveOverview(
                weeklyHeights: weeklyHeights,
                tasksCompleted: tasksCompleted,
                currentStreak: currentStreak,
              ),
            const SizedBox(height: 32),
            _WeeklyActivitySection(
              userId: userId,
              weeklyHeights: weeklyHeights,
              highlightPeak: !isEmpty,
            ),
          ],
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: EcoColors.background,
        appBar: const _ProgressAppBar(),
        body: buildBody(tasksCompleted: 0, currentStreak: 0, userData: null),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: EcoColors.background,
            appBar: _ProgressAppBar(),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            ),
          );
        }

        final tasksCompleted = FirestoreService.tasksCompletedFromSnapshot(
          snapshot.data,
        );
        final currentStreak = FirestoreService.currentStreakFromSnapshot(
          snapshot.data,
        );
        final userData = snapshot.data?.data();

        return Scaffold(
          backgroundColor: EcoColors.background,
          appBar: const _ProgressAppBar(),
          body: buildBody(
            tasksCompleted: tasksCompleted,
            currentStreak: currentStreak,
            userData: userData,
          ),
        );
      },
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

class _ChallengesBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ChallengesBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EcoColors.primary.withValues(alpha: 0.12),
              EcoColors.secondaryContainer.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: EcoColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: EcoColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: EcoColors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Sustainability Challenges',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join Plastic-Free Week & more',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: EcoColors.primary,
              ),
            ],
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
          ValueListenableBuilder<String>(
            valueListenable: UserPreferences.instance.avatarPath,
            builder: (context, avatarPath, _) {
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcoColors.secondaryContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarPath.isEmpty
                    ? (FirebaseAuth.instance.currentUser?.photoURL != null
                        ? Image.network(
                            FirebaseAuth.instance.currentUser!.photoURL!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 18,
                            color: EcoColors.secondary,
                          ))
                    : Image.file(
                        File(avatarPath),
                        fit: BoxFit.cover,
                      ),
              );
            },
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

class _ImpactCards extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isEmpty;
  final void Function(ProgressMetric)? onMetricTap;

  const _ImpactCards({
    required this.userData,
    required this.isEmpty,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final co2Saved = (userData?['co2Saved'] as num?)?.toDouble() ?? 0.0;
    final waterSaved = (userData?['waterSaved'] as num?)?.toDouble() ?? 0.0;
    final energySaved = (userData?['energySaved'] as num?)?.toDouble() ?? 0.0;
    final tasksDone = (userData?['tasksCompleted'] as num?)?.toInt() ?? 0;

    final impactMetrics = [
      _ImpactMetric(
        label: 'CO₂ Reduced',
        value: '~${co2Saved.toStringAsFixed(1)} kg',
        icon: Icons.cloud_rounded,
        iconColor: EcoColors.primary,
        type: ProgressCategoryType.co2,
        isTappable: true,
      ),
      _ImpactMetric(
        label: 'Water Saved',
        value: '~${waterSaved.toStringAsFixed(1)} L',
        icon: Icons.water_drop_rounded,
        iconColor: Colors.blue,
        type: ProgressCategoryType.water,
        isTappable: true,
      ),
      _ImpactMetric(
        label: 'Energy Saved',
        value: '~${energySaved.toStringAsFixed(1)} kWh',
        icon: Icons.bolt_rounded,
        iconColor: Colors.amber,
        type: ProgressCategoryType.energy,
        isTappable: true,
      ),
      _ImpactMetric(
        label: 'Tasks Done',
        value: '$tasksDone',
        icon: Icons.check_circle_rounded,
        iconColor: EcoColors.secondary,
        type: ProgressCategoryType.trees,
        isTappable: false,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: impactMetrics.map((m) {
        return _ImpactCard(
          metric: m,
          onTap: !isEmpty && m.isTappable && onMetricTap != null
              ? () => onMetricTap!(ProgressMetric(
                    type: m.type,
                    label: m.label,
                    value: m.value,
                    icon: m.icon,
                    iconColor: m.iconColor,
                    isTappable: true,
                  ))
              : null,
        );
      }).toList(),
    );
  }
}

class _ImpactMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final ProgressCategoryType type;
  final bool isTappable;

  _ImpactMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.type,
    this.isTappable = false,
  });
}

class _ImpactCard extends StatelessWidget {
  final _ImpactMetric metric;
  final VoidCallback? onTap;

  const _ImpactCard({required this.metric, this.onTap});

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
  final int tasksCompleted;
  final int currentStreak;

  const _ActiveOverview({
    required this.weeklyHeights,
    required this.tasksCompleted,
    required this.currentStreak,
  });

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
                icon: Icons.local_fire_department_rounded,
                label: 'Current Streak: $currentStreak',
              ),
              const SizedBox(width: 10),
              _OverviewChip(
                icon: Icons.check_circle_rounded,
                label: 'Tasks Completed: $tasksCompleted',
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
  final String? userId;
  final List<double> weeklyHeights;
  final bool highlightPeak;

  const _WeeklyActivitySection({
    required this.userId,
    required this.weeklyHeights,
    required this.highlightPeak,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _WeeklyActivityPlaceholder(
        weeklyHeights: weeklyHeights,
        highlightPeak: highlightPeak,
      );
    }

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
        FutureBuilder<List<int>>(
          future: DatabaseService.instance.getWeeklyActivity(userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _WeeklyActivityPlaceholder(
                weeklyHeights: weeklyHeights,
                highlightPeak: highlightPeak,
              );
            }

            if (snapshot.hasError) {
              return _WeeklyActivityPlaceholder(
                weeklyHeights: weeklyHeights,
                highlightPeak: highlightPeak,
              );
            }

            final weeklyActivity = snapshot.data ?? List.filled(7, 0);
            final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EcoColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EcoColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final status = weeklyActivity[index];
                  final dayLabel = dayLabels[index];
                  return _DayStatusIndicator(
                    status: status,
                    dayLabel: dayLabel,
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeeklyActivityPlaceholder extends StatelessWidget {
  final List<double> weeklyHeights;
  final bool highlightPeak;

  const _WeeklyActivityPlaceholder({
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

class _DayStatusIndicator extends StatelessWidget {
  final int status;
  final String dayLabel;

  const _DayStatusIndicator({
    required this.status,
    required this.dayLabel,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (status) {
      case 1: // Completed
        icon = Icons.check_circle_rounded;
        iconColor = EcoColors.primary;
        bgColor = EcoColors.primaryFixed.withValues(alpha: 0.2);
        break;
      case 0: // Missed
        icon = Icons.close_rounded;
        iconColor = EcoColors.outline;
        bgColor = EcoColors.surfaceContainer;
        break;
      case -1: // Future
      default:
        icon = Icons.remove_rounded;
        iconColor = EcoColors.outline.withValues(alpha: 0.5);
        bgColor = EcoColors.surfaceContainerLow;
        break;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dayLabel,
          style: GoogleFonts.publicSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
