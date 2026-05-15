import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      children: const [
                        _RecipeCard(
                          title: 'Lentil Stew',
                          icon: Icons.restaurant_rounded,
                          prepTime: '25 mins',
                          ecoBenefits: ['Low Carbon Impact', 'Plant-Based'],
                          ingredients: ['2 cups lentils', '1 onion', '2 carrots', '3 celery stalks', '4 cups vegetable broth'],
                          steps: ['Rinse lentils thoroughly', 'Chop vegetables', 'Sauté onions and carrots', 'Add lentils and broth', 'Simmer for 25 minutes'],
                        ),
                        SizedBox(width: 12),
                        _RecipeCard(
                          title: 'Zero-Waste Veggie Wrap',
                          icon: Icons.wrap_text_rounded,
                          prepTime: '15 mins',
                          ecoBenefits: ['Zero Waste', 'Plant-Based'],
                          ingredients: ['Whole wheat tortilla', 'Leftover vegetables', 'Hummus', 'Fresh herbs'],
                          steps: ['Warm tortilla', 'Spread hummus', 'Add vegetables', 'Roll tightly', 'Cut in half'],
                        ),
                        SizedBox(width: 12),
                        _RecipeCard(
                          title: 'Locally Sourced Salad',
                          icon: Icons.eco_rounded,
                          prepTime: '10 mins',
                          ecoBenefits: ['Local Ingredients', 'Low Carbon Impact'],
                          ingredients: ['Mixed greens', 'Local tomatoes', 'Cucumber', 'Olive oil', 'Lemon juice'],
                          steps: ['Wash vegetables', 'Chop into bite-sized pieces', 'Mix in bowl', 'Drizzle with dressing', 'Serve fresh'],
                        ),
                        SizedBox(width: 12),
                        _RecipeCard(
                          title: 'Seasonal Soup',
                          icon: Icons.soup_kitchen_rounded,
                          prepTime: '30 mins',
                          ecoBenefits: ['Seasonal Ingredients', 'Plant-Based'],
                          ingredients: ['Seasonal vegetables', 'Vegetable stock', 'Herbs', 'Garlic', 'Olive oil'],
                          steps: ['Prepare seasonal vegetables', 'Sauté garlic', 'Add vegetables and stock', 'Simmer until tender', 'Blend if desired'],
                        ),
                      ],
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
                      child: ListView.separated(
                        itemCount: 7,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _DayPlannerCard(
                          day: _getDayName(index),
                        ),
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

  String _getDayName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[index];
  }
}

class _RecipeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String prepTime;
  final List<String> ecoBenefits;
  final List<String> ingredients;
  final List<String> steps;

  const _RecipeCard({
    required this.title,
    required this.icon,
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
              icon: icon,
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
            // Placeholder image icon
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: EcoColors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 48,
                    color: EcoColors.primary,
                  ),
                ),
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

  const _DayPlannerCard({required this.day});

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
                color: EcoColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EcoColors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                'No meal planned',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: EcoColors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Assign button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select a recipe from the library above',
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
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
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
