import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../database_service.dart';
import '../models/dashboard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_app_bar.dart';
import '../widgets/eco_bottom_nav.dart';
import '../widgets/empty_state_body.dart';
import '../widgets/active_state_body.dart';
import 'tips_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Continue',
          textColor: EcoColors.primaryFixed,
          onPressed: _dismissCelebration,
        ),
      ),
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
      appBar: _navIndex == 0
          ? EcoAppBar(showAvatar: !_dashState.isFirstTime)
          : null,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: switch (_navIndex) {
          0 => _dashState.isFirstTime
              ? EmptyStateBody(
                  key: const ValueKey('empty'),
                  onCompleteAction: _onCompleteAction,
                  isLoading: _isSaving,
                )
              : ActiveStateBody(
                  key: const ValueKey('active'),
                  state: _dashState,
                  showCelebration: _showCelebration,
                  onDismissCelebration: _dismissCelebration,
                ),
          1 => const TipsScreen(key: ValueKey('tips')),
          2 => ProgressScreen(
              key: ValueKey('progress'),
              isEmpty: _dashState.isFirstTime,
              onGoToDashboard: () => setState(() => _navIndex = 0),
            ),
          3 => const ProfileScreen(key: ValueKey('profile')),
          _ => const SizedBox.shrink(key: ValueKey('unknown')),
        },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: EcoBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (_showCelebration && i != 0) _dismissCelebration();
          setState(() => _navIndex = i);
        },
        ),
      ),
    );
  }
}
