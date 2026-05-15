class DashboardState {
  final bool isFirstTime;
  final String userName;
  final int dayStreak;
  final double kgSaved;
  final bool todayActionCompleted;
  final int points;
  final double weeklyGoalPercent;
  final List<JourneyActivity> recentActivities;

  const DashboardState({
    required this.isFirstTime,
    this.userName = 'Alex',
    this.dayStreak = 0,
    this.kgSaved = 0.0,
    this.todayActionCompleted = false,
    this.points = 0,
    this.weeklyGoalPercent = 0.0,
    this.recentActivities = const [],
  });

  DashboardState copyWith({
    bool? isFirstTime,
    String? userName,
    int? dayStreak,
    double? kgSaved,
    bool? todayActionCompleted,
    int? points,
    double? weeklyGoalPercent,
    List<JourneyActivity>? recentActivities,
  }) {
    return DashboardState(
      isFirstTime: isFirstTime ?? this.isFirstTime,
      userName: userName ?? this.userName,
      dayStreak: dayStreak ?? this.dayStreak,
      kgSaved: kgSaved ?? this.kgSaved,
      todayActionCompleted: todayActionCompleted ?? this.todayActionCompleted,
      points: points ?? this.points,
      weeklyGoalPercent: weeklyGoalPercent ?? this.weeklyGoalPercent,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}

class JourneyActivity {
  final String title;
  final String subtitle;
  final String iconName;

  const JourneyActivity({
    required this.title,
    required this.subtitle,
    required this.iconName,
  });
}

/// Sample data for the active/returning user state
final activeUserState = DashboardState(
  isFirstTime: false,
  userName: 'Alex',
  dayStreak: 12,
  kgSaved: 4.2,
  todayActionCompleted: false,
  points: 10,
  weeklyGoalPercent: 0.85,
  recentActivities: const [
    JourneyActivity(
      title: 'Biked to Work',
      subtitle: 'Yesterday · Saved 1.2kg CO₂',
      iconName: 'pedal_bike',
    ),
    JourneyActivity(
      title: 'Composted Organic Waste',
      subtitle: 'Tuesday · Saved 0.3kg CO₂',
      iconName: 'compost',
    ),
  ],
);

/// Sample data for first-time / empty state
final emptyUserState = DashboardState(
  isFirstTime: true,
  userName: '',
  dayStreak: 0,
  kgSaved: 0.0,
  todayActionCompleted: false,
  weeklyGoalPercent: 0.0,
  recentActivities: const [],
);
