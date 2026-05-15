import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database_service.dart';
import '../theme/app_theme.dart';

class WasteTrackerScreen extends StatefulWidget {
  const WasteTrackerScreen({super.key});

  @override
  State<WasteTrackerScreen> createState() => _WasteTrackerScreenState();
}

class _WasteTrackerScreenState extends State<WasteTrackerScreen> {
  String? _busyActionType;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'user_123';

  Future<void> _logAction({
    required String actionType,
    required String label,
  }) async {
    if (_busyActionType != null) return;

    setState(() => _busyActionType = actionType);
    try {
      await DatabaseService.instance.logWasteAction(_userId, actionType, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label logged — great work!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: EcoColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not log action: $e',
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
      if (mounted) setState(() => _busyActionType = null);
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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Waste Reduction',
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
                color: EcoColors.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EcoColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.recycling_rounded,
                    color: EcoColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tap an action to log it instantly. Every small habit keeps waste out of landfills.',
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
            _WasteActionCard(
              title: 'Reusable Bottle',
              subtitle: 'Skip single-use plastic for the day',
              icon: Icons.water_drop_rounded,
              iconColor: EcoColors.tertiary,
              iconBg: EcoColors.tertiaryContainer.withValues(alpha: 0.35),
              isBusy: _busyActionType == 'reusable_bottle',
              enabled: _busyActionType == null,
              onTap: () => _logAction(
                actionType: 'reusable_bottle',
                label: 'Reusable Bottle',
              ),
            ),
            const SizedBox(height: 12),
            _WasteActionCard(
              title: 'Compost',
              subtitle: 'Divert organic waste from landfill',
              icon: Icons.compost_rounded,
              iconColor: EcoColors.secondary,
              iconBg: EcoColors.secondaryContainer,
              isBusy: _busyActionType == 'compost',
              enabled: _busyActionType == null,
              onTap: () => _logAction(
                actionType: 'compost',
                label: 'Compost',
              ),
            ),
            const SizedBox(height: 12),
            _WasteActionCard(
              title: 'Recycle Can',
              subtitle: 'Recycle aluminium or steel cans',
              icon: Icons.recycling_rounded,
              iconColor: EcoColors.primary,
              iconBg: EcoColors.primaryFixed.withValues(alpha: 0.45),
              isBusy: _busyActionType == 'recycle_can',
              enabled: _busyActionType == null,
              onTap: () => _logAction(
                actionType: 'recycle_can',
                label: 'Recycle Can',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WasteActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isBusy;
  final bool enabled;
  final VoidCallback onTap;

  const _WasteActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isBusy,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EcoColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: EcoColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EcoColors.primary,
                  ),
                )
              else
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: enabled
                      ? EcoColors.primary
                      : EcoColors.outlineVariant,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
