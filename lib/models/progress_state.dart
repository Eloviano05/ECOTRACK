import 'package:flutter/material.dart';

enum ProgressCategoryType { co2, water, energy, trees }

class ProgressMetric {
  final ProgressCategoryType type;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isTappable;

  const ProgressMetric({
    required this.type,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isTappable = false,
  });
}

class ProgressContribution {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;

  const ProgressContribution({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });
}

class ProgressCategoryDetail {
  final ProgressCategoryType type;
  final String title;
  final String heroLabel;
  final String heroValue;
  final String heroSubtitle;
  final String trendLabel;
  final double avgPerDay;
  final String avgUnit;
  final List<double> weeklyHeights;
  final List<ProgressContribution> contributions;
  final String tipTitle;
  final String tipCta;
  final IconData heroIcon;

  const ProgressCategoryDetail({
    required this.type,
    required this.title,
    required this.heroLabel,
    required this.heroValue,
    required this.heroSubtitle,
    required this.trendLabel,
    required this.avgPerDay,
    required this.avgUnit,
    required this.weeklyHeights,
    required this.contributions,
    required this.tipTitle,
    required this.tipCta,
    required this.heroIcon,
  });
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

List<String> get progressWeekdayLabels => _weekdays;

/// Empty progress tab — matches ecotrack_progress_starting_state.
final emptyProgressMetrics = [
  ProgressMetric(
    type: ProgressCategoryType.co2,
    label: 'CO2 Saved',
    value: '0 kg',
    icon: Icons.eco_rounded,
    iconColor: Color(0xFF006E1C),
  ),
  ProgressMetric(
    type: ProgressCategoryType.water,
    label: 'Water Conserved',
    value: '0 L',
    icon: Icons.water_drop_rounded,
    iconColor: Color(0xFFA63360),
  ),
  ProgressMetric(
    type: ProgressCategoryType.energy,
    label: 'Energy Offset',
    value: '---',
    icon: Icons.bolt_rounded,
    iconColor: Color(0xFF42673F),
  ),
  ProgressMetric(
    type: ProgressCategoryType.trees,
    label: 'Trees Planted',
    value: '0',
    icon: Icons.forest_rounded,
    iconColor: Color(0xFF4CAF50),
  ),
];

/// Active progress tab — metric cards link to category detail screens.
final activeProgressMetrics = [
  ProgressMetric(
    type: ProgressCategoryType.co2,
    label: 'CO2 Saved',
    value: '4.2 kg',
    icon: Icons.eco_rounded,
    iconColor: Color(0xFF006E1C),
    isTappable: true,
  ),
  ProgressMetric(
    type: ProgressCategoryType.water,
    label: 'Water Conserved',
    value: '150 L',
    icon: Icons.water_drop_rounded,
    iconColor: Color(0xFFA63360),
    isTappable: true,
  ),
  ProgressMetric(
    type: ProgressCategoryType.energy,
    label: 'Energy Offset',
    value: '12 kWh',
    icon: Icons.bolt_rounded,
    iconColor: Color(0xFF42673F),
    isTappable: true,
  ),
  ProgressMetric(
    type: ProgressCategoryType.trees,
    label: 'Trees Planted',
    value: '2',
    icon: Icons.forest_rounded,
    iconColor: Color(0xFF4CAF50),
    isTappable: true,
  ),
];

final activeWeeklyHeights = [0.15, 0.25, 0.85, 0.35, 0.55, 0.20, 0.30];

ProgressCategoryDetail detailForCategory(ProgressCategoryType type) {
  switch (type) {
    case ProgressCategoryType.water:
      return waterImpactDetail;
    case ProgressCategoryType.co2:
      return co2ImpactDetail;
    case ProgressCategoryType.energy:
      return energyImpactDetail;
    case ProgressCategoryType.trees:
      return treesImpactDetail;
  }
}

/// Matches ecotrack_progress_category_detail (Water Impact).
const waterImpactDetail = ProgressCategoryDetail(
  type: ProgressCategoryType.water,
  title: 'Water Impact',
  heroLabel: 'Total Volume Saved',
  heroValue: '150L Saved',
  heroSubtitle: 'Equates to 3 average showers',
  trendLabel: '+12% vs last week',
  avgPerDay: 21.4,
  avgUnit: 'L',
  weeklyHeights: [0.43, 0.71, 1.0, 0.57, 0.86, 0.36, 0.50],
  heroIcon: Icons.water_drop_rounded,
  contributions: [
    ProgressContribution(
      title: 'Short shower (5 min)',
      subtitle: '2 hours ago · Efficient habit',
      amount: '+25L',
      icon: Icons.shower_rounded,
    ),
    ProgressContribution(
      title: 'Full dishwasher load',
      subtitle: 'Today, 9:15 AM · Optimization',
      amount: '+40L',
      icon: Icons.flatware_rounded,
    ),
    ProgressContribution(
      title: 'Rainwater collection',
      subtitle: 'Yesterday · Outdoor use',
      amount: '+15L',
      icon: Icons.eco_rounded,
    ),
  ],
  tipTitle:
      'Did you know that fixing a leaky faucet can save up to 11,000 liters a year?',
  tipCta: 'Check for Leaks',
);

const co2ImpactDetail = ProgressCategoryDetail(
  type: ProgressCategoryType.co2,
  title: 'CO₂ Impact',
  heroLabel: 'Total Carbon Saved',
  heroValue: '4.2kg Saved',
  heroSubtitle: 'Equivalent to 18 km not driven',
  trendLabel: '+8% vs last week',
  avgPerDay: 0.6,
  avgUnit: 'kg',
  weeklyHeights: [0.5, 0.65, 0.9, 0.4, 0.75, 0.55, 0.7],
  heroIcon: Icons.eco_rounded,
  contributions: [
    ProgressContribution(
      title: 'Biked to Work',
      subtitle: 'Yesterday · Transport',
      amount: '+1.2kg',
      icon: Icons.pedal_bike_rounded,
    ),
    ProgressContribution(
      title: 'Composted Organic Waste',
      subtitle: 'Tuesday · Waste reduction',
      amount: '+0.3kg',
      icon: Icons.compost,
    ),
    ProgressContribution(
      title: 'Meat-free lunch',
      subtitle: 'Monday · Diet choice',
      amount: '+0.8kg',
      icon: Icons.restaurant_rounded,
    ),
  ],
  tipTitle: 'Switching off standby power can cut home emissions by up to 10%.',
  tipCta: 'Audit Standby',
);

const energyImpactDetail = ProgressCategoryDetail(
  type: ProgressCategoryType.energy,
  title: 'Energy Impact',
  heroLabel: 'Total Energy Offset',
  heroValue: '12kWh Saved',
  heroSubtitle: 'Powers a fridge for about 4 days',
  trendLabel: '+5% vs last week',
  avgPerDay: 1.7,
  avgUnit: 'kWh',
  weeklyHeights: [0.3, 0.45, 0.8, 0.5, 0.6, 0.35, 0.55],
  heroIcon: Icons.bolt_rounded,
  contributions: [
    ProgressContribution(
      title: 'Unplugged idle devices',
      subtitle: 'Today · Home office',
      amount: '+3kWh',
      icon: Icons.power_off_rounded,
    ),
    ProgressContribution(
      title: 'LED bulb swap',
      subtitle: 'Yesterday · Lighting',
      amount: '+2kWh',
      icon: Icons.lightbulb_rounded,
    ),
    ProgressContribution(
      title: 'Cold wash laundry',
      subtitle: 'Sunday · Appliances',
      amount: '+1.5kWh',
      icon: Icons.local_laundry_service_rounded,
    ),
  ],
  tipTitle: 'Air-drying clothes once a week saves roughly 200 kWh per year.',
  tipCta: 'Try Air Dry',
);

const treesImpactDetail = ProgressCategoryDetail(
  type: ProgressCategoryType.trees,
  title: 'Trees Planted',
  heroLabel: 'Total Trees Supported',
  heroValue: '2 Trees',
  heroSubtitle: 'Absorbing ~40kg CO₂ per year',
  trendLabel: '+1 this month',
  avgPerDay: 0.3,
  avgUnit: 'trees',
  weeklyHeights: [0.0, 0.0, 1.0, 0.0, 0.0, 0.5, 0.0],
  heroIcon: Icons.forest_rounded,
  contributions: [
    ProgressContribution(
      title: 'Mangrove restoration',
      subtitle: 'Last week · Coastal project',
      amount: '+1',
      icon: Icons.park_rounded,
    ),
    ProgressContribution(
      title: 'Community orchard',
      subtitle: 'This month · Local initiative',
      amount: '+1',
      icon: Icons.nature_people_rounded,
    ),
  ],
  tipTitle: 'One mature tree can absorb about 22 kg of CO₂ each year.',
  tipCta: 'Plant Another',
);
