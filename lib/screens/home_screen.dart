import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/active_state_body.dart';
import '../widgets/empty_state_body.dart';
import '../widgets/home_hub_section.dart';
import '../services/user_preferences.dart';
import '../services/firestore_service.dart';
import '../services/offline_sync_service.dart';
import '../database_service.dart';
import 'notifications_screen.dart';
import 'progress_screen.dart';
import 'meal_plan_screen.dart';
import 'tips_screen.dart';

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
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _runInitializationBarrier();
  }

  Future<void> _runInitializationBarrier() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirestoreService.instance.syncUserDocument(currentUser);
    }
    await FirestoreService.instance.seedProductionData();
    await OfflineSyncService.instance.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: EcoColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            ),
          );
        }

        if (initSnapshot.hasError) {
          return Scaffold(
            backgroundColor: EcoColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not sync your data. Pull to refresh or try again.\n${initSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
                ),
              ),
            ),
          );
        }

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
                    : (hour < 17)
                        ? 'Good afternoon'
                        : 'Good evening';

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
                              color: avatarPath.isEmpty
                                  ? const Color(0xFFE8F5E9)
                                  : EcoColors.secondaryContainer,
                              border: Border.all(
                                color: avatarPath.isEmpty
                                    ? const Color(0xFFC8E6C9)
                                    : EcoColors.primaryFixed,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: avatarPath.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF2E7D32),
                                    size: 24,
                                  )
                                : Image.file(File(avatarPath),
                                    fit: BoxFit.cover),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: EcoColors.secondaryContainer,
                            ),
                            child: const Icon(Icons.eco_rounded,
                                color: EcoColors.primary, size: 22),
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
                        icon: const Icon(Icons.notifications_none,
                            color: EcoColors.primary),
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
                            FutureBuilder<List<int>>(
                              future: Future.wait([
                                DatabaseService.instance.getTasksCompleted(
                                    currentUser?.uid ?? ''),
                                DatabaseService.instance.getCurrentStreak(
                                    currentUser?.uid ?? ''),
                              ]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  );
                                }
                                final int currentStreak = snapshot.data?[1] ??
                                    widget.state.dayStreak;
                                return ActiveStateBody(
                                  state: widget.state.copyWith(
                                      userName: firstName,
                                      dayStreak: currentStreak),
                                  showCelebration: widget.showCelebration,
                                  onDismissCelebration: () {
                                    if (widget.showCelebration) {
                                      widget.onDismissCelebration?.call();
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ProgressScreen(
                                              isEmpty: false),
                                        ),
                                      );
                                    }
                                  },
                                  embedInParentScroll: true,
                                );
                              },
                            ),
                            if (currentUser != null)
                              _SustainableChallengesSection(
                                userId: currentUser.uid,
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
      },
    );
  }
}

// ── Live challenges carousel + navigation to detail / full list ─────────────

class _SustainableChallengesSection extends StatefulWidget {
  const _SustainableChallengesSection({required this.userId});

  final String userId;

  @override
  State<_SustainableChallengesSection> createState() =>
      _SustainableChallengesSectionState();
}

class _SustainableChallengesSectionState
    extends State<_SustainableChallengesSection> {
  final Set<String> _joiningIds = {};

  Future<void> _join(String challengeId, String title) async {
    if (_joiningIds.contains(challengeId)) return;
    setState(() => _joiningIds.add(challengeId));
    try {
      await FirestoreService.instance
          .joinChallenge(widget.userId, challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined $title! 🌟'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not join: $e'),
          backgroundColor: EcoColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _joiningIds.remove(challengeId));
      }
    }
  }

  void _openDetail(String challengeId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChallengeDetailPage(
          challengeId: challengeId,
          data: data,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _openAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllChallengesPage(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(widget.userId),
      builder: (context, userSnapshot) {
        final joined = FirestoreService.activeChallengesFromSnapshot(
          userSnapshot.data,
        );

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance.watchChallengesWithFallback(),
          builder: (context, challengesSnapshot) {
            if (challengesSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !challengesSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              );
            }

            final docs = challengesSnapshot.data ?? [];
            if (docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sustainable Living Challenges',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: EcoColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openAll,
                        child: Text(
                          'View all',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: EcoColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final challenge = docs[index];
                      final challengeId = challenge['id'] as String? ?? '';
                      final title = challenge['title'] as String? ?? 'Challenge';
                      final desc = challenge['description'] as String? ?? '';
                      final category = challenge['category'] as String? ?? '';
                      final duration =
                          challenge['duration_days'] as int? ?? 7;
                      final points =
                          (challenge['rewards'] as Map?)?['points'] as int? ??
                              0;
                      final imageUrl =
                          challenge['image_url'] as String? ?? '';
                      final isJoined = joined.contains(challengeId);
                      final isJoining = _joiningIds.contains(challengeId);

                      return GestureDetector(
                        onTap: () => _openDetail(challengeId, challenge),
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: EcoColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: EcoColors.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                height: 80,
                                child: Image.network(
                                  imageUrl.isNotEmpty
                                      ? imageUrl
                                      : 'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=400&q=80',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: EcoColors.secondaryContainer,
                                    child: const Icon(Icons.eco,
                                        color: EcoColors.primary),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                top: 92,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: EcoColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: EcoColors.primaryFixed
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '+$points pts',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: EcoColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: EcoColors.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$duration Days · $category',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: EcoColors.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 28,
                                          child: ElevatedButton(
                                            onPressed: isJoined || isJoining
                                                ? null
                                                : () => _join(
                                                      challengeId,
                                                      title,
                                                    ),
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor: isJoined
                                                  ? Colors.transparent
                                                  : EcoColors.primary,
                                              foregroundColor: isJoined
                                                  ? EcoColors.primary
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                            ),
                                            child: isJoining
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    isJoined
                                                        ? 'Joined'
                                                        : 'Join',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Full Firestore-backed challenge list (linked from home carousel).
class _AllChallengesPage extends StatelessWidget {
  const _AllChallengesPage({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        title: Text(
          'All Challenges',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: EcoColors.primary,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.watchChallengesWithFallback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No challenges yet. Check back soon.',
                style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index];
              final challengeId = data['id'] as String? ?? '';
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: EcoColors.outlineVariant),
                ),
                tileColor: EcoColors.surfaceContainerLowest,
                title: Text(
                  data['title'] as String? ?? 'Challenge',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  data['description'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: EcoColors.primary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ChallengeDetailPage(
                        challengeId: challengeId,
                        data: data,
                        userId: userId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Challenge detail — tasks, tips, links to Tips Library / Meal Planner.
class _ChallengeDetailPage extends StatefulWidget {
  const _ChallengeDetailPage({
    required this.challengeId,
    required this.data,
    required this.userId,
  });

  final String challengeId;
  final Map<String, dynamic> data;
  final String userId;

  @override
  State<_ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<_ChallengeDetailPage> {
  bool _joining = false;

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await FirestoreService.instance
          .joinChallenge(widget.userId, widget.challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Joined ${widget.data['title'] ?? 'challenge'}! 🌟',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? 'Challenge';
    final desc = widget.data['description'] as String? ?? '';
    final category = widget.data['category'] as String? ?? '';
    final difficulty = widget.data['difficulty'] as String? ?? '';
    final duration = widget.data['duration_days'] as int? ?? 0;
    final imageUrl = widget.data['image_url'] as String? ?? '';
    final tasks = (widget.data['tasks'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final tips = (widget.data['tips'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final rewards = widget.data['rewards'] as Map<String, dynamic>? ?? {};
    final points = rewards['points'] as int? ?? 0;
    final badge = rewards['badge'] as String? ?? '';
    final impact = rewards['impact_estimate'] as String? ?? '';
    final isEatingChallenge =
        category.toLowerCase().contains('eating') ||
            title.toLowerCase().contains('meatless');

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: EcoColors.primary,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.getUserStream(widget.userId),
        builder: (context, userSnap) {
          final joined = FirestoreService.activeChallengesFromSnapshot(
            userSnap.data,
          );
          final isJoined = joined.contains(widget.challengeId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: EcoColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$duration days · $difficulty · $category',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EcoColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              if (badge.isNotEmpty || impact.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EcoColors.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rewards · +$points pts',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: EcoColors.onPrimaryContainer,
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(badge, style: GoogleFonts.inter(fontSize: 13)),
                      ],
                      if (impact.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          impact,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: EcoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Daily tasks',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 18, color: EcoColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tips',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...tips.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $t',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TipsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('Tips Library'),
                    ),
                  ),
                  if (isEatingChallenge) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MealPlanScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu, size: 18),
                        label: const Text('Recipes'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isJoined || _joining ? null : _join,
                  child: _joining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isJoined ? 'Already joined' : 'Join Challenge',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
