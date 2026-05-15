import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EcoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showAvatar;

  const EcoAppBar({super.key, this.showAvatar = false});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EcoColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.secondaryContainer,
              border: showAvatar
                  ? Border.all(color: EcoColors.primaryFixed, width: 2)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: showAvatar
                ? Image.network(
                    'https://i.pravatar.cc/80?img=33',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: EcoColors.secondary,
                    ),
                  )
                : const Icon(
                    Icons.eco_rounded,
                    color: EcoColors.primary,
                    size: 22,
                  ),
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
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: EcoColors.primary,
          ),
          padding: const EdgeInsets.all(8),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
