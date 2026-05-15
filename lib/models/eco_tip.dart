import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TipCategory { all, energy, food, water, mobility }

extension TipCategoryLabel on TipCategory {
  String get label {
    switch (this) {
      case TipCategory.all:      return 'All';
      case TipCategory.energy:   return 'Energy';
      case TipCategory.food:     return 'Food';
      case TipCategory.water:    return 'Water';
      case TipCategory.mobility: return 'Mobility';
    }
  }

  IconData get icon {
    switch (this) {
      case TipCategory.all:      return Icons.apps_rounded;
      case TipCategory.energy:   return Icons.bolt_rounded;
      case TipCategory.food:     return Icons.restaurant_rounded;
      case TipCategory.water:    return Icons.water_drop_rounded;
      case TipCategory.mobility: return Icons.pedal_bike_rounded;
    }
  }
}

class TipStep {
  final String title;
  final String description;
  final bool completed;

  const TipStep({
    required this.title,
    required this.description,
    this.completed = false,
  });
}

class EcoTip {
  final String id;
  final String title;
  final String summary;
  final String savingsLabel;
  final TipCategory category;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final List<TipStep> steps;
  final String imageUrl;

  const EcoTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.savingsLabel,
    required this.category,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.steps,
    required this.imageUrl,
  });
}

final List<EcoTip> kAllTips = [
  EcoTip(
    id: 'unplug',
    title: 'Unplug devices',
    summary: 'Save energy and reduce your carbon footprint by unplugging electronics when not in use.',
    savingsLabel: '~5kg CO₂/month',
    category: TipCategory.energy,
    icon: Icons.electrical_services_rounded,
    iconBg: EcoColors.secondaryContainer,
    iconFg: EcoColors.onSecondaryContainer,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
    steps: [
      TipStep(
        title: 'Unplug chargers after use',
        description: 'Phone and laptop chargers draw "vampire power" even when not connected to a device.',
        completed: true,
      ),
      TipStep(
        title: 'Use power strips',
        description: 'For entertainment centers, a single switch can cut power to multiple idle devices at once.',
      ),
      TipStep(
        title: 'Turn off standby mode',
        description: 'Kitchen appliances like microwaves and coffee makers consume unnecessary energy on standby.',
      ),
    ],
  ),
  EcoTip(
    id: 'showers',
    title: 'Shorter showers',
    summary: 'Reduce water consumption and water-heating energy by timing your showers.',
    savingsLabel: '~3kg CO₂/month',
    category: TipCategory.water,
    icon: Icons.water_drop_rounded,
    iconBg: EcoColors.tertiaryContainer,
    iconFg: Color(0xFF690034),
    imageUrl: 'https://images.unsplash.com/photo-1620626011761-996317702782?w=800&q=80',
    steps: [
      TipStep(
        title: 'Set a 5-minute timer',
        description: 'Use your phone or a waterproof timer to keep showers under 5 minutes.',
        completed: true,
      ),
      TipStep(
        title: 'Install a low-flow showerhead',
        description: 'Reduces flow by up to 60% without sacrificing pressure.',
      ),
      TipStep(
        title: 'Turn off water while soaping',
        description: 'Pause the water while lathering up — you can save gallons per shower.',
      ),
    ],
  ),
  EcoTip(
    id: 'compost',
    title: 'Compost kitchen scraps',
    summary: 'Turn your organic waste into nutrient-rich soil instead of sending it to landfill.',
    savingsLabel: '~2kg CO₂/month',
    category: TipCategory.food,
    icon: Icons.compost_rounded,
    iconBg: EcoColors.primaryContainer,
    iconFg: EcoColors.onPrimaryContainer,
    imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800&q=80',
    steps: [
      TipStep(
        title: 'Start a countertop bin',
        description: 'Keep a small sealed container on your counter for daily scraps like peels and coffee grounds.',
      ),
      TipStep(
        title: 'Learn what to compost',
        description: 'Fruit, veg, eggshells, and paper are great. Avoid meat and dairy in home bins.',
      ),
      TipStep(
        title: 'Use a local drop-off',
        description: 'No backyard? Many cities have community composting pick-up points.',
      ),
    ],
  ),
];
