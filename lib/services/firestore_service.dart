import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database_service.dart';
import 'offline_sync_service.dart';

/// Firestore SSOT for user profile state and educational content.
class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String contentCollection = 'content';
  static const String usersCollection = 'users';
  static const String recipesCollection = 'recipes';
  static const String communityCollection = 'community_posts';
  static const String galleryCollection = 'gallery';
  static const String challengesCollection = 'challenges';

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(usersCollection).doc(userId);

  static Map<String, dynamic> _defaultUserFields(User user) => {
        'displayName': user.displayName ?? 'Eco-Warrior',
        'email': user.email,
        'goalTitle': 'Reduce Waste',
        'notificationsEnabled': true,
        'tasksCompleted': 0,
        'currentStreak': 0,
        'savedTips': <String>[],
        'activeChallenges': <String>[],
        'co2Saved': 0.0,
        'co2SavedLastMonth': 0.0,
        'changePercent': 12,
        'waterSaved': 0.0,
        'energySaved': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Creates or repairs `users/{uid}` so dashboard modules share one SSOT shape.
  Future<void> syncUserDocument(User user) async {
    final ref = _userRef(user.uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set(_defaultUserFields(user));
      return;
    }

    final data = snapshot.data() ?? {};
    final patch = <String, dynamic>{};
    for (final entry in _defaultUserFields(user).entries) {
      if (!data.containsKey(entry.key)) {
        patch[entry.key] = entry.value;
      }
    }
    if (user.displayName != null &&
        user.displayName!.isNotEmpty &&
        (data['displayName'] == null ||
            (data['displayName'] as String).trim().isEmpty)) {
      patch['displayName'] = user.displayName;
    }
    if (patch.isNotEmpty) {
      patch['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(patch, SetOptions(merge: true));
    }
  }

  /// Real-time user profile / progress document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _userRef(userId).snapshots();
  }

  Future<void> toggleSaveTip(
    String userId,
    String tipId,
    bool isSaving,
  ) async {
    final ref = _userRef(userId);
    final update = {
      'savedTips': isSaving
          ? FieldValue.arrayUnion([tipId])
          : FieldValue.arrayRemove([tipId]),
    };

    try {
      await ref.update(update);
    } catch (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await syncUserDocument(user);
      }
      await ref.update(update);
    }
  }

  /// Called after successful SQLite activity logs (offline-first, cloud SSOT).
  Future<void> incrementTasksCompleted(
    String userId, {
    double co2 = 0.0,
    double water = 0.0,
    double energy = 0.0,
    int? currentStreak,
  }) async {
    final updateData = <String, dynamic>{
      'tasksCompleted': FieldValue.increment(1),
      if (co2 > 0) 'co2Saved': FieldValue.increment(co2),
      if (water > 0) 'waterSaved': FieldValue.increment(water),
      if (energy > 0) 'energySaved': FieldValue.increment(energy),
      if (currentStreak != null) 'currentStreak': currentStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection(usersCollection).doc(userId).update(updateData);
    } catch (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await syncUserDocument(user);
      }
      await _firestore.collection(usersCollection).doc(userId).set(
        {
          ...updateData,
          'savedTips': <String>[],
          'goalTitle': 'Reduce Waste',
          'notificationsEnabled': true,
          'activeChallenges': <String>[],
          if (!updateData.containsKey('co2Saved')) 'co2Saved': 0.0,
          if (!updateData.containsKey('waterSaved')) 'waterSaved': 0.0,
          if (!updateData.containsKey('energySaved')) 'energySaved': 0.0,
          if (currentStreak == null) 'currentStreak': 0,
        },
        SetOptions(merge: true),
      );
    }
  }

  static double waterSavedFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 0;
    final value = snapshot.data()?['waterSaved'];
    if (value is num) return value.toDouble();
    return 0;
  }

  static double energySavedFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 0;
    final value = snapshot.data()?['energySaved'];
    if (value is num) return value.toDouble();
    return 0;
  }

  static List<String> savedTipsFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return const [];
    final raw = snapshot.data()?['savedTips'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static int tasksCompletedFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 0;
    final value = snapshot.data()?['tasksCompleted'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int currentStreakFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 0;
    final value = snapshot.data()?['currentStreak'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double co2SavedFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 0;
    final value = snapshot.data()?['co2Saved'];
    if (value is num) return value.toDouble();
    return 0;
  }

  static int changePercentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return 12;
    final value = snapshot.data()?['changePercent'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 12;
  }

  static Set<String> activeChallengesFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    if (snapshot == null || !snapshot.exists) return {};
    final raw = snapshot.data()?['activeChallenges'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return {};
  }

  // ── Community forum ─────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getCommunityPosts() {
    return _firestore
        .collection(communityCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addCommunityPost(String userName, String message) async {
    await _firestore.collection(communityCollection).add({
      'userName': userName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'likeCount': 0,
    });
  }

  // ── Image gallery ───────────────────────────────────────────────────────

  Future<List<String>> getGalleryImages() async {
    final snapshot = await _firestore.collection(galleryCollection).get();

    final urls = snapshot.docs
        .map((doc) => doc.data()['imageUrl'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return urls;
  }

  Future<void> seedGallery() async {
    final snapshot =
        await _firestore.collection(galleryCollection).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final collection = _firestore.collection(galleryCollection);

    for (final item in _gallerySeedItems) {
      final ref = collection.doc();
      batch.set(ref, item);
    }

    await batch.commit();
  }

  static final List<Map<String, dynamic>> _gallerySeedItems = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800&q=80',
      'title': 'Solar rooftop garden',
      'tag': 'energy',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800&q=80',
      'title': 'Zero-waste kitchen',
      'tag': 'home',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
      'title': 'Urban cycling commute',
      'tag': 'mobility',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1620626011761-996317702782?w=800&q=80',
      'title': 'Rainwater collection',
      'tag': 'water',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&q=80',
      'title': 'Community compost hub',
      'tag': 'food',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
      'title': 'Native wildflower meadow',
      'tag': 'nature',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=800&q=80',
      'title': 'Reusable market haul',
      'tag': 'products',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1466611653911-950815379e6b?w=800&q=80',
      'title': 'Wind farm at dusk',
      'tag': 'energy',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80',
      'title': 'Bamboo utensil set',
      'tag': 'products',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80',
      'title': 'Forest trail stewardship',
      'tag': 'nature',
    },
  ];

  /// Fetches documents from [contentCollection].
  /// Pass [category] `all` to return every document; otherwise filters by
  /// `products`, `certifications`, `energy_tips`, `travel`, or `general_education`.
  Future<List<Map<String, dynamic>>> getEducationalContent(
    String category,
  ) async {
    final normalized = category.trim().toLowerCase();

    Query<Map<String, dynamic>> query =
        _firestore.collection(contentCollection);

    if (normalized != 'all') {
      query = query.where('category', isEqualTo: normalized);
    }

    final snapshot = await query.get();

    final items = snapshot.docs
        .map(
          (doc) => <String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          },
        )
        .toList();

    items.sort(
      (a, b) => (a['title'] as String? ?? '')
          .toLowerCase()
          .compareTo((b['title'] as String? ?? '').toLowerCase()),
    );

    return items;
  }

  /// Seeds [contentCollection] when empty (for local / QA testing).
  Future<void> seedFirestoreData() async {
    final snapshot =
        await _firestore.collection(contentCollection).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final collection = _firestore.collection(contentCollection);

    for (final doc in _seedDocuments) {
      final ref = collection.doc();
      batch.set(ref, doc);
    }

    await batch.commit();
  }

  /// Fetches all recipes from the recipes collection.
  Future<List<Map<String, dynamic>>> getRecipes() async {
    final snapshot = await _firestore.collection(recipesCollection).get();

    final items = snapshot.docs
        .map(
          (doc) => <String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          },
        )
        .toList();

    items.sort(
      (a, b) => (a['title'] as String? ?? '')
          .toLowerCase()
          .compareTo((b['title'] as String? ?? '').toLowerCase()),
    );

    return items;
  }

  /// Legacy entry point — delegates to [seedProductionData] for SSOT recipe IDs.
  Future<void> seedRecipes() async {
    await seedProductionData();
  }

  /// Live recipe library stream (Meal Planner / detail screens).
  Stream<QuerySnapshot<Map<String, dynamic>>> getRecipesStream() {
    return _firestore
        .collection(recipesCollection)
        .orderBy('title')
        .snapshots();
  }

  Future<Map<String, dynamic>?> getChallengeById(String challengeId) async {
    final doc = await _firestore
        .collection(challengesCollection)
        .doc(challengeId)
        .get();
    if (!doc.exists) return null;
    return {...?doc.data(), 'id': doc.id};
  }

  static final List<Map<String, dynamic>> _seedDocuments = [
    // ── products ──────────────────────────────────────────────────────────
    {
      'category': 'products',
      'title': 'Reusable Bamboo Utensils',
      'summary':
          'Lightweight bamboo cutlery sets replace disposable plastic forks and spoons on the go.',
      'savingsLabel': 'Avoids ~150 plastic utensils/year',
      'imageUrl':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80',
      'steps': [
        {
          'title': 'Keep a set in your bag',
          'description':
              'Store a fork, knife, and spoon pouch in your everyday carry so takeout stays plastic-free.',
        },
        {
          'title': 'Rinse and air-dry',
          'description':
              'A quick rinse after meals keeps bamboo fresh; dry fully before closing the pouch.',
        },
      ],
    },
    {
      'category': 'products',
      'title': 'Refillable Glass Water Bottle',
      'summary':
          'Durable borosilicate bottles cut single-use plastic and keep drinks tasting clean.',
      'savingsLabel': 'Saves ~167 bottles/person/year',
      'imageUrl':
          'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&q=80',
      'steps': [
        {
          'title': 'Fill before you leave',
          'description':
              'Make refilling part of your morning routine to avoid buying bottled water.',
        },
        {
          'title': 'Use café refill stations',
          'description':
              'Many coffee shops offer free tap refills—look for Refill or Tap signs.',
        },
      ],
    },
    {
      'category': 'products',
      'title': 'Organic Cotton Tote Bags',
      'summary':
          'GOTS-certified cotton totes last for years and replace hundreds of plastic bags.',
      'savingsLabel': 'Replaces 500+ plastic bags over lifetime',
      'imageUrl':
          'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=800&q=80',
      'steps': [
        {
          'title': 'Fold one into every bag',
          'description':
              'A compact tote in your backpack means you are never caught at checkout without one.',
        },
      ],
    },
    // ── certifications ────────────────────────────────────────────────────
    {
      'category': 'certifications',
      'title': 'ENERGY STAR Appliances',
      'summary':
          'EPA-certified products use 10–50% less energy than standard models without sacrificing performance.',
      'savingsLabel': 'Up to 50% lower energy use',
      'imageUrl':
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
      'steps': [
        {
          'title': 'Look for the blue label',
          'description':
              'The ENERGY STAR mark on fridges, washers, and dishwashers signals verified efficiency.',
        },
        {
          'title': 'Compare annual kWh',
          'description':
              'Use the yellow EnergyGuide tag to pick the lowest estimated yearly consumption.',
        },
      ],
    },
    {
      'category': 'certifications',
      'title': 'Fair Trade Certified Coffee',
      'summary':
          'Fair Trade standards ensure farmers receive fair wages and farms follow environmental practices.',
      'savingsLabel': 'Supports ethical supply chains',
      'imageUrl':
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
      'steps': [
        {
          'title': 'Check the package seal',
          'description':
              'The Fair Trade Certified mark appears on bags and pods from participating roasters.',
        },
      ],
    },
    {
      'category': 'certifications',
      'title': 'Forest Stewardship Council (FSC) Paper',
      'summary':
          'FSC-labeled paper and packaging come from responsibly managed forests with chain-of-custody tracking.',
      'savingsLabel': 'Protects biodiversity & watersheds',
      'imageUrl':
          'https://images.unsplash.com/photo-1456513088650-7bf4988fb84c?w=800&q=80',
      'steps': [
        {
          'title': 'Choose FSC on office supplies',
          'description':
              'Notebooks, printer paper, and shipping boxes often display the FSC tree logo.',
        },
      ],
    },
    // ── energy_tips ─────────────────────────────────────────────────────────
    {
      'category': 'energy_tips',
      'title': 'Switch to LED Bulbs',
      'summary':
          'LEDs use up to 90% less energy than incandescent bulbs and last 15+ years.',
      'savingsLabel': '~40 kg CO₂/year per home',
      'imageUrl':
          'https://images.unsplash.com/photo-1558449028-b53a9d771b3f?w=800&q=80',
      'steps': [
        {
          'title': 'Replace high-use rooms first',
          'description':
              'Kitchen, living room, and porch lights deliver the fastest payback.',
        },
        {
          'title': 'Match brightness (lumens)',
          'description':
              'Pick LEDs with similar lumens to your old bulbs for the same light level.',
        },
      ],
    },
    {
      'category': 'energy_tips',
      'title': 'Smart Thermostat Scheduling',
      'summary':
          'Program lower temps when asleep or away to trim heating and cooling bills.',
      'savingsLabel': '~8% on heating/cooling',
      'imageUrl':
          'https://images.unsplash.com/photo-1558002038-1055907df827?w=800&q=80',
      'steps': [
        {
          'title': 'Set eco mode at night',
          'description':
              'Drop 2–3°F while sleeping; most people sleep better with slightly cooler air.',
        },
        {
          'title': 'Use geofencing if available',
          'description':
              'Let the thermostat ease off when your phone leaves home automatically.',
        },
      ],
    },
    {
      'category': 'energy_tips',
      'title': 'Line-Dry Laundry',
      'summary':
          'Air-drying clothes skips dryer heat entirely and extends fabric life.',
      'savingsLabel': '~300 kg CO₂/year (avg household)',
      'imageUrl':
          'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
      'steps': [
        {
          'title': 'Use a rack indoors',
          'description':
              'Folding racks work in apartments; spin cycles well to reduce drying time.',
        },
      ],
    },
    // ── travel ──────────────────────────────────────────────────────────────
    {
      'category': 'travel',
      'title': 'Public Transit Guide',
      'summary':
          'Buses and trains emit a fraction of the CO₂ per mile compared with solo driving.',
      'savingsLabel': '~45% lower trip emissions',
      'imageUrl':
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
      'steps': [
        {
          'title': 'Plan one route ahead',
          'description':
              'Save your usual commute in a transit app to see live arrivals and delays.',
        },
        {
          'title': 'Combine with biking',
          'description':
              'First/last mile by bike or scooter makes longer transit lines practical.',
        },
      ],
    },
    {
      'category': 'travel',
      'title': 'Train Over Short-Haul Flights',
      'summary':
          'Rail journeys under 500 miles often beat flying on time, cost, and carbon when city centers connect.',
      'savingsLabel': 'Up to 90% less CO₂ vs flying',
      'imageUrl':
          'https://images.unsplash.com/photo-1474487548417-9cb5a7a7a27e?w=800&q=80',
      'steps': [
        {
          'title': 'Book early for best fares',
          'description':
              'Advance tickets on intercity rail are often cheaper than last-minute flights.',
        },
      ],
    },
    {
      'category': 'travel',
      'title': 'Eco-Friendly Hotel Stays',
      'summary':
          'Green Key and LEED-certified hotels reduce water, energy, and waste through verified programs.',
      'savingsLabel': 'Lower per-night footprint',
      'imageUrl':
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
      'steps': [
        {
          'title': 'Skip daily linen service',
          'description':
              'Reuse towels and sheets—housekeeping only when needed saves water and detergent.',
        },
        {
          'title': 'Bring your toiletries',
          'description':
              'Small refillable bottles avoid single-use hotel mini plastics.',
        },
      ],
    },
    // ── general_education ─────────────────────────────────────────────────
    {
      'category': 'general_education',
      'title': 'Understanding Your Carbon Footprint',
      'summary':
          'A carbon footprint totals greenhouse gases from energy, food, travel, and goods you consume.',
      'savingsLabel': 'Foundation for smarter choices',
      'imageUrl':
          'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
      'steps': [
        {
          'title': 'Track your top three sources',
          'description':
              'Home energy, diet, and transport usually dominate—measure before optimizing.',
        },
        {
          'title': 'Set one realistic goal',
          'description':
              'Small consistent changes beat ambitious plans you cannot sustain.',
        },
      ],
    },
    {
      'category': 'general_education',
      'title': 'The Three R\'s: Reduce, Reuse, Recycle',
      'summary':
          'Waste hierarchy prioritizes using less first, reusing items second, and recycling last.',
      'savingsLabel': 'Less landfill, less extraction',
      'imageUrl':
          'https://images.unsplash.com/photo-1532996122724-e3c354a0e0f0?w=800&q=80',
      'steps': [
        {
          'title': 'Reduce at the source',
          'description':
              'Buy durable goods and avoid excess packaging before thinking about recycling.',
        },
        {
          'title': 'Recycle correctly',
          'description':
              'Rinse containers and check local rules—contamination can spoil whole batches.',
        },
      ],
    },
    {
      'category': 'general_education',
      'title': 'Biodiversity and Everyday Choices',
      'summary':
          'Protecting habitats and pollinators starts with food, landscaping, and consumption habits at home.',
      'savingsLabel': 'Supports ecosystem health',
      'imageUrl':
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
      'steps': [
        {
          'title': 'Plant native species',
          'description':
              'Native flowers need less water and feed local bees and butterflies.',
        },
      ],
    },
  ];

  /// Live stream of challenges (SSOT). Ordered for stable UI.
  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveChallengesStream() {
    return _firestore
        .collection(challengesCollection)
        .orderBy('title')
        .snapshots();
  }

  Future<void> _setById(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data)..remove('id');
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(payload, SetOptions(merge: true));
  }

  /// Master seeding function for production data.
  /// Seeds recipes, challenges, and content collections, strictly setting document IDs to prevent duplicates.
  Future<void> seedProductionData() async {
    // 1. Recipes Seed Data (from testdata.txt)
    final List<Map<String, dynamic>> recipes = [
      {
        'id': 'REC001',
        'title': 'One-Pot Lentil & Vegetable Curry',
        'category': 'Plant-Based Main',
        'prepTime': '15 mins',
        'prep_time_minutes': 15,
        'cook_time_minutes': 30,
        'servings': 4,
        'difficulty': 'Easy',
        'description': 'A hearty, protein-rich curry using pantry staples and seasonal vegetables. Perfect for meal prep!',
        'ingredients': [
          'Red lentils (Legumes fix nitrogen in soil, reducing fertilizer needs)',
          'Coconut milk (Choose brands with sustainable palm oil policies)',
          'Seasonal vegetables (Buy local/seasonal to reduce transport emissions)',
          'Onion, garlic, ginger',
          'Spices (Buy in bulk to reduce packaging waste)'
        ],
        'steps': [
          'Sauté aromatics in 1 tbsp oil until fragrant',
          'Add lentils, spices, and 3 cups water; simmer 20 mins',
          'Stir in vegetables and coconut milk; cook 10 more mins',
          'Season with salt, lemon juice, and fresh cilantro'
        ],
        'ecoBenefits': [
          'Plant-based meal saves ~4kg CO₂ vs. beef equivalent',
          'One-pot cooking reduces water/energy for cleanup',
          'Uses affordable, shelf-stable ingredients to reduce food waste'
        ],
        'imageUrl': 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800',
        'user_rating': 4.8,
        'tags': ['vegan', 'gluten-free', 'high-protein', 'budget', 'meal-prep']
      },
      {
        'id': 'REC002',
        'title': 'Zero-Waste Vegetable Scrap Broth',
        'category': 'Foundation Recipe',
        'prepTime': '10 mins',
        'prep_time_minutes': 10,
        'cook_time_minutes': 45,
        'servings': 8,
        'difficulty': 'Easy',
        'description': 'Transform onion skins, carrot tops, and herb stems into a flavorful, nutrient-rich broth—no waste!',
        'ingredients': [
          'Vegetable scraps (onion skins, carrot peels, celery leaves, mushroom stems)',
          'Garlic cloves (peels OK)',
          'Bay leaf, peppercorns, thyme',
          'Water (filtered tap water instead of bottled)'
        ],
        'steps': [
          'Combine all scraps and aromatics in large pot',
          'Cover with cold water; bring to boil, then reduce to simmer',
          'Simmer uncovered 45 mins, skimming foam occasionally',
          'Strain through fine mesh; cool and store in jars or freeze'
        ],
        'ecoBenefits': [
          'Diverts ~1 lb food scraps from landfill per batch',
          'Reduces need for store-bought broth (and its packaging)',
          'Captures nutrients often discarded with peels/stems'
        ],
        'imageUrl': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800',
        'user_rating': 4.9,
        'tags': ['zero-waste', 'vegan', 'gluten-free', 'foundation', 'budget']
      },
      {
        'id': 'REC003',
        'title': 'Seasonal Grain Bowl Builder',
        'category': 'Flexible Template',
        'prepTime': '20 mins',
        'prep_time_minutes': 20,
        'cook_time_minutes': 25,
        'servings': 2,
        'difficulty': 'Easy',
        'description': 'A customizable formula for nutritious, low-waste meals using whatever is in season and on hand.',
        'ingredients': [
          'Cooked grains (quinoa, farro, brown rice)',
          'Plant protein (beans, lentils, tofu, tempeh)',
          'Seasonal vegetables (roasted, raw, or fermented)',
          'Healthy fat (avocado, seeds, tahini)',
          'Flavor boost (herbs, citrus, vinegar, or homemade dressing)'
        ],
        'steps': [
          'Cook grains according to package instructions',
          'Prepare your chosen protein and vegetables',
          'Assemble all components in a wide serving bowl',
          'Drizzle with dressing, sprinkle seeds, and serve'
        ],
        'ecoBenefits': [
          'Reduces food waste by using imperfect or surplus produce',
          'Plant-forward formula lowers carbon footprint vs. meat-centric meals',
          'Encourages seasonal eating, supporting local agriculture'
        ],
        'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800',
        'user_rating': 4.7,
        'tags': ['template', 'plant-based', 'seasonal', 'meal-prep', 'customizable']
      }
    ];

    // 2. Challenges Seed Data (from testdata.txt)
    final List<Map<String, dynamic>> challenges = [
      {
        'id': 'CH001',
        'title': 'Plastic-Free January Challenge',
        'description': 'Go a month without single-use plastics. Track your swaps, use reusables, and build sustainable habits!',
        'duration_days': 30,
        'difficulty': 'Intermediate',
        'category': 'Waste Reduction',
        'tasks': [
          'Bring reusable bags to all shopping trips',
          'Use a refillable water bottle daily',
          'Refuse plastic straws and cutlery',
          'Choose package-free produce',
          'Pack lunch in reusable containers'
        ],
        'rewards': {
          'points': 150,
          'badge': 'Plastic Warrior 🌊',
          'impact_estimate': 'Prevents ~100 plastic items from entering landfills'
        },
        'tips': [
          'Keep a zero-waste kit in your bag: utensils, napkin, container',
          'Shop bulk bins with your own jars',
          'Choose bar soap/shampoo over bottled versions'
        ],
        'prerequisite_level': 1,
        'image_url': 'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=800&q=80'
      },
      {
        'id': 'CH002',
        'title': 'Meatless Monday Kickstart',
        'description': 'Replace meat with plant-based proteins one day per week. Discover delicious, low-carbon alternatives!',
        'duration_days': 30,
        'difficulty': 'Beginner',
        'category': 'Sustainable Eating',
        'tasks': [
          'Plan meatless dinners (one per week)',
          'Try 2 new plant-based recipes',
          'Research the water footprint of beef vs. beans',
          'Share one meatless meal photo in the community'
        ],
        'rewards': {
          'points': 120,
          'badge': 'Plant Pioneer 🌱',
          'impact_estimate': 'Saves ~1,200 gallons of water and 24kg CO2'
        },
        'tips': [
          'Start with familiar dishes like pasta, stir-fries, tacos with lentils',
          'Batch-cook grains and beans for easy meal assembly',
          'Explore local farmers markets for fresh produce'
        ],
        'prerequisite_level': 0,
        'image_url': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80'
      },
      {
        'id': 'CH003',
        'title': 'Home Energy Sprint',
        'description': 'Cut household energy use by implementing 5 changes to reduce your utility bills and carbon footprint over 14 days.',
        'duration_days': 14,
        'difficulty': 'Advanced',
        'category': 'Energy Conservation',
        'tasks': [
          'Conduct a home energy audit using the app checklist',
          'Switch 5 bulbs to LED',
          'Unplug vampire electronics overnight',
          'Adjust thermostat by 2°F (summer/winter)',
          'Run dishwasher/washer only with full loads'
        ],
        'rewards': {
          'points': 200,
          'badge': 'Energy Guardian ⚡',
          'impact_estimate': 'Potential savings: 15% on electricity bills'
        },
        'tips': [
          'Use smart power strips to eliminate phantom loads',
          'Air-dry clothes when possible',
          'Seal windows and doors to prevent energy leaks'
        ],
        'prerequisite_level': 2,
        'image_url': 'https://images.unsplash.com/photo-1558449028-b53a9d771b3f?w=800&q=80'
      },
      {
        'id': 'CH004',
        'title': 'Compost Starter Challenge',
        'description': 'Begin composting food scraps at home. Learn the basics, choose your system, and feed the soil.',
        'duration_days': 21,
        'difficulty': 'Intermediate',
        'category': 'Waste Reduction',
        'tasks': [
          'Choose a composting method (bin, tumbler, vermicompost)',
          'Collect greens and browns for 3 weeks',
          'Turn your pile twice weekly',
          'Log diverted food waste in the tracker',
          'Share progress photo in community'
        ],
        'rewards': {
          'points': 175,
          'badge': 'Soil Savior 🪱',
          'impact_estimate': 'Diverts ~15kg food waste from landfill; creates nutrient-rich soil'
        },
        'tips': [
          'Balance 3 parts browns (leaves, paper) to 1 part greens (scraps)',
          'Avoid meat, dairy, and oils in home compost',
          'Keep pile moist like a wrung-out sponge'
        ],
        'prerequisite_level': 1,
        'image_url': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&q=80'
      }
    ];

    // 3. Content Seed Data (Educational Articles, Certs, Energy, Travel, Products)
    final List<Map<String, dynamic>> content = [
      // Reusable Products
      {
        'id': 'EP001',
        'category': 'products',
        'title': 'HydroFlask Steel Bottle',
        'summary': '32oz insulated bottle keeps drinks cold for 24hrs. Eliminates ~156 plastic bottles/year.',
        'savingsLabel': 'Saves ~156 plastic bottles/year',
        'imageUrl': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&q=80',
        'steps': [
          {'title': 'Keep insulated water bottle handy', 'description': 'Refill at tap and avoid single-use plastics.'}
        ]
      },
      {
        'id': 'EP002',
        'category': 'products',
        'title': 'Organic Cotton Produce Bags',
        'summary': 'Lightweight, washable mesh bags for groceries. Replaces 500+ single-use plastic bags.',
        'savingsLabel': 'Replaces 500+ single-use bags',
        'imageUrl': 'https://images.unsplash.com/photo-1591195853828-11ad59a44f6b?w=800&q=80',
        'steps': [
          {'title': 'Pack produce bags', 'description': 'Store in tote bag so you always have them at checkout.'}
        ]
      },
      // Certifications
      {
        'id': 'CERT001',
        'category': 'certifications',
        'title': 'ENERGY STAR Certification',
        'summary': 'Certifies appliances and electronics that meet strict EPA energy efficiency guidelines.',
        'savingsLabel': 'Uses 10-50% less energy',
        'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
        'steps': [
          {'title': 'Check for blue star label', 'description': 'Save energy and bills by choosing certified models.'}
        ]
      },
      {
        'id': 'CERT003',
        'category': 'certifications',
        'title': 'Fair Trade Certified',
        'summary': 'Guarantees fair wages, safe working conditions, and environmental protection.',
        'savingsLabel': 'Ethical supply chains',
        'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
        'steps': [
          {'title': 'Support Fair Trade farmers', 'description': 'Look for the circular seal on coffee, tea, and chocolate.'}
        ]
      },
      // Energy Tips
      {
        'id': 'ET001',
        'category': 'energy_tips',
        'title': 'Switch to LED Bulbs',
        'summary': 'Replace incandescent bulbs with ENERGY STAR-certified LEDs to save 75% energy.',
        'savingsLabel': 'Saves ~\$55/year per household',
        'imageUrl': 'https://images.unsplash.com/photo-1558449028-b53a9d771b3f?w=800&q=80',
        'steps': [
          {'title': 'Upgrade light fixtures', 'description': 'Switching to LEDs immediately lowers energy draw.'}
        ]
      },
      {
        'id': 'ET002',
        'category': 'energy_tips',
        'title': 'Optimize Thermostat Settings',
        'summary': 'Adjust thermostat by 7-10°F for 8 hours/day to save up to 10% on heating and cooling.',
        'savingsLabel': 'Saves up to 10% on utility bills',
        'imageUrl': 'https://images.unsplash.com/photo-1558002038-1055907df827?w=800&q=80',
        'steps': [
          {'title': 'Automate settings', 'description': 'Set slightly cooler in winter, warmer in summer.'}
        ]
      },
      // Travel Tips
      {
        'id': 'TR001',
        'category': 'travel',
        'title': 'Choose Train Commuting',
        'summary': 'Rail travel produces 75% less CO₂ emissions per passenger-mile than driving alone.',
        'savingsLabel': 'Produces 75% less CO₂ emissions',
        'imageUrl': 'https://images.unsplash.com/photo-1474487548417-9cb5a7a7a27e?w=800&q=80',
        'steps': [
          {'title': 'Take the train', 'description': 'A green commute alternative for medium-to-long city transits.'}
        ]
      },
      // Educational Articles
      {
        'id': 'EDU001',
        'category': 'general_education',
        'title': 'The True Cost of Fast Fashion',
        'summary': 'The fashion industry produces 10% of global emissions. Learn how to build a durable wardrobe.',
        'savingsLabel': 'Reduces clothing footprint',
        'imageUrl': 'https://images.unsplash.com/photo-1532996122724-e3c354a0e0f0?w=800&q=80',
        'steps': [
          {'title': 'Buy high-quality secondhand', 'description': 'Extend garments life by 2.2 years to cut carbon footprint.'}
        ]
      },
      {
        'id': 'EDU002',
        'category': 'general_education',
        'title': 'Home Composting 101',
        'summary': 'A complete visual guide to turn kitchen scraps into nutrient-rich soil gold.',
        'savingsLabel': 'Soil revitalization & carbon capture',
        'imageUrl': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&q=80',
        'steps': [
          {'title': 'Balance greens and browns', 'description': 'Maintain healthy ventilation and moisture levels.'}
        ]
      }
    ];

    for (final recipe in recipes) {
      await _setById(
        recipesCollection,
        recipe['id'] as String,
        recipe,
      );
    }

    for (final challenge in challenges) {
      final withActive = Map<String, dynamic>.from(challenge)
        ..putIfAbsent('is_active', () => true);
      await _setById(
        challengesCollection,
        challenge['id'] as String,
        withActive,
      );
    }

    for (final item in content) {
      await _setById(
        contentCollection,
        item['id'] as String,
        item,
      );
    }
  }

  /// Dual-write join: SQLite `user_challenge` + Firestore `activeChallenges`.
  Future<void> joinChallenge(String userId, String challengeId) async {
    final ref = _userRef(userId);
    final snapshot = await ref.get();
    final joined = activeChallengesFromSnapshot(snapshot);
    if (joined.contains(challengeId)) {
      return;
    }

    await DatabaseService.instance.joinChallenge(userId, challengeId);

    try {
      await ref.update({
        'activeChallenges': FieldValue.arrayUnion([challengeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await syncUserDocument(user);
      }
      await ref.set(
        {
          'activeChallenges': FieldValue.arrayUnion([challengeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  /// Check if device has usable network connectivity.
  Future<bool> isDeviceOnline() async {
    final result = await Connectivity().checkConnectivity();
    return OfflineSyncService.hasNetwork(result);
  }

  Future<bool> _isOnline() => isDeviceOnline();

  Future<List<Map<String, dynamic>>> _cachedOrRemote({
    required Future<List<Map<String, dynamic>>> Function() remote,
    required Future<List<Map<String, dynamic>>> Function() cached,
  }) async {
    final cache = await cached();
    if (!await _isOnline()) {
      return cache;
    }
    try {
      final live = await remote();
      if (live.isNotEmpty) return live;
      if (cache.isNotEmpty) return cache;
      return live;
    } catch (_) {
      return cache;
    }
  }

  /// Get recipes with offline fallback.
  Future<List<Map<String, dynamic>>> getRecipesWithFallback() async {
    return _cachedOrRemote(
      remote: getRecipes,
      cached: OfflineSyncService.instance.getCachedRecipes,
    );
  }

  /// Get challenges with offline fallback.
  Future<List<Map<String, dynamic>>> getChallengesWithFallback() async {
    return _cachedOrRemote(
      remote: () async {
        final snapshot = await getActiveChallengesStream().first;
        return snapshot.docs
            .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
            .toList();
      },
      cached: OfflineSyncService.instance.getCachedChallenges,
    );
  }

  /// Get educational content with offline fallback.
  Future<List<Map<String, dynamic>>> getContentWithFallback(
    String category,
  ) async {
    return _cachedOrRemote(
      remote: () => getEducationalContent(category),
      cached: () =>
          OfflineSyncService.instance.getCachedContent(category: category),
    );
  }

  /// Get gallery image URLs with offline fallback.
  Future<List<String>> getGalleryWithFallback() async {
    final items = await getGalleryItemsWithFallback();
    return items
        .map((e) => e['imageUrl'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// Full gallery rows (title, tag, imageUrl) with offline fallback.
  Future<List<Map<String, dynamic>>> getGalleryItemsWithFallback() async {
    return _cachedOrRemote(
      remote: () async {
        final snapshot = await _firestore.collection(galleryCollection).get();
        return snapshot.docs
            .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
            .toList();
      },
      cached: OfflineSyncService.instance.getCachedGalleryItems,
    );
  }

  /// Live + offline-aware recipe list for UI streams.
  Stream<List<Map<String, dynamic>>> watchRecipesWithFallback() {
    return _catalogStream(
      firestoreStream: getRecipesStream().map(
        (snap) => snap.docs
            .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
            .toList(),
      ),
      fallback: getRecipesWithFallback,
    );
  }

  /// Live + offline-aware challenge list for UI streams.
  Stream<List<Map<String, dynamic>>> watchChallengesWithFallback() {
    return _catalogStream(
      firestoreStream: getActiveChallengesStream().map(
        (snap) => snap.docs
            .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
            .toList(),
      ),
      fallback: getChallengesWithFallback,
    );
  }

  Stream<List<Map<String, dynamic>>> _catalogStream({
    required Stream<List<Map<String, dynamic>>> firestoreStream,
    required Future<List<Map<String, dynamic>>> Function() fallback,
  }) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? fireSub;
    StreamSubscription<void>? cacheSub;
    StreamSubscription<List<ConnectivityResult>>? connectivitySub;

    Future<void> emitFallback() async {
      if (controller.isClosed) return;
      try {
        controller.add(await fallback());
      } catch (_) {
        controller.add(const []);
      }
    }

    Future<void> bindFirestore() async {
      fireSub?.cancel();
      if (!await isDeviceOnline()) {
        await emitFallback();
        return;
      }
      fireSub = firestoreStream.listen(
        (items) {
          if (controller.isClosed) return;
          if (items.isNotEmpty) {
            controller.add(items);
          } else {
            emitFallback();
          }
        },
        onError: (_) => emitFallback(),
      );
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () async {
        await emitFallback();
        await bindFirestore();
        cacheSub = OfflineSyncService.instance.onCacheUpdated.listen((_) async {
          await emitFallback();
          await bindFirestore();
        });
        connectivitySub =
            Connectivity().onConnectivityChanged.listen((_) async {
          await bindFirestore();
          await emitFallback();
        });
      },
      onCancel: () async {
        await fireSub?.cancel();
        await cacheSub?.cancel();
        await connectivitySub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Submits a high-fidelity contact inquiry to Firestore under the 'inquiries' collection.
  Future<void> submitInquiry({
    required String name,
    required String email,
    required String category,
    required String message,
    String? userId,
  }) async {
    await _firestore.collection('inquiries').add({
      'name': name,
      'email': email,
      'category': category,
      'message': message,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
