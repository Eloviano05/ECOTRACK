import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _storyController = TextEditingController();
  final List<_SuccessStory> _stories = List.of(_seedStories);

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      final story = _stories[index];
      _stories[index] = story.copyWith(
        liked: !story.liked,
        likeCount: story.liked ? story.likeCount - 1 : story.likeCount + 1,
      );
    });
  }

  void _openShareSheet() {
    _storyController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EcoColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EcoColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share your story',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EcoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inspire others with a quick win from your eco journey.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: EcoColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _storyController,
                  maxLines: 4,
                  style: GoogleFonts.inter(color: EcoColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Share your eco-journey...',
                    hintStyle: GoogleFonts.inter(color: EcoColors.outline),
                    filled: true,
                    fillColor: EcoColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: EcoColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: EcoColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: EcoColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _submitStory(sheetContext),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Post',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitStory(BuildContext sheetContext) {
    final text = _storyController.text.trim();
    if (text.isEmpty) return;

    Navigator.pop(sheetContext);
    setState(() {
      _stories.insert(
        0,
        _SuccessStory(
          username: 'You',
          timestamp: 'Just now',
          message: text,
          likeCount: 0,
          liked: false,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your story has been shared with the community!',
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
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
          'Community Stories',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: EcoColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: _stories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final story = _stories[index];
            return _StoryCard(
              story: story,
              onLike: () => _toggleLike(index),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openShareSheet,
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _SuccessStory {
  final String username;
  final String timestamp;
  final String message;
  final int likeCount;
  final bool liked;

  const _SuccessStory({
    required this.username,
    required this.timestamp,
    required this.message,
    this.likeCount = 0,
    this.liked = false,
  });

  _SuccessStory copyWith({
    String? username,
    String? timestamp,
    String? message,
    int? likeCount,
    bool? liked,
  }) {
    return _SuccessStory(
      username: username ?? this.username,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
    );
  }
}

const _seedStories = [
  _SuccessStory(
    username: 'Sarah M.',
    timestamp: '2 hours ago',
    message: 'Just finished my first zero-waste week! 🌍',
    likeCount: 24,
  ),
  _SuccessStory(
    username: 'Alex K.',
    timestamp: '5 hours ago',
    message: 'Biked to work every day this month — feeling great and saving CO₂!',
    likeCount: 18,
    liked: true,
  ),
  _SuccessStory(
    username: 'Jordan L.',
    timestamp: 'Yesterday',
    message: 'Swapped all our bulbs to LED. Electric bill dropped and the house looks warmer. 💡',
    likeCount: 31,
  ),
  _SuccessStory(
    username: 'Maya P.',
    timestamp: '2 days ago',
    message: 'Started composting kitchen scraps. Our garden has never been happier!',
    likeCount: 42,
  ),
];

class _StoryCard extends StatelessWidget {
  final _SuccessStory story;
  final VoidCallback onLike;

  const _StoryCard({
    required this.story,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: EcoColors.secondaryContainer,
                child: Text(
                  story.username.isNotEmpty ? story.username[0] : '?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: EcoColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.username,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    Text(
                      story.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story.message,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.45,
              color: EcoColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  story.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: story.liked
                      ? EcoColors.tertiary
                      : EcoColors.onSurfaceVariant,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Text(
                '${story.likeCount}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: EcoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
