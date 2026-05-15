import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database_service.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final Set<String> _joinedIds = {};
  final Set<String> _joiningIds = {};

  static const _challenges = [
    _ChallengeData(
      id: 'plastic_free_week',
      title: 'Plastic-Free Week',
      description:
          'Avoid single-use plastics for seven days. Track reusables, refills, and package-free choices.',
      icon: Icons.shopping_bag_outlined,
      duration: '7 days',
    ),
    _ChallengeData(
      id: 'zero_emissions_commute',
      title: 'Zero-Emissions Commute',
      description:
          'Walk, bike, or take public transit instead of driving. Log each low-carbon trip you take.',
      icon: Icons.directions_bike_rounded,
      duration: '14 days',
    ),
  ];

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'user_123';

  Future<void> _joinChallenge(_ChallengeData challenge) async {
    if (_joinedIds.contains(challenge.id) ||
        _joiningIds.contains(challenge.id)) {
      return;
    }

    setState(() => _joiningIds.add(challenge.id));
    try {
      await DatabaseService.instance.joinChallenge(_userId, challenge.id);
      if (!mounted) return;
      setState(() {
        _joinedIds.add(challenge.id);
        _joiningIds.remove(challenge.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Joined ${challenge.title}!',
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
      setState(() => _joiningIds.remove(challenge.id));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EcoColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EcoColors.primaryContainer.withValues(alpha: 0.25),
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
            ..._challenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ChallengeCard(
                  challenge: c,
                  joined: _joinedIds.contains(c.id),
                  joining: _joiningIds.contains(c.id),
                  onJoin: () => _joinChallenge(c),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String duration;

  const _ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
  });
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData challenge;
  final bool joined;
  final bool joining;
  final VoidCallback onJoin;

  const _ChallengeCard({
    required this.challenge,
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
                child: Icon(challenge.icon, color: EcoColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.duration,
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: EcoColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
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
