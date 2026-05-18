import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final Set<String> _joiningIds = {};

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _joinChallenge({
    required String challengeId,
    required String title,
  }) async {
    if (_userId.isEmpty || _joiningIds.contains(challengeId)) return;

    setState(() => _joiningIds.add(challengeId));
    try {
      await FirestoreService.instance.joinChallenge(_userId, challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Joined $title!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: EcoColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not join challenge: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: EcoColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _joiningIds.remove(challengeId));
      }
    }
  }

  static IconData _iconForCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('waste')) return Icons.shopping_bag_outlined;
    if (c.contains('eat') || c.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (c.contains('energy')) return Icons.bolt_rounded;
    return Icons.emoji_events_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return Scaffold(
        backgroundColor: EcoColors.background,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Sign in to view challenges.',
            style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.getUserStream(_userId),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  );
                }

                if (challengesSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load challenges.',
                        style: GoogleFonts.inter(
                          color: EcoColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                final docs = challengesSnapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: EcoColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              EcoColors.primaryContainer.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: EcoColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Join community challenges to stay motivated and multiply your impact.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.45,
                                color: EcoColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (docs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            'No challenges available yet.',
                            style: GoogleFonts.inter(
                              color: EcoColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...docs.map((data) {
                        final challengeId =
                            data['id'] as String? ?? '';
                        final title = data['title'] as String? ?? 'Challenge';
                        final description =
                            data['description'] as String? ?? '';
                        final category = data['category'] as String? ?? '';
                        final durationDays =
                            data['duration_days'] as int? ?? 7;
                        final points =
                            (data['rewards'] as Map?)?['points'] as int? ?? 0;
                        final isJoined = joined.contains(challengeId);
                        final isJoining = _joiningIds.contains(challengeId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ChallengeCard(
                            title: title,
                            description: description,
                            durationLabel: '$durationDays days · $category',
                            points: points,
                            icon: _iconForCategory(category),
                            joined: isJoined,
                            joining: isJoining,
                            onJoin: () => _joinChallenge(
                              challengeId: challengeId,
                              title: title,
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Challenges',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: EcoColors.primary,
        ),
      ),
      centerTitle: true,
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final String durationLabel;
  final int points;
  final IconData icon;
  final bool joined;
  final bool joining;
  final VoidCallback onJoin;

  const _ChallengeCard({
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.points,
    required this.icon,
    required this.joined,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EcoColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: EcoColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationLabel,
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: EcoColors.primary,
                      ),
                    ),
                    if (points > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+$points pts',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: EcoColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: EcoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: joined
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      'Joined',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EcoColors.primary,
                      side: const BorderSide(color: EcoColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: joining ? null : onJoin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: joining
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EcoColors.onPrimary,
                            ),
                          )
                        : Text(
                            'Join Challenge',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
