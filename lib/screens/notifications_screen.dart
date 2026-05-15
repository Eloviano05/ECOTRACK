import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mockNotifications = [
      {
        'title': 'Reminder: Log your daily eco-actions!',
        'body': 'You haven\'t logged any actions today. Keep your streak alive!',
        'time': '2 hours ago',
        'isRead': 'false',
      },
      {
        'title': 'New Challenge Available: Plastic-Free Week',
        'body': 'Join the community in our latest challenge and earn 500 bonus points.',
        'time': '5 hours ago',
        'isRead': 'true',
      },
      {
        'title': 'Community: Someone liked your success story!',
        'body': 'Your post "Switching to Solar" is gaining traction.',
        'time': 'Yesterday',
        'isRead': 'true',
      },
    ];

    return Scaffold(
      backgroundColor: EcoColors.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        backgroundColor: EcoColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: EcoColors.onSurface,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = mockNotifications[index];
          final bool isRead = item['isRead'] == 'true';

          return Container(
            decoration: BoxDecoration(
              color: isRead ? EcoColors.surface : EcoColors.primaryFixed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? EcoColors.surfaceVariant : EcoColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRead ? EcoColors.surfaceVariant : EcoColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                  color: isRead ? EcoColors.onSurfaceVariant : Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                item['title']!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                  color: EcoColors.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    item['body']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['time']!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isRead ? EcoColors.outline : EcoColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
