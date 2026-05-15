import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/eco_tip.dart';
import '../theme/app_theme.dart';
import 'tips_search_screen.dart';
import 'tip_detail_screen.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  TipCategory _activeCategory = TipCategory.all;

  List<EcoTip> get _filtered => _activeCategory == TipCategory.all
      ? kAllTips
      : kAllTips.where((t) => t.category == _activeCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _TipsAppBar(onSearchTap: _openSearch),
      body: SafeArea(
        child: Column(
        children: [
          // ── Search bar (tappable, opens search screen) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SearchBarTile(onTap: _openSearch),
          ),
          const SizedBox(height: 12),

          // ── Filter chips ─────────────────────────────────
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: TipCategory.values.map((cat) {
                final active = cat == _activeCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FilterChip(
                    label: cat.label,
                    active: active,
                    onTap: () => setState(() => _activeCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tip list ──────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _TipCard(
                tip: _filtered[i],
                onTap: () => _openDetail(_filtered[i]),
              ),
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

  void _openDetail(EcoTip tip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TipDetailScreen(tip: tip)),
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

// ─────────────────────────────────────────────────────────
// Tappable search bar tile
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
// Tip card row
// ─────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final EcoTip tip;
  final VoidCallback onTap;

  const _TipCard({required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            // Icon avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tip.iconBg,
              ),
              child: Icon(tip.icon, color: tip.iconFg, size: 26),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: EcoColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tip.summary,
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
