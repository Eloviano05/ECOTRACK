import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/eco_tip.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'tip_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<Map<String, dynamic>>> _allContentFuture;

  @override
  void initState() {
    super.initState();
    _allContentFuture = FirestoreService.instance.getContentWithFallback('all');
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
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
            'Saved Tips',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: EcoColors.onSurface,
            ),
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Text('Sign in to view your saved tips.'),
          ),
        ),
      );
    }

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
          'Saved Tips',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.getUserStream(userId),
          builder: (context, userSnapshot) {
            final savedTips = FirestoreService.savedTipsFromSnapshot(
              userSnapshot.data,
            );

            if (savedTips.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: EcoColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved tips yet',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: EcoColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the bookmark icon on any tip to save it here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: EcoColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _allContentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EcoColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading tips: ${snapshot.error}',
                      style: GoogleFonts.inter(color: EcoColors.error),
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];
                final savedItems = allItems
                    .where((item) => savedTips.contains(item['id'] as String?))
                    .toList();

                if (savedItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 64,
                            color: EcoColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved tips found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: EcoColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: savedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = savedItems[index];
                    final tipId = item['id'] as String? ?? '';
                    return _ContentCard(
                      title: item['title'] as String? ?? 'Untitled',
                      summary: item['summary'] as String? ?? '',
                      category: item['category'] as String? ?? '',
                      isSaved: true,
                      onBookmark: () {
                        FirestoreService.instance.toggleSaveTip(
                          userId,
                          tipId,
                          false,
                        );
                      },
                      onTap: () => _openDetail(item),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
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

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.summary,
    required this.category,
    required this.isSaved,
    required this.onBookmark,
    required this.onTap,
  });

  final String title;
  final String summary;
  final String category;
  final bool isSaved;
  final VoidCallback onBookmark;
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
            IconButton(
              onPressed: onBookmark,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? EcoColors.primary : EcoColors.onSurfaceVariant,
              ),
              tooltip: isSaved ? 'Remove from saved' : 'Save tip',
            ),
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
