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
  int _plannerRefreshKey = 0;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner'];

  void _refreshPlanner() {
    setState(() => _plannerRefreshKey++);
  }

  String _getDayName(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[index];
  }

  String _getDateForDay(int index) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final targetDay = monday.add(Duration(days: index));
    return targetDay.toIso8601String().split('T').first;
  }

  Future<void> _showCustomMealSheet(String userId, String date) async {
    final nameController = TextEditingController();
    String mealType = 'Lunch';

    await showModalBottomSheet<void>(
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
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
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
                    'Add Custom Meal',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EcoColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plan for ${_formatDisplayDate(date)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name',
                      labelStyle: GoogleFonts.inter(
                        color: EcoColors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: EcoColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EcoColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EcoColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: EcoColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Meal Type',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: _mealTypes
                        .map(
                          (t) => ButtonSegment<String>(
                            value: t,
                            label: Text(
                              t,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    selected: {mealType},
                    onSelectionChanged: (selected) {
                      setSheetState(() => mealType = selected.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFE8F5E9);
                        }
                        return EcoColors.surface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF2E7D32);
                        }
                        return EcoColors.onSurfaceVariant;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Enter a meal name',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: EcoColors.error,
                          ),
                        );
                        return;
                      }
                      await DatabaseService.instance.addPlannedMeal(
                        userId,
                        date,
                        mealType,
                        name,
                        isCustom: true,
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      _refreshPlanner();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added $name',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showRecipeSelectionDialog(
    BuildContext context,
    String date,
    String userId,
    List<Map<String, dynamic>> recipes,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: EcoColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Select a Recipe',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: EcoColors.onSurface,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: recipes.isEmpty
              ? Text(
                  'No recipes in library yet.',
                  style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (_, index) {
                    final recipe = recipes[index];
                    return ListTile(
                      title: Text(
                        recipe['title'] as String? ?? 'Untitled',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        recipe['prepTime'] as String? ?? '',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await DatabaseService.instance.addPlannedMeal(
                          userId,
                          date,
                          'Dinner',
                          recipe['title'] as String? ?? 'Untitled',
                          carbonKg: 0.5,
                          isCustom: false,
                        );
                        _refreshPlanner();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _formatDisplayDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return iso;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: EcoColors.background,
        appBar: _buildAppBar(),
        body: const SafeArea(
          child: Center(child: Text('Sign in to plan your meals.')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final today = DateTime.now().toIso8601String().split('T').first;
          _showCustomMealSheet(userId, today);
        },
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Custom Meal',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream:
                          FirestoreService.instance.watchRecipesWithFallback(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                            ),
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
                          return Center(
                            child: Text(
                              'No recipes available',
                              style: GoogleFonts.inter(
                                color: EcoColors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 16),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < recipes.length - 1 ? 12 : 0,
                              ),
                              child: SizedBox(
                                width: 160,
                                child: _RecipeCard(
                                  title: recipe['title'] as String? ?? 'Untitled',
                                  imageUrl: recipe['imageUrl'] as String? ?? '',
                                  prepTime: recipe['prepTime'] as String? ?? '',
                                  ecoBenefits: (recipe['ecoBenefits']
                                              as List<dynamic>?)
                                          ?.cast<String>() ??
                                      [],
                                  ingredients: (recipe['ingredients']
                                              as List<dynamic>?)
                                          ?.cast<String>() ??
                                      [],
                                  steps: (recipe['steps'] as List<dynamic>?)
                                          ?.cast<String>() ??
                                      [],
                                ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
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
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: FirestoreService.instance
                            .watchRecipesWithFallback(),
                        builder: (context, recipesSnapshot) {
                          final recipeList = recipesSnapshot.data ?? [];

                          return ListView.separated(
                            key: ValueKey(_plannerRefreshKey),
                            itemCount: 7,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final day = _getDayName(index);
                              final date = _getDateForDay(index);

                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: DatabaseService.instance
                                    .getPlannedMealsForDate(userId, date),
                                builder: (context, mealSnapshot) {
                                  if (mealSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return _DayPlannerCard(
                                      day: day,
                                      meals: const [],
                                      isLoading: true,
                                      onAddRecipe: () {},
                                      onAddCustom: () {},
                                    );
                                  }

                                  final meals = mealSnapshot.data ?? [];

                                  return _DayPlannerCard(
                                    day: day,
                                    meals: meals,
                                    onAddRecipe: () => _showRecipeSelectionDialog(
                                      context,
                                      date,
                                      userId,
                                      recipeList,
                                    ),
                                    onAddCustom: () =>
                                        _showCustomMealSheet(userId, date),
                                  );
                                },
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 120,
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 48,
                      color: Color(0xFF2E7D32),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          prepTime.isNotEmpty ? prepTime : 'Eco-friendly',
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
  final List<Map<String, dynamic>> meals;
  final bool isLoading;
  final VoidCallback onAddRecipe;
  final VoidCallback onAddCustom;

  const _DayPlannerCard({
    required this.day,
    required this.meals,
    this.isLoading = false,
    required this.onAddRecipe,
    required this.onAddCustom,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: EcoColors.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onAddRecipe,
                icon: const Icon(Icons.menu_book_outlined,
                    color: EcoColors.primary, size: 20),
                tooltip: 'Add from library',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: onAddCustom,
                icon: const Icon(Icons.add_rounded,
                    color: EcoColors.primary, size: 22),
                tooltip: 'Add custom meal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            )
          else if (meals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: EcoColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EcoColors.outlineVariant),
              ),
              child: Text(
                'No meals planned',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: EcoColors.outline,
                ),
              ),
            )
          else
            ...meals.map((meal) {
              final title = meal['recipe_title'] as String? ?? 'Meal';
              final mealType = meal['meal_type'] as String? ?? 'Dinner';
              final isCustom = (meal['is_custom'] as int? ?? 0) == 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isCustom)
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.restaurant,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          mealType.isNotEmpty ? mealType[0] : 'R',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
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
                          ),
                          Text(
                            mealType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: EcoColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
