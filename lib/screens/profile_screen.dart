import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../models/profile_state.dart';
import '../theme/app_theme.dart';
import 'achievement_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile _profile = defaultUserProfile;
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _syncFromFirebase();
  }

  void _syncFromFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _profile = _profile.copyWith(
        displayName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : _profile.displayName,
        email: user.email ?? _profile.email,
        photoUrl: user.photoURL ?? _profile.photoUrl,
      );
    });
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  void _openAchievement(Achievement achievement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementDetailScreen(achievement: achievement),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signOut();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: const _ProfileAppBar(),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileHeader(
            profile: _profile,
            onEdit: _openEditProfile,
          ),
          const SizedBox(height: 28),
          _GoalBanner(profile: _profile),
          const SizedBox(height: 28),
          _SettingsSection(
            notificationsOn: _notificationsOn,
            darkModeOn: _darkModeOn,
            isSigningOut: _isSigningOut,
            onNotificationsChanged: (v) => setState(() => _notificationsOn = v),
            onDarkModeChanged: (v) => setState(() => _darkModeOn = v),
            onSignOut: _signOut,
          ),
          const SizedBox(height: 28),
          _AchievementsSection(
            achievements: kAchievements,
            onTap: _openAchievement,
          ),
        ],
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.eco_rounded, color: EcoColors.primary),
          ),
          Text(
            'EcoTrack',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: EcoColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: EcoColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              defaultUserProfile.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                color: EcoColors.secondary,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      titleSpacing: 0,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: profile.photoUrl != null
                  ? Image.network(
                      profile.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: EcoColors.primaryContainer,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: EcoColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: EcoColors.secondaryContainer,
      child: const Icon(Icons.person, size: 40, color: EcoColors.secondary),
    );
  }
}

class _GoalBanner extends StatelessWidget {
  final UserProfile profile;

  const _GoalBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EcoColors.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: EcoColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: EcoColors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY GOAL',
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: EcoColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.goalTitle,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.goalSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final bool notificationsOn;
  final bool darkModeOn;
  final bool isSigningOut;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onSignOut;

  const _SettingsSection({
    required this.notificationsOn,
    required this.darkModeOn,
    required this.isSigningOut,
    required this.onNotificationsChanged,
    required this.onDarkModeChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EcoColors.surfaceVariant),
          ),
          child: Column(
            children: [
              _SettingsToggleRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: notificationsOn,
                onChanged: onNotificationsChanged,
                showDivider: true,
              ),
              _SettingsToggleRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: darkModeOn,
                onChanged: onDarkModeChanged,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSigningOut ? null : onSignOut,
            icon: isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(
              isSigningOut ? 'Signing out…' : 'Log Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: EcoColors.error,
              side: const BorderSide(color: EcoColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: EcoColors.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: EcoColors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: EcoColors.onPrimary,
                activeTrackColor: EcoColors.primary,
                inactiveTrackColor: EcoColors.surfaceVariant,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: EcoColors.surfaceVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final List<Achievement> achievements;
  final void Function(Achievement) onTap;

  const _AchievementsSection({
    required this.achievements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: EcoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EcoColors.surfaceVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < achievements.length; i++)
                _AchievementRow(
                  achievement: achievements[i],
                  onTap: () => onTap(achievements[i]),
                  showDivider: i < achievements.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;
  final bool showDivider;

  const _AchievementRow({
    required this.achievement,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: achievement.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.icon,
                      color: achievement.iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      achievement.listTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: EcoColors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: EcoColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: EcoColors.surfaceVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
