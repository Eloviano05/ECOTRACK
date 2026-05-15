import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/about_screen.dart';
import '../screens/carbon_tracker_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/meal_plan_screen.dart';
import '../screens/tips_screen.dart';
import '../screens/waste_tracker_screen.dart';
import '../theme/app_theme.dart';

/// Module quick-launch grid — intended below the live dashboard on Home.
class HomeHubSection extends StatelessWidget {
  const HomeHubSection({super.key});

  void _openLogActivitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EcoColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: EcoColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  'Log Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EcoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EcoColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.co2_rounded, color: EcoColors.primary),
                  ),
                  title: Text(
                    'Log Carbon Activity',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CarbonTrackerScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EcoColors.primaryFixed.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      color: EcoColors.primary,
                    ),
                  ),
                  title: Text(
                    'Log Waste Reduction',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WasteTrackerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = <_HubTileData>[
      _HubTileData(
        'Log Activity',
        Icons.add_chart_rounded,
        () => _openLogActivitySheet(context),
      ),
      _HubTileData(
        'Tips Library',
        Icons.menu_book_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TipsScreen()),
        ),
      ),
      _HubTileData(
        'Meal Planner',
        Icons.restaurant_menu_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealPlanScreen()),
        ),
      ),
      _HubTileData(
        'Image Gallery',
        Icons.photo_library_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GalleryScreen()),
        ),
      ),
      _HubTileData(
        'About Us',
        Icons.info_outline_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
      ),
      _HubTileData(
        'Contact Us',
        Icons.mail_outline_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: EcoColors.surfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ALL MODULES',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: EcoColors.primary,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: EcoColors.surfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Quick access',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jump to any part of EcoTrack',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: modules
              .map((m) => _HubTile(title: m.title, icon: m.icon, onTap: m.onTap))
              .toList(),
        ),
      ],
    );
  }
}

class _HubTileData {
  const _HubTileData(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EcoColors.surfaceVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EcoColors.primaryFixed.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: EcoColors.primary, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: EcoColors.onSurface,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
