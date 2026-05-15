import 'package:flutter/material.dart';

class UserProfile {
  final String displayName;
  final String email;
  final String goalTitle;
  final String goalSubtitle;
  final String? photoUrl;

  const UserProfile({
    required this.displayName,
    required this.email,
    required this.goalTitle,
    this.goalSubtitle = 'Small steps, big change',
    this.photoUrl,
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? goalTitle,
    String? goalSubtitle,
    String? photoUrl,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      goalTitle: goalTitle ?? this.goalTitle,
      goalSubtitle: goalSubtitle ?? this.goalSubtitle,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class AchievementRequirement {
  final String title;
  final String description;
  final String pointsLabel;
  final bool completed;
  final bool isNext;

  const AchievementRequirement({
    required this.title,
    required this.description,
    required this.pointsLabel,
    required this.completed,
    this.isNext = false,
  });
}

class Achievement {
  final String id;
  final String listTitle;
  final String detailTitle;
  final int level;
  final int progressCurrent;
  final int progressTotal;
  final String progressHint;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final List<AchievementRequirement> requirements;

  const Achievement({
    required this.id,
    required this.listTitle,
    required this.detailTitle,
    required this.level,
    required this.progressCurrent,
    required this.progressTotal,
    required this.progressHint,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.requirements,
  });

  double get progressFraction =>
      progressTotal == 0 ? 0 : progressCurrent / progressTotal;
}

const defaultUserProfile = UserProfile(
  displayName: 'Sarah',
  email: 'sarah@email.com',
  goalTitle: 'Become carbon neutral',
  goalSubtitle: 'Small steps, big change',
  photoUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDDVL4aKY-0VvlHxHRBvd1HmZ7uMeh2k59c_dYi1Kru0K1afV3EYNZ3JuqaDmKhwM0-J6KUXrhLaUQ9WumJt1p5T-a3kzOlxwh8t4KFr0VqbOTWO-7i_FcNiMDXW8odat1LDj7fgbPc5Ura8vXtd2GwdQhifmsK7swoxJ34VuDKP2TpwEWIzwu8_wbWGzwVWNkIT75GEQGFfpmYy0TR3k-KSIlwFjGYMXRsuZdQ2SZbXK-HheyjyDx7Kt-is-A3ao_bxChAz-xZuTI',
);

const kAchievements = [
  Achievement(
    id: 'energy_saver',
    listTitle: 'Energy Saver (Level 1)',
    detailTitle: 'Energy Saver',
    level: 1,
    progressCurrent: 4,
    progressTotal: 5,
    progressHint: 'Almost there! Complete one more action to level up.',
    icon: Icons.bolt_rounded,
    iconColor: Color(0xFF42673F),
    iconBgColor: Color(0x66C3EEBB),
    requirements: [
      AchievementRequirement(
        title: 'Unplug 5 inactive devices',
        description: 'Prevent phantom energy drain from devices not in use.',
        pointsLabel: '+10 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Air dry clothes once',
        description: 'Skip the dryer and use a drying rack or clothesline.',
        pointsLabel: '+15 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Wash full loads only',
        description:
            'Maximize efficiency for dishwasher or washing machine.',
        pointsLabel: '+10 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Adjust thermostat by 2°',
        description: 'Lower in winter, raise in summer to save energy.',
        pointsLabel: '+20 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Switch to LED bulbs',
        description: 'Replace at least 3 incandescent bulbs with LEDs.',
        pointsLabel: '+30 pts',
        completed: false,
        isNext: true,
      ),
    ],
  ),
  Achievement(
    id: 'first_7_days',
    listTitle: 'First 7 Days (Completed)',
    detailTitle: 'First 7 Days',
    level: 1,
    progressCurrent: 7,
    progressTotal: 7,
    progressHint: 'Achievement unlocked! You logged actions 7 days in a row.',
    icon: Icons.local_fire_department_rounded,
    iconColor: Color(0xFFA63360),
    iconBgColor: Color(0x4DF26F9D),
    requirements: [
      AchievementRequirement(
        title: 'Log your first action',
        description: 'Complete any eco action from the dashboard.',
        pointsLabel: '+5 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Maintain a 3-day streak',
        description: 'Check in three days in a row.',
        pointsLabel: '+10 pts',
        completed: true,
      ),
      AchievementRequirement(
        title: 'Reach a 7-day streak',
        description: 'Keep your momentum for a full week.',
        pointsLabel: '+25 pts',
        completed: true,
      ),
    ],
  ),
];

Achievement? achievementById(String id) {
  try {
    return kAchievements.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}
