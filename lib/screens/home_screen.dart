import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dashboard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/active_state_body.dart';
import '../widgets/eco_app_bar.dart';
import '../widgets/empty_state_body.dart';
import '../widgets/home_hub_section.dart';
import '../services/user_preferences.dart';
import '../services/firestore_service.dart';
import '../database_service.dart';
import 'notifications_screen.dart';

/// Home tab: live dashboard (empty or active) plus module hub for rubric navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.showCelebration,
    required this.isSaving,
    required this.onCompleteAction,
    this.onDismissCelebration,
  });

  final DashboardState state;
  final bool showCelebration;
  final bool isSaving;
  final VoidCallback onCompleteAction;
  final VoidCallback? onDismissCelebration;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    FirestoreService.instance.seedProductionData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserPreferences.instance.userName,
      builder: (context, userName, _) {
        return ValueListenableBuilder<String>(
          valueListenable: UserPreferences.instance.avatarPath,
          builder: (context, avatarPath, _) {
            final String firstName = userName.trim().isNotEmpty
                ? userName.trim().split(' ').first
                : 'Eco-Warrior';

            final hour = DateTime.now().hour;
            final greeting = (hour < 12)
                ? 'Good morning'
                : (hour < 17) ? 'Good afternoon' : 'Good evening';

            return Scaffold(
              backgroundColor: EcoColors.background,
              appBar: AppBar(
                backgroundColor: EcoColors.surface,
                elevation: 1,
                shadowColor: Colors.black12,
                automaticallyImplyLeading: false,
                titleSpacing: 16,
                title: Row(
                  children: [
                    if (!widget.state.isFirstTime)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.secondaryContainer,
                          border: Border.all(color: EcoColors.primaryFixed, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarPath.isEmpty
                            ? (FirebaseAuth.instance.currentUser?.photoURL != null
                                ? Image.network(
                                    FirebaseAuth.instance.currentUser!.photoURL!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, color: EcoColors.secondary))
                            : Image.file(File(avatarPath), fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.secondaryContainer,
                        ),
                        child: const Icon(Icons.eco_rounded, color: EcoColors.primary, size: 22),
                      ),
                    const SizedBox(width: 10),
                    Text(
                      'EcoTrack',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: EcoColors.primary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none, color: EcoColors.primary),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: ListView(
                    key: ValueKey<bool>(widget.state.isFirstTime),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (widget.state.isFirstTime)
                        EmptyStateBody(
                          onCompleteAction: widget.onCompleteAction,
                          isLoading: widget.isSaving,
                          embedInParentScroll: true,
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            '$greeting, $firstName!',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: EcoColors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        // Wrap the FutureBuilder here as requested for streak and tasks
                        FutureBuilder<List<int>>(
                          future: Future.wait([
                            DatabaseService.instance.getTasksCompleted(FirebaseAuth.instance.currentUser?.uid ?? ''),
                            DatabaseService.instance.getCurrentStreak(FirebaseAuth.instance.currentUser?.uid ?? ''),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            final int currentStreak = snapshot.data?[1] ?? widget.state.dayStreak;
                            return ActiveStateBody(
                              state: widget.state.copyWith(userName: firstName, dayStreak: currentStreak),
                              showCelebration: widget.showCelebration,
                              onDismissCelebration: widget.onDismissCelebration,
                              embedInParentScroll: true,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      const HomeHubSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
