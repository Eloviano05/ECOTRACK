import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore access for educational / tips library content.
class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String contentCollection = 'content';

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
}
