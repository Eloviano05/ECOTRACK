import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../models/eco_tip.dart';
import '../theme/app_theme.dart';
import 'bookmarks_screen.dart';
import 'meal_plan_screen.dart';
import 'tip_detail_screen.dart';

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
  String _searchQuery = '';
  bool _sortAscending = true;
  late Future<List<Map<String, dynamic>>> _contentFuture;

  @override
  void initState() {
    super.initState();
    FirestoreService.instance.seedFirestoreData();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirestoreService.instance.syncUserDocument(user);
    }
    _reloadContent();
  }

  void _reloadContent() {
    setState(() {
      _contentFuture = FirestoreService.instance
          .getContentWithFallback(_selectedCategory);
    });
  }

  void _onFilterSelected(String firestoreCategory) {
    if (_selectedCategory == firestoreCategory) return;
    setState(() => _selectedCategory = firestoreCategory);
    _reloadContent();
  }

  void _toggleSort() {
    setState(() => _sortAscending = !_sortAscending);
  }

  List<Map<String, dynamic>> _filterAndSortItems(List<Map<String, dynamic>> items) {
    var filtered = items.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final summary = (item['summary'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || summary.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final titleA = (a['title'] as String? ?? '').toLowerCase();
      final titleB = (b['title'] as String? ?? '').toLowerCase();
      return _sortAscending ? titleA.compareTo(titleB) : titleB.compareTo(titleA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: EcoColors.background,
        appBar: _TipsAppBar(
          onBookmarkTap: () {},
          onSortTap: () {},
        ),
        body: const SafeArea(
          child: Center(
            child: Text('Sign in to save tips and sync your library.'),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(userId),
      builder: (context, userSnapshot) {
        final savedTips = FirestoreService.savedTipsFromSnapshot(
          userSnapshot.data,
        );

        return Scaffold(
          backgroundColor: EcoColors.background,
          appBar: _TipsAppBar(
            onBookmarkTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              );
            },
            onSortTap: _toggleSort,
          ),
          body: SafeArea(
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search tips...',
                  hintStyle: GoogleFonts.inter(
                    color: EcoColors.outline,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: EcoColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: EcoColors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
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
                  final filteredItems = _filterAndSortItems(items);
                  
                  if (filteredItems.isEmpty) {
                    return _ContentMessage(
                      icon: Icons.eco_outlined,
                      title: items.isEmpty ? 'No tips here yet' : 'No results found',
                      subtitle: items.isEmpty
                          ? 'We are growing our library. Try another category or pull to refresh in a moment.'
                          : 'Try adjusting your search or filter criteria.',
                      actionLabel: items.isEmpty ? 'Refresh' : 'Clear search',
                      onAction: items.isEmpty ? _reloadContent : () => setState(() => _searchQuery = ''),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final item = filteredItems[index];
                      final tipId = item['id'] as String? ?? '';
                      final isSaved = savedTips.contains(tipId);
                      return _ContentCard(
                        title: item['title'] as String? ?? 'Untitled',
                        summary: item['summary'] as String? ?? '',
                        category: item['category'] as String? ?? '',
                        imageUrl: item['imageUrl'] as String? ?? '',
                        isSaved: isSaved,
                        onBookmark: () {
                          FirestoreService.instance.toggleSaveTip(
                            userId,
                            tipId,
                            !isSaved,
                          );
                        },
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
      },
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
    required this.imageUrl,
    required this.isSaved,
    required this.onBookmark,
    required this.onTap,
  });

  final String title;
  final String summary;
  final String category;
  final String imageUrl;
  final bool isSaved;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = _iconForCategory(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.5)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Image at the top
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: EcoColors.secondaryContainer,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: EcoColors.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
            // White space content area below image
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: iconBg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: iconFg, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              category.toUpperCase(),
                              style: GoogleFonts.publicSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: iconFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Bookmark sits cleanly in white space
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: onBookmark,
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? EcoColors.primary : EcoColors.onSurfaceVariant,
                          size: 24,
                        ),
                        tooltip: isSaved ? 'Remove from saved' : 'Save tip',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: EcoColors.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
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
  final VoidCallback onBookmarkTap;
  final VoidCallback onSortTap;
  const _TipsAppBar({required this.onBookmarkTap, required this.onSortTap});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
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
          onPressed: onSortTap,
          icon: const Icon(Icons.sort_rounded,
              color: EcoColors.onSurfaceVariant),
          tooltip: 'Sort',
        ),
        IconButton(
          onPressed: onBookmarkTap,
          icon: const Icon(Icons.bookmark_rounded,
              color: EcoColors.onSurfaceVariant),
          tooltip: 'Saved Tips',
        ),
      ],
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
