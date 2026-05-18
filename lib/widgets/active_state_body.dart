import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database_service.dart';
import '../models/dashboard_state.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ActiveStateBody extends StatelessWidget {
  final DashboardState state;
  final bool showCelebration;
  final VoidCallback? onDismissCelebration;
  final bool embedInParentScroll;

  const ActiveStateBody({
    super.key,
    required this.state,
    this.showCelebration = false,
    this.onDismissCelebration,
    this.embedInParentScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final children = <Widget>[
      // Block 1: Streak + Impact — live Firestore user doc
      StreamBuilder(
        stream: FirestoreService.instance.getUserStream(uid),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final streak = data?['currentStreak'] as int? ?? state.dayStreak;
          final co2 = (data?['co2Saved'] as num?)?.toDouble() ?? state.kgSaved;
          final pct = data?['changePercent'] as int? ?? 12;
          return _HeroStatsRow(
            state: state.copyWith(dayStreak: streak, kgSaved: co2),
            changePercent: pct,
          );
        },
      ),
      const SizedBox(height: 16),
      // Block 2: Daily habit / points — live tasksCompleted
      StreamBuilder(
        stream: FirestoreService.instance.getUserStream(uid),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final pts = data?['tasksCompleted'] as int? ?? state.points;
          return _CompletedActionCard(
            points: pts * 10,
            showCelebration: showCelebration,
            onContinue: onDismissCelebration,
          );
        },
      ),
      const SizedBox(height: 16),
      // Block 3: Did you know + Weekly Goal — live Firestore tip + SQLite weekly
      _LiveInsightsBento(userId: uid),
      const SizedBox(height: 24),
      // Block 4: Your Journey — live SQLite logs
      _LiveJourneySection(userId: uid),
    ];

    if (embedInParentScroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero Stats Row
// ─────────────────────────────────────────────────────────
class _HeroStatsRow extends StatelessWidget {
  final DashboardState state;
  final int changePercent;

  const _HeroStatsRow({required this.state, this.changePercent = 12});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StreakCard(
              userName: state.userName,
              streak: state.dayStreak,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ImpactCard(
              kgSaved: state.kgSaved,
              changePercent: changePercent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String userName;
  final int streak;

  const _StreakCard({required this.userName, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background fire icon
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 80,
              color: EcoColors.onPrimaryContainer.withOpacity(0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great job, $userName!',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: EcoColors.onPrimaryContainer,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You've completed all tasks for today.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: EcoColors.onPrimaryContainer.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: EcoColors.onPrimaryContainer,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    'DAY STREAK',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: EcoColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final double kgSaved;
  final int changePercent;

  const _ImpactCard({required this.kgSaved, this.changePercent = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.co2_rounded,
                      color: EcoColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Impact Saved',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: EcoColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This month vs. last month',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: EcoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: kgSaved.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: EcoColors.primary,
                            letterSpacing: -1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'kg',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: EcoColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: EcoColors.primaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_down_rounded,
                        size: 13, color: EcoColors.primary),
                    Text(
                      '12%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.primary,
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

// ─────────────────────────────────────────────────────────
// Completed Action Card
// ─────────────────────────────────────────────────────────
class _CompletedActionCard extends StatelessWidget {
  final int points;
  final bool showCelebration;
  final VoidCallback? onContinue;

  const _CompletedActionCard({
    required this.points,
    this.showCelebration = false,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCelebration) {
      return _CompactCompletedCard(points: points, onContinue: onContinue);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EcoColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EcoColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'DAILY HABIT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: EcoColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today, Oct 24',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Switch to Cold Water Laundry',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: EcoColors.onSurface,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Heating water consumes 90% of energy in a laundry cycle. By switching to cold, you save 0.5kg of CO₂ today.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: EcoColors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              // Completed UI
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcoColors.primaryContainer,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: EcoColors.onPrimaryContainer,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Action Completed!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: EcoColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Continue to Dashboard',
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
        ),
        // +Points badge
        Positioned(
          top: -10,
          right: -4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: EcoColors.tertiary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+$points Points',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: EcoColors.onTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactCompletedCard extends StatelessWidget {
  final int points;
  final VoidCallback? onContinue;

  const _CompactCompletedCard({
    required this.points,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: EcoColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily habit complete',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: EcoColors.onSurface,
                  ),
                ),
                Text(
                  '+$points points earned today',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: EcoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onContinue != null)
            TextButton(
              onPressed: onContinue,
              child: Text(
                'View all',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: EcoColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Live Insights Bento — Firestore tip + SQLite weekly goal
// ─────────────────────────────────────────────────────────
class _LiveInsightsBento extends StatefulWidget {
  final String userId;
  const _LiveInsightsBento({required this.userId});

  @override
  State<_LiveInsightsBento> createState() => _LiveInsightsBentoState();
}

class _LiveInsightsBentoState extends State<_LiveInsightsBento> {
  late Future<_InsightData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InsightData> _load() async {
    final tips = await FirestoreService.instance
        .getContentWithFallback('energy_tips');
    String tip = 'LED bulbs use 75% less energy and last 25× longer than incandescent lighting.';
    if (tips.isNotEmpty) {
      final pick = tips[Random().nextInt(tips.length)];
      tip = pick['summary'] as String? ?? tip;
    }
    final weekly = await DatabaseService.instance
        .getWeeklyActivity(widget.userId);
    final done = weekly.where((d) => d == 1).length;
    final total = weekly.where((d) => d != -1).length;
    final pct = total > 0 ? done / total : 0.0;
    final daysLeft = weekly.where((d) => d == -1).length;
    return _InsightData(tip: tip, weeklyGoal: pct, daysLeft: daysLeft);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InsightData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return _InsightsBento(
          weeklyGoal: data?.weeklyGoal ?? 0.0,
          tip: data?.tip ?? 'LED bulbs use 75% less energy and last 25× longer than incandescent lighting.',
          daysLeft: data?.daysLeft ?? 0,
        );
      },
    );
  }
}

class _InsightData {
  final String tip;
  final double weeklyGoal;
  final int daysLeft;
  const _InsightData({required this.tip, required this.weeklyGoal, required this.daysLeft});
}

class _InsightsBento extends StatelessWidget {
  final double weeklyGoal;
  final String tip;
  final int daysLeft;

  const _InsightsBento({required this.weeklyGoal, required this.tip, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tip card (wider)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EcoColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EcoColors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EcoColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: EcoColors.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Did you know?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: EcoColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: EcoColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Weekly goal card (narrower)
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EcoColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WEEKLY\nGOAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: EcoColors.onSecondaryContainer.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${(weeklyGoal * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: weeklyGoal,
                    minHeight: 8,
                    backgroundColor: EcoColors.surfaceContainerLowest,
                    valueColor: const AlwaysStoppedAnimation(EcoColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  daysLeft > 0
                      ? '$daysLeft more day${daysLeft == 1 ? '' : 's'} to go!'
                      : 'Weekly goal complete! 🎉',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EcoColors.onSecondaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Live Your Journey — SQLite carbon_log + waste_log
// ─────────────────────────────────────────────────────────
class _LiveJourneySection extends StatefulWidget {
  final String userId;
  const _LiveJourneySection({required this.userId});

  @override
  State<_LiveJourneySection> createState() => _LiveJourneySectionState();
}

class _LiveJourneySectionState extends State<_LiveJourneySection> {
  late Future<List<JourneyActivity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<JourneyActivity>> _load() async {
    return DatabaseService.instance.getRecentActivities(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JourneyActivity>>(
      future: _future,
      builder: (context, snapshot) {
        final activities = snapshot.data ?? const [];
        return _YourJourneySection(activities: activities);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Your Journey Section
// ─────────────────────────────────────────────────────────
class _YourJourneySection extends StatelessWidget {
  final List<JourneyActivity> activities;

  const _YourJourneySection({required this.activities});

  static const _iconMap = <String, IconData>{
    'pedal_bike': Icons.pedal_bike_rounded,
    'compost': Icons.compost_rounded,
    'eco': Icons.eco_rounded,
    'directions_walk': Icons.directions_walk_rounded,
    'restaurant': Icons.restaurant_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Journey',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityTile(
              activity: activity,
              icon: _iconMap[activity.iconName] ?? Icons.eco_rounded,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final JourneyActivity activity;
  final IconData icon;

  const _ActivityTile({required this.activity, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerHigh,
            ),
            child: Icon(icon, color: EcoColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: EcoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: EcoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: EcoColors.primaryContainer,
            size: 22,
          ),
        ],
      ),
    );
  }
}
