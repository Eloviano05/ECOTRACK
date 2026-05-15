import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class _GalleryItem {
  const _GalleryItem({
    required this.imageUrl,
    required this.title,
    required this.tag,
  });

  final String imageUrl;
  final String title;
  final String tag;
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<_GalleryItem>> _galleryFuture;

  static const _fallbackTags = [
    'energy',
    'home',
    'mobility',
    'water',
    'food',
    'nature',
    'products',
    'energy',
    'products',
    'nature',
  ];

  static const _fallbackTitles = [
    'Solar inspiration',
    'Sustainable home',
    'Green commute',
    'Water wisdom',
    'Fresh harvest',
    'Wild nature',
    'Eco products',
    'Clean energy',
    'Reusable living',
    'Forest paths',
  ];

  @override
  void initState() {
    super.initState();
    FirestoreService.instance.seedGallery();
    _galleryFuture = _loadGallery();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  Future<List<_GalleryItem>> _loadGallery() async {
    final urls = await FirestoreService.instance.getGalleryImages();
    return List.generate(urls.length, (index) {
      return _GalleryItem(
        imageUrl: urls[index],
        title: index < _fallbackTitles.length
            ? _fallbackTitles[index]
            : 'Eco inspiration ${index + 1}',
        tag: index < _fallbackTags.length ? _fallbackTags[index] : 'nature',
      );
    });
  }

  void _reloadGallery() {
    setState(() => _galleryFuture = _loadGallery());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_GalleryItem> _filter(List<_GalleryItem> items) {
    if (_query.isEmpty) return items;
    return items.where((item) {
      return item.title.toLowerCase().contains(_query) ||
          item.tag.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              child: FutureBuilder<List<_GalleryItem>>(
                future: _galleryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: EcoColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Could not load gallery',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: EcoColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _reloadGallery,
                              style: FilledButton.styleFrom(
                                backgroundColor: EcoColors.primary,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = _filter(snapshot.data ?? []);

                  if (items.isEmpty) {
                    return Center(
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
                    );
                  }

                  return GridView.builder(
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
                  );
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
