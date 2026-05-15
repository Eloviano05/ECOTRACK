import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late Future<List<Map<String, dynamic>>> _recipesFuture;
  late Future<List<Map<String, dynamic>>> _mealPlansFuture;

  @override
  void initState() {
    super.initState();
    FirestoreService.instance.seedRecipes();
    _loadData();
  }

  void _loadData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _recipesFuture = FirestoreService.instance.getRecipes();
        _mealPlansFuture = DatabaseService.instance.getMealPlans(userId);
      });
    }
  }

  String _getDayName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[index];
  }

  String _getDateForDay(int index) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final targetDay = monday.add(Duration(days: index));
    return targetDay.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: EcoColors.background,
        appBar: AppBar(
          backgroundColor: EcoColors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: EcoColors.onSurface),
          ),
          title: Text(
            'Sustainable Meal Planner',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: EcoColors.onSurface,
            ),
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Text('Sign in to plan your meals.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: EcoColors.onSurface),
        ),
        title: Text(
          'Sustainable Meal Planner',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Section 1: Recipe Library
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe Library',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: EcoColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _recipesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: EcoColors.primary),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading recipes',
                              style: GoogleFonts.inter(color: EcoColors.error),
                            ),
                          );
                        }

                        final recipes = snapshot.data ?? [];
                        if (recipes.isEmpty) {
                          return const Center(
                            child: Text('No recipes available'),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 16),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return Padding(
                              padding: EdgeInsets.only(right: index < recipes.length - 1 ? 12 : 0),
                              child: _RecipeCard(
                                title: recipe['title'] as String? ?? 'Untitled',
                                imageUrl: recipe['imageUrl'] as String? ?? '',
                                prepTime: recipe['prepTime'] as String? ?? '',
                                ecoBenefits: (recipe['ecoBenefits'] as List<dynamic>?)?.cast<String>() ?? [],
                                ingredients: (recipe['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
                                steps: (recipe['steps'] as List<dynamic>?)?.cast<String>() ?? [],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Section 2: Weekly Planner
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Planner',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: EcoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _mealPlansFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: EcoColors.primary),
                            );
                          }

                          final mealPlans = snapshot.data ?? [];
                          final mealPlansMap = <String, String>{};
                          for (final plan in mealPlans) {
                            mealPlansMap[plan['date'] as String] = plan['recipe_title'] as String;
                          }

                          return ListView.separated(
                            itemCount: 7,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final day = _getDayName(index);
                              final date = _getDateForDay(index);
                              final plannedMeal = mealPlansMap[date];

                              return _DayPlannerCard(
                                day: day,
                                plannedMeal: plannedMeal,
                                onAddTap: () => _showRecipeSelectionDialog(context, date, userId),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeSelectionDialog(BuildContext context, String date, String userId) async {
    final recipes = await _recipesFuture;
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Select a Recipe',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recipes.length,
            itemBuilder: (_, index) {
              final recipe = recipes[index];
              return ListTile(
                title: Text(recipe['title'] as String? ?? 'Untitled'),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await DatabaseService.instance.insertMealPlan(
                    userId,
                    date,
                    recipe['title'] as String? ?? '',
                  );
                  _loadData();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String prepTime;
  final List<String> ecoBenefits;
  final List<String> ingredients;
  final List<String> steps;

  const _RecipeCard({
    required this.title,
    required this.imageUrl,
    required this.prepTime,
    required this.ecoBenefits,
    required this.ingredients,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              title: title,
              icon: Icons.restaurant_rounded,
              prepTime: prepTime,
              ecoBenefits: ecoBenefits,
              ingredients: ingredients,
              steps: steps,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EcoColors.surfaceContainer),
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
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: EcoColors.surfaceContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 48,
                        color: EcoColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: EcoColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: EcoColors.primaryFixed.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 10,
                          color: EcoColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Low Carbon Impact',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            color: EcoColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPlannerCard extends StatelessWidget {
  final String day;
  final String? plannedMeal;
  final VoidCallback onAddTap;

  const _DayPlannerCard({
    required this.day,
    this.plannedMeal,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.surfaceContainer),
      ),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 60,
            child: Text(
              day,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: EcoColors.onSurface,
              ),
            ),
          ),
          // Meal slot
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: plannedMeal != null
                    ? EcoColors.primaryFixed.withValues(alpha: 0.2)
                    : EcoColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: plannedMeal != null
                      ? EcoColors.primary
                      : EcoColors.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                plannedMeal ?? 'No meal planned',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: plannedMeal != null
                      ? EcoColors.primary
                      : EcoColors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Assign button
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EcoColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: EcoColors.onPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
