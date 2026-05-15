import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../firestore_service.dart';
import '../models/eco_tip.dart';
import '../theme/app_theme.dart';
import 'meal_plan_screen.dart';
import 'tip_detail_screen.dart';
import 'tips_search_screen.dart';

/// UI filter chip → Firestore `category` field (or `all` for no filter).
class _ContentFilter {
  const _ContentFilter({required this.label, required this.firestoreCategory});

  final String label;
  final String firestoreCategory;
}

const _contentFilters = [
  _ContentFilter(label: 'All', firestoreCategory: 'all'),
  _ContentFilter(label: 'Products', firestoreCategory: 'products'),
  _ContentFilter(label: 'Certifications', firestoreCategory: 'certifications'),
  _ContentFilter(label: 'Energy', firestoreCategory: 'energy_tips'),
  _ContentFilter(label: 'Travel', firestoreCategory: 'travel'),
];

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String _selectedCategory = 'all';
  late Future<List<Map<String, dynamic>>> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture =
        FirestoreService.instance.getEducationalContent(_selectedCategory);
    _seedAndRefresh();
  }

  Future<void> _seedAndRefresh() async {
    await FirestoreService.instance.seedFirestoreData();
    if (!mounted) return;
    _reloadContent();
  }

  void _reloadContent() {
    setState(() {
      _contentFuture = FirestoreService.instance
          .getEducationalContent(_selectedCategory);
    });
  }

  void _onFilterSelected(String firestoreCategory) {
    if (_selectedCategory == firestoreCategory) return;
    setState(() => _selectedCategory = firestoreCategory);
    _reloadContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _TipsAppBar(onSearchTap: _openSearch),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SearchBarTile(onTap: _openSearch),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _contentFilters.map((filter) {
                  final active = filter.firestoreCategory == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _FilterChip(
                      label: filter.label,
                      active: active,
                      onTap: () => _onFilterSelected(filter.firestoreCategory),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [EcoColors.primary, EcoColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: EcoColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: EcoColors.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sustainable Meal Planner',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: EcoColors.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plan low-carbon meals for the week',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color:
                                    EcoColors.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: EcoColors.onPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey<String>(_selectedCategory),
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: EcoColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ContentMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load content',
                      subtitle: snapshot.error.toString(),
                      actionLabel: 'Retry',
                      onAction: _reloadContent,
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return _ContentMessage(
                      icon: Icons.eco_outlined,
                      title: 'No content yet',
                      subtitle:
                          'Try another category or check your Firestore connection.',
                      actionLabel: 'Refresh',
                      onAction: _reloadContent,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return _ContentCard(
                        title: item['title'] as String? ?? 'Untitled',
                        summary: item['summary'] as String? ?? '',
                        category: item['category'] as String? ?? '',
                        onTap: () => _openDetail(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TipsSearchScreen()),
    );
  }

  void _openDetail(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TipDetailScreen(tip: _ecoTipFromFirestore(data)),
      ),
    );
  }

  EcoTip _ecoTipFromFirestore(Map<String, dynamic> data) {
    final category = data['category'] as String? ?? 'general_education';
    final stepsRaw = data['steps'];
    final steps = <TipStep>[];
    if (stepsRaw is List) {
      for (final entry in stepsRaw) {
        if (entry is Map) {
          steps.add(
            TipStep(
              title: entry['title'] as String? ?? '',
              description: entry['description'] as String? ?? '',
            ),
          );
        }
      }
    }

    final (icon, iconBg, iconFg) = _iconForCategory(category);

    return EcoTip(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      summary: data['summary'] as String? ?? '',
      savingsLabel: data['savingsLabel'] as String? ?? 'Eco impact',
      category: _tipCategoryFromFirestore(category),
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      steps: steps.isEmpty
          ? [
              TipStep(
                title: 'Learn more',
                description: data['summary'] as String? ?? '',
              ),
            ]
          : steps,
      imageUrl: data['imageUrl'] as String? ??
          'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800&q=80',
    );
  }

  TipCategory _tipCategoryFromFirestore(String category) {
    switch (category) {
      case 'energy_tips':
        return TipCategory.energy;
      case 'travel':
        return TipCategory.mobility;
      case 'products':
        return TipCategory.food;
      case 'certifications':
      case 'general_education':
      default:
        return TipCategory.all;
    }
  }

}

class _ContentMessage extends StatelessWidget {
  const _ContentMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: EcoColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: EcoColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: EcoColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: EcoColors.primary,
                foregroundColor: EcoColors.onPrimary,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.summary,
    required this.category,
    required this.onTap,
  });

  final String title;
  final String summary;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = _iconForCategory(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EcoColors.surfaceContainer),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconFg, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: EcoColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EcoColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: EcoColors.outlineVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

(IconData, Color, Color) _iconForCategory(String category) {
  switch (category) {
    case 'products':
      return (
        Icons.shopping_bag_rounded,
        EcoColors.primaryContainer,
        EcoColors.onPrimaryContainer,
      );
    case 'certifications':
      return (
        Icons.verified_rounded,
        EcoColors.secondaryContainer,
        EcoColors.onSecondaryContainer,
      );
    case 'energy_tips':
      return (
        Icons.bolt_rounded,
        EcoColors.secondaryContainer,
        EcoColors.onSecondaryContainer,
      );
    case 'travel':
      return (
        Icons.directions_transit_rounded,
        EcoColors.tertiaryContainer,
        const Color(0xFF690034),
      );
    case 'general_education':
      return (
        Icons.menu_book_rounded,
        EcoColors.surfaceContainerHigh,
        EcoColors.onSurfaceVariant,
      );
    default:
      return (
        Icons.eco_rounded,
        EcoColors.primaryContainer,
        EcoColors.onPrimaryContainer,
      );
  }
}

// ─────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────
class _TipsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  const _TipsAppBar({required this.onSearchTap});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: IconButton(
        onPressed: onSearchTap,
        icon: const Icon(Icons.search_rounded, color: EcoColors.onSurfaceVariant),
      ),
      title: Text(
        'EcoTrack',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: EcoColors.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.filter_list_rounded,
              color: EcoColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SearchBarTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: EcoColors.onSurfaceVariant, size: 22),
            const SizedBox(width: 10),
            Text(
              'Search tips...',
              style: GoogleFonts.inter(
                color: EcoColors.outline,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? EcoColors.primary : EcoColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: active
              ? null
              : Border.all(color: EcoColors.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? EcoColors.onPrimary : EcoColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
