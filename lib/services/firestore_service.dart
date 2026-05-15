import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(usersCollection).doc(userId);

  /// Creates `users/{uid}` on first login/sign-up with default cloud state.
  Future<void> syncUserDocument(User user) async {
    final ref = _userRef(user.uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'displayName': user.displayName,
        'email': user.email,
        'goalTitle': 'Reduce Waste',
        'notificationsEnabled': true,
        'tasksCompleted': 0,
        'currentStreak': 0,
        'savedTips': <String>[],
        'co2Saved': 0.0,
        'waterSaved': 0.0,
        'energySaved': 0.0,
      });
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
  }) async {
    try {
      final updateData = <String, dynamic>{
        'tasksCompleted': FieldValue.increment(1),
      };
      if (co2 > 0) {
        updateData['co2Saved'] = FieldValue.increment(co2);
      }
      if (water > 0) {
        updateData['waterSaved'] = FieldValue.increment(water);
      }
      if (energy > 0) {
        updateData['energySaved'] = FieldValue.increment(energy);
      }
      await _firestore.collection(usersCollection).doc(userId).update(updateData);
    } catch (_) {
      final updateData = <String, dynamic>{
        'tasksCompleted': FieldValue.increment(1),
        'savedTips': <String>[],
        'currentStreak': 0,
        'goalTitle': 'Reduce Waste',
        'notificationsEnabled': true,
        'co2Saved': FieldValue.increment(co2),
        'waterSaved': FieldValue.increment(water),
        'energySaved': FieldValue.increment(energy),
      };
      await _firestore.collection(usersCollection).doc(userId).set(
        updateData,
        SetOptions(merge: true),
      );
    }
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

  /// Seeds the recipes collection with dummy eco-friendly recipes if empty.
  Future<void> seedRecipes() async {
    final snapshot =
        await _firestore.collection(recipesCollection).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final collection = _firestore.collection(recipesCollection);

    for (final doc in _seedRecipeDocuments) {
      final ref = collection.doc();
      batch.set(ref, doc);
    }

    await batch.commit();
  }

  static final List<Map<String, dynamic>> _seedRecipeDocuments = [
    {
      'title': 'Lentil Stew',
      'prepTime': '25 mins',
      'ecoBenefits': ['Low Carbon Impact', 'Plant-Based'],
      'ingredients': [
        '2 cups lentils',
        '1 onion',
        '2 carrots',
        '3 celery stalks',
        '4 cups vegetable broth'
      ],
      'steps': [
        'Rinse lentils thoroughly',
        'Chop vegetables',
        'Sauté onions and carrots',
        'Add lentils and broth',
        'Simmer for 25 minutes'
      ],
      'imageUrl':
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80',
    },
    {
      'title': 'Zero-Waste Veggie Wrap',
      'prepTime': '15 mins',
      'ecoBenefits': ['Zero Waste', 'Plant-Based'],
      'ingredients': [
        'Whole wheat tortilla',
        'Leftover vegetables',
        'Hummus',
        'Fresh herbs'
      ],
      'steps': [
        'Warm tortilla',
        'Spread hummus',
        'Add vegetables',
        'Roll tightly',
        'Cut in half'
      ],
      'imageUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    },
    {
      'title': 'Locally Sourced Salad',
      'prepTime': '10 mins',
      'ecoBenefits': ['Local Ingredients', 'Low Carbon Impact'],
      'ingredients': [
        'Mixed greens',
        'Local tomatoes',
        'Cucumber',
        'Olive oil',
        'Lemon juice'
      ],
      'steps': [
        'Wash vegetables',
        'Chop into bite-sized pieces',
        'Mix in bowl',
        'Drizzle with dressing',
        'Serve fresh'
      ],
      'imageUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    },
  ];

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

  /// Master seeding function for production data.
  /// Seeds recipes, challenges, and content collections if they are empty.
  Future<void> seedProductionData() async {
    // Recipes data
    final List<Map<String, dynamic>> recipes = [
      {"title": "One-Pot Lentil Bolognese", "type": "vegan_main", "ingredients": ["1 cup brown lentils", "1 onion, diced", "2 carrots, diced", "2 celery stalks, diced", "3 cloves garlic, minced", "1 can crushed tomatoes", "2 tbsp tomato paste", "1 tsp dried oregano", "500ml vegetable broth", "Salt and pepper to taste"], "carbon_per_serving_kg": 0.4, "image_url": "https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800", "instructions": "Sauté onion, carrots, celery until soft. Add garlic, lentils, tomatoes, broth, and spices. Simmer 25 mins until lentils are tender. Serve over whole-grain pasta or zucchini noodles.", "tags": ["vegan", "low-carbon", "high-protein", "meal-prep"]},
      {"title": "Coconut Chickpea Curry", "type": "curry", "ingredients": ["1 can chickpeas, drained", "1 can coconut milk", "1 onion, chopped", "2 tbsp curry powder", "1 tsp turmeric", "1 cup spinach", "1 cup cauliflower florets", "1 tbsp coconut oil", "Salt to taste"], "carbon_per_serving_kg": 0.6, "image_url": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800", "instructions": "Heat oil, sauté onion until golden. Add spices, toast 1 min. Add chickpeas, cauliflower, coconut milk. Simmer 15 mins. Stir in spinach until wilted. Serve with brown rice.", "tags": ["vegetarian", "gluten-free", "anti-inflammatory", "quick-meal"]},
      {"title": "Rainbow Quinoa Buddha Bowl", "type": "bowl", "ingredients": ["1 cup cooked quinoa", "1/2 cup roasted sweet potato", "1/2 cup chickpeas", "1/4 avocado, sliced", "1/4 cup shredded purple cabbage", "2 tbsp tahini", "1 tbsp lemon juice", "Handful of kale"], "carbon_per_serving_kg": 0.3, "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800", "instructions": "Arrange cooked quinoa, roasted sweet potato, chickpeas, cabbage, kale, and avocado in a bowl. Whisk tahini, lemon juice, and water for dressing. Drizzle and serve.", "tags": ["vegan", "nutrient-dense", "no-cook-option", "colorful"]}
    ];

    // Challenges data
    final List<Map<String, dynamic>> challenges = [
      {"id": "plastic_free_jan_2026", "title": "Plastic-Free January Challenge", "description": "Reduce single-use plastic waste for 30 days with daily actionable swaps.", "start_date": "2026-01-01", "end_date": "2026-01-31", "actions": ["Carry a reusable water bottle and coffee cup", "Use cloth produce bags for grocery shopping", "Choose package-free fruits and vegetables", "Refuse plastic straws and cutlery when ordering takeout"]},
      {"id": "meatless_monday_q1", "title": "Meatless Monday Kickstart", "description": "Replace one meat-based meal per week with a plant-powered alternative to lower your carbon footprint.", "start_date": "2026-01-06", "end_date": "2026-03-31", "actions": ["Try one new vegetarian recipe each Monday", "Share your plant-based meal photo in the app community", "Calculate your weekly carbon savings using the in-app tracker", "Invite a friend to join your Meatless Monday"]},
      {"id": "home_energy_sprint_feb", "title": "Home Energy Sprint", "description": "Cut household energy use by 15% in February through small, consistent habit changes.", "start_date": "2026-02-01", "end_date": "2026-02-28", "actions": ["Lower thermostat by 1°C and wear a sweater", "Switch to LED bulbs in high-use fixtures", "Unplug devices or use smart power strips at night", "Wash clothes in cold water and air-dry when possible"]}
    ];

    // Content data
    final List<Map<String, dynamic>> content = [
      {"title": "Decode Eco-Labels Like a Pro", "description": "Learn to identify trustworthy certifications like Energy Star, Fair Trade, and FSC to avoid greenwashing.", "category": "certifications", "impact_estimate": "Prevents ~50kg CO2e/year by steering purchases toward verified sustainable brands"},
      {"title": "Switch to Community Solar", "description": "Join a local community solar program to access renewable energy without installing panels on your roof.", "category": "energy_tips", "impact_estimate": "Offsets ~1.2 tons CO2e annually per household"},
      {"title": "Choose Trains Over Short-Haul Flights", "description": "For trips under 500km, take the train instead of flying to drastically cut travel emissions.", "category": "travel", "impact_estimate": "Reduces travel emissions by up to 90% compared to flying"}
    ];

    // Seed recipes if empty
    final recipesSnap = await _firestore.collection(recipesCollection).limit(1).get();
    if (recipesSnap.docs.isEmpty) {
      for (final recipe in recipes) {
        await _firestore.collection(recipesCollection).add(recipe);
      }
    }

    // Seed challenges if empty
    final challengesSnap = await _firestore.collection('challenges').limit(1).get();
    if (challengesSnap.docs.isEmpty) {
      for (final challenge in challenges) {
        await _firestore.collection('challenges').doc(challenge['id']).set(challenge);
      }
    }

    // Seed content if empty
    final contentSnap = await _firestore.collection(contentCollection).limit(1).get();
    if (contentSnap.docs.isEmpty) {
      for (final item in content) {
        await _firestore.collection(contentCollection).add(item);
      }
    }
  }
}
