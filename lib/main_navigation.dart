import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'database_service.dart';
import 'models/dashboard_state.dart';
import 'screens/carbon_tracker_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/waste_tracker_screen.dart';
import 'theme/app_theme.dart';

/// Post-auth shell: IndexedStack tabs, center-docked FAB, and BottomAppBar.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _navIndex = 0;
  DashboardState _dashState = emptyUserState;
  bool _showCelebration = false;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardFromDb();
  }

  String? get _userId =>
      Provider.of<AuthService>(context, listen: false).currentUid;

  String get _today =>
      DateTime.now().toIso8601String().split('T').first;

  Future<void> _loadDashboardFromDb() async {
    final userId = _userId;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final dailyKg =
          await DatabaseService.instance.getDailyCarbonTotal(userId, _today);
      if (!mounted) return;

      if (dailyKg > 0) {
        setState(() {
          _dashState = activeUserState.copyWith(
            kgSaved: dailyKg,
            todayActionCompleted: true,
          );
          _showCelebration = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCompleteAction() async {
    final userId = _userId;
    if (userId == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await DatabaseService.instance.logWasteAction(
        userId,
        'reusable_bottle',
        1,
      );
      await DatabaseService.instance.logCarbonActivity(
        userId,
        'Electricity',
        null,
        1.0,
      );

      final dailyKg =
          await DatabaseService.instance.getDailyCarbonTotal(userId, _today);

      if (!mounted) return;
      setState(() {
        _dashState = activeUserState.copyWith(
          kgSaved: dailyKg > 0 ? dailyKg : 0.5,
          todayActionCompleted: true,
        );
        _showCelebration = true;
      });
      _showCompletionSnackbar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save action: $e'),
          backgroundColor: EcoColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _dismissCelebration() {
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _showCelebration = false);
  }

  void _showCompletionSnackbar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Action complete! +10 points earned.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: EcoColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Continue',
          textColor: EcoColors.primaryFixed,
          onPressed: _dismissCelebration,
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (_showCelebration && index != 0) _dismissCelebration();
    setState(() => _navIndex = index);
  }

  void _openTrackerSheet() {
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
                  'Log an impact',
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
                    child: const Icon(
                      Icons.co2_rounded,
                      color: EcoColors.primary,
                    ),
                  ),
                  title: Text(
                    'Log Carbon Activity',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Travel, energy, or meals',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: EcoColors.onSurfaceVariant,
                    ),
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
                  subtitle: Text(
                    'Quick eco habits',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: EcoColors.onSurfaceVariant,
                    ),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: EcoColors.background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: EcoColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EcoColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          HomeScreen(
            state: _dashState,
            showCelebration: _showCelebration,
            isSaving: _isSaving,
            onCompleteAction: _onCompleteAction,
            onDismissCelebration: _dismissCelebration,
          ),
          const TipsScreen(),
          ProgressScreen(
            isEmpty: _dashState.isFirstTime,
            onGoToDashboard: () => _onNavTap(0),
          ),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTrackerSheet,
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: EcoColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: const Border(
            top: BorderSide(
              color: EcoColors.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GNav(
              gap: 8,
              activeColor: Colors.white,
              tabBackgroundColor: EcoColors.primary,
              color: EcoColors.onSurfaceVariant,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBorderRadius: 12,
              selectedIndex: _navIndex,
              onTabChange: _onNavTap,
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.lightbulb_rounded,
                  text: 'Tips',
                ),
                GButton(
                  icon: Icons.trending_up_rounded,
                  text: 'Progress',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
