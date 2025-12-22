import 'package:flutter/material.dart';

class PetCareHub extends StatelessWidget {
  const PetCareHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pet Care Hub'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Daily'),
              Tab(icon: Icon(Icons.lightbulb), text: 'Tips'),
              Tab(icon: Icon(Icons.pets), text: 'Breed'),
              Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DailyGuidelinesView(),
            _TipsView(),
            _BreedDescriptionView(),
            _NutritionInfoView(),
          ],
        ),
      ),
    );
  }
}

// --- Daily Guidelines (merged from DailyCareTrackerTab) ---
class _DailyGuidelinesView extends StatefulWidget {
  const _DailyGuidelinesView();

  @override
  State<_DailyGuidelinesView> createState() => _DailyGuidelinesViewState();
}

class _DailyGuidelinesViewState extends State<_DailyGuidelinesView> {
  final List<String> _items = [
    'Morning walk',
    'Feed breakfast',
    'Medicine (if any)',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final text = _items[i];
                return ListTile(
                  leading: const Icon(Icons.check_box_outline_blank),
                  title: Text(text),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked done: $text')));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tips (merged from PetTipsTab) ---
class _TipsView extends StatelessWidget {
  const _TipsView();

  final List<Map<String, dynamic>> tips = const [
    {
      'category': 'Nutrition 🍖',
      'tip': "Dogs should not eat chocolate – it's toxic.",
    },
    {
      'category': 'Nutrition 🍖',
      'tip': "Cats need taurine in their diet for heart health.",
    },
    {
      'category': 'Grooming ✂️',
      'tip': "Brush your pet regularly to reduce shedding.",
    },
    {
      'category': 'Grooming ✂️',
      'tip': "Trim nails every 3-4 weeks to prevent injury.",
    },
    {
      'category': 'Emergency 🚑',
      'tip': "Keep emergency vet contacts handy.",
    },
    {
      'category': 'Emergency 🚑',
      'tip': "Know basic pet CPR for emergencies.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Text(tip['category'], style: const TextStyle(fontSize: 18)),
              title: Text(tip['tip'], style: const TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}

// --- Breed Description (adapted from PetDescriptionScreen) ---
class _BreedDescriptionView extends StatelessWidget {
  const _BreedDescriptionView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: const [
          Text('🐾 Name: Tommy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Breed: German Shepherd', style: TextStyle(fontSize: 16)),
          SizedBox(height: 6),
          Text('Age: 1 year', style: TextStyle(fontSize: 16)),
          SizedBox(height: 6),
          Text('Vaccinated: Yes', style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          Text(
            'Description:\nTommy is a playful and intelligent dog, perfect for families. He loves walks and is trained.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// --- Nutrition Info ---
class _NutritionInfoView extends StatelessWidget {
  const _NutritionInfoView();

  final List<String> nutritionPoints = const [
    'Feed balanced meals formulated for your pet\'s life stage.',
    'Avoid toxic foods like chocolate, grapes, and xylitol.',
    'Provide fresh water at all times.',
    'Consult your vet before changing diet or starting supplements.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: nutritionPoints.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(nutritionPoints[i]),
          );
        },
      ),
    );
  }
}
