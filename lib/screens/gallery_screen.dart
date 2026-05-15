import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class _GalleryItem {
  const _GalleryItem({
    required this.title,
    required this.tag,
    required this.imageUrl,
  });

  final String title;
  final String tag;
  final String imageUrl;
}

const _kGalleryItems = [
  _GalleryItem(
    title: 'Solar rooftop garden',
    tag: 'energy',
    imageUrl:
        'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Zero-waste kitchen',
    tag: 'home',
    imageUrl:
        'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Urban cycling commute',
    tag: 'mobility',
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Rainwater collection',
    tag: 'water',
    imageUrl:
        'https://images.unsplash.com/photo-1620626011761-996317702782?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Community compost hub',
    tag: 'food',
    imageUrl:
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Native wildflower meadow',
    tag: 'nature',
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Reusable market haul',
    tag: 'products',
    imageUrl:
        'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Wind farm at dusk',
    tag: 'energy',
    imageUrl:
        'https://images.unsplash.com/photo-1466611653911-950815379e6b?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Bamboo utensil set',
    tag: 'products',
    imageUrl:
        'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80',
  ),
  _GalleryItem(
    title: 'Forest trail stewardship',
    tag: 'nature',
    imageUrl:
        'https://images.unsplash.com/photo-1448375240586-882707db888b?w=600&q=80',
  ),
];

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_GalleryItem> get _filtered {
    if (_query.isEmpty) return _kGalleryItems;
    return _kGalleryItems.where((item) {
      return item.title.toLowerCase().contains(_query) ||
          item.tag.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

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
          'Image Gallery',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search or filter by tag…',
                  hintStyle: GoogleFonts.inter(
                    color: EcoColors.outline,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: EcoColors.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: EcoColors.onSurfaceVariant,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: EcoColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_search_rounded,
                              size: 48,
                              color: EcoColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No images match your search',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: EcoColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _GalleryTile(item: items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.item});

  final _GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EcoColors.surfaceContainer),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: EcoColors.surfaceContainer,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EcoColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: EcoColors.secondaryContainer,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: EcoColors.secondary,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: EcoColors.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: EcoColors.primaryFixed.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.tag,
                      style: GoogleFonts.publicSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: EcoColors.primary,
                      ),
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
