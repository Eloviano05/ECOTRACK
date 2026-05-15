import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

enum _AchievementType { tasks, streak }

class _LogicAchievement {
  const _LogicAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.threshold,
    required this.type,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int threshold;
  final _AchievementType type;

  bool isUnlocked(int tasksCompleted, int currentStreak) {
    switch (type) {
      case _AchievementType.tasks:
        return tasksCompleted >= threshold;
      case _AchievementType.streak:
        return currentStreak >= threshold;
    }
  }
}

const _achievements = [
  _LogicAchievement(
    id: 'starter',
    title: 'Starter',
    description: 'Complete your first eco task',
    icon: Icons.eco_rounded,
    threshold: 1,
    type: _AchievementType.tasks,
  ),
  _LogicAchievement(
    id: 'eco_saver',
    title: 'Eco Saver',
    description: 'Complete 10 sustainable actions',
    icon: Icons.energy_savings_leaf_rounded,
    threshold: 10,
    type: _AchievementType.tasks,
  ),
  _LogicAchievement(
    id: 'green_champion',
    title: 'Green Champion',
    description: 'Complete 25 eco tasks',
    icon: Icons.military_tech_rounded,
    threshold: 25,
    type: _AchievementType.tasks,
  ),
  _LogicAchievement(
    id: 'streak_starter',
    title: 'On a Roll',
    description: 'Maintain a 3-day streak',
    icon: Icons.local_fire_department_rounded,
    threshold: 3,
    type: _AchievementType.streak,
  ),
  _LogicAchievement(
    id: 'streak_master',
    title: 'Streak Master',
    description: 'Maintain a 5-day streak',
    icon: Icons.whatshot_rounded,
    threshold: 5,
    type: _AchievementType.streak,
  ),
  _LogicAchievement(
    id: 'planet_guardian',
    title: 'Planet Guardian',
    description: 'Maintain a 7-day streak',
    icon: Icons.public_rounded,
    threshold: 7,
    type: _AchievementType.streak,
  ),
];

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: EcoColors.onSurface),
        ),
        title: Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: userId == null
            ? Center(
                child: Text(
                  'Sign in to track your achievements.',
                  style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
                ),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.instance.getUserStream(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: EcoColors.primary,
                      ),
                    );
                  }

                  final tasksCompleted =
                      FirestoreService.tasksCompletedFromSnapshot(
                    snapshot.data,
                  );
                  final currentStreak =
                      FirestoreService.currentStreakFromSnapshot(
                    snapshot.data,
                  );

                  final unlockedCount = _achievements
                      .where(
                        (a) => a.isUnlocked(tasksCompleted, currentStreak),
                      )
                      .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: EcoColors.primaryContainer
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: EcoColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: EcoColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: EcoColors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$unlockedCount of ${_achievements.length} unlocked',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: EcoColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$tasksCompleted tasks · $currentStreak-day streak',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: EcoColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._achievements.map(
                        (achievement) {
                          final unlocked = achievement.isUnlocked(
                            tasksCompleted,
                            currentStreak,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AchievementBadge(
                              achievement: achievement,
                              unlocked: unlocked,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.achievement,
    required this.unlocked,
  });

  final _LogicAchievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final iconBg = unlocked
        ? EcoColors.primaryFixed.withValues(alpha: 0.55)
        : EcoColors.surfaceVariant.withValues(alpha: 0.45);
    final iconColor =
        unlocked ? EcoColors.primary : EcoColors.onSurfaceVariant;
    final titleColor =
        unlocked ? EcoColors.onSurface : EcoColors.onSurfaceVariant;
    final borderColor = unlocked
        ? EcoColors.primary.withValues(alpha: 0.35)
        : EcoColors.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? EcoColors.surfaceContainerLowest
            : EcoColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: unlocked
            ? const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_outline_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: EcoColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unlocked ? 'Unlocked' : 'Locked',
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: unlocked ? EcoColors.primary : EcoColors.outline,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: EcoColors.primary,
              size: 26,
            ),
        ],
      ),
    );
  }
}
