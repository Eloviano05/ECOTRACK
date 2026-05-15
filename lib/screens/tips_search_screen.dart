import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/eco_tip.dart';
import '../theme/app_theme.dart';
import 'tip_detail_screen.dart';

class TipsSearchScreen extends StatefulWidget {
  const TipsSearchScreen({super.key});

  @override
  State<TipsSearchScreen> createState() => _TipsSearchScreenState();
}

class _TipsSearchScreenState extends State<TipsSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(() => setState(() => _query = _controller.text.trim()));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<EcoTip> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return kAllTips.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.summary.toLowerCase().contains(q)).toList();
  }

  bool get _hasQuery => _query.isNotEmpty;
  bool get _noResults => _hasQuery && _results.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _SearchAppBar(
        controller: _controller,
        focusNode: _focusNode,
        onClear: () {
          _controller.clear();
          _focusNode.requestFocus();
        },
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: _noResults
          ? _EmptyState(
              query: _query,
              onSuggestion: (s) {
                _controller.text = s;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: s.length),
                );
              },
            )
          : _hasQuery
              ? _ResultsList(
                  results: _results,
                  onTap: (tip) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TipDetailScreen(tip: tip)),
                  ),
                )
              : _DefaultView(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Search AppBar
// ─────────────────────────────────────────────────────────
class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _SearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      title: Container(
        height: 50,
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EcoColors.outlineVariant),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            // Back / search icon
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: EcoColors.onSurfaceVariant, size: 22),
              padding: EdgeInsets.zero,
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: EcoColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search tips...',
                  hintStyle: GoogleFonts.inter(color: EcoColors.outline),
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            // Clear button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) => val.text.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded,
                          color: EcoColors.onSurfaceVariant, size: 20),
                      padding: EdgeInsets.zero,
                    )
                  : const SizedBox(width: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty / no-results state
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSuggestion;

  const _EmptyState({required this.query, required this.onSuggestion});

  static const _suggestions = ['Recycling', 'Vegan', 'Biking'];
  static const _categories = [
    (label: 'All',    icon: Icons.apps_rounded),
    (label: 'Energy', icon: Icons.bolt_rounded),
    (label: 'Food',   icon: Icons.restaurant_rounded),
    (label: 'Water',  icon: Icons.water_drop_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
      children: [
        // Illustration circle
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerLow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 90,
                  color: EcoColors.primary.withOpacity(0.18),
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Icon(
                    Icons.search_rounded,
                    size: 48,
                    color: EcoColors.secondary.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Headline
        Text(
          'No tips found for "$query"',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: EcoColors.onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Try a different keyword or browse our categories below to find sustainable living advice.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: EcoColors.onSurfaceVariant,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Suggested searches label
        Text(
          'SUGGESTED SEARCHES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: EcoColors.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Suggestion chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: _suggestions
              .map((s) => _SuggestionChip(label: s, onTap: () => onSuggestion(s)))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Request a tip CTA
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 18, color: EcoColors.primary),
            label: Text(
              'Request a Tip',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: EcoColors.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Divider
        const Divider(color: EcoColors.outlineVariant),
        const SizedBox(height: 24),

        // Browse categories
        Text(
          'Browse Tip Categories',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: _categories
              .map((c) => _CategoryTile(label: c.label, icon: c.icon))
              .toList(),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EcoColors.outlineVariant),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryTile({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: EcoColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: EcoColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Default view (empty query — show all tips)
// ─────────────────────────────────────────────────────────
class _DefaultView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: kAllTips
          .map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResultTile(tip: tip),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Results list
// ─────────────────────────────────────────────────────────
class _ResultsList extends StatelessWidget {
  final List<EcoTip> results;
  final ValueChanged<EcoTip> onTap;

  const _ResultsList({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onTap(results[i]),
        child: _ResultTile(tip: results[i]),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final EcoTip tip;
  const _ResultTile({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tip.iconBg),
            child: Icon(tip.icon, color: tip.iconFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(tip.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: EcoColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: EcoColors.outlineVariant),
        ],
      ),
    );
  }
}
