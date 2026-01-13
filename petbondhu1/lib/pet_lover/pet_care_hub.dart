import 'dart:math' as math;
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
  final TextEditingController _addController = TextEditingController();
  final List<_TaskItem> _tasks = [
    _TaskItem('Morning walk'),
    _TaskItem('Feed breakfast'),
    _TaskItem('Medicine (if any)'),
  ];

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  double _completionRatio() {
    if (_tasks.isEmpty) return 0;
    final done = _tasks.where((task) => task.done).length;
    return done / _tasks.length;
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(done: !_tasks[index].done);
    });
  }

  void _showAddTaskDialog() {
    _addController
      ..text = ''
      ..selection = TextSelection.collapsed(offset: 0);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add daily task'),
        content: TextField(
          controller: _addController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter task name'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitNewTask(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _submitNewTask, child: const Text('Add')),
        ],
      ),
    );
  }

  void _submitNewTask() {
    final text = _addController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _tasks.add(_TaskItem(text));
    });
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added "$text"')));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _completionRatio();
    final done = _tasks.where((task) => task.done).length;
    final percent = (ratio * 100).round();
    final total = _tasks.length;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Add task',
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add_task),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Text(
                      'Add tasks to build your daily routine.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return CheckboxListTile(
                        value: task.done,
                        onChanged: (_) => _toggleTask(index),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.done
                                ? Theme.of(context).colorScheme.outline
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _CompletionSummaryCard(
            ratio: ratio,
            percent: percent,
            done: done,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _TaskItem {
  const _TaskItem(this.title, {this.done = false});

  final String title;
  final bool done;

  _TaskItem copyWith({String? title, bool? done}) {
    return _TaskItem(title ?? this.title, done: done ?? this.done);
  }
}

class _CompletionSummaryCard extends StatelessWidget {
  const _CompletionSummaryCard({
    required this.ratio,
    required this.percent,
    required this.done,
    required this.total,
  });

  final double ratio;
  final int percent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: _CompletionPieChart(
                ratio: ratio.clamp(0.0, 1.0),
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percent% completed',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? 'Add tasks to start tracking.'
                        : '$done of $total tasks done',
                    style: TextStyle(color: scheme.outline),
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

class _CompletionPieChart extends StatelessWidget {
  const _CompletionPieChart({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceVariant;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: _PieChartPainter(
                progress: value,
                progressColor: color,
                trackColor: track,
              ),
              child: const SizedBox.expand(),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(10.0, size.shortestSide * 0.14);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        progressColor != oldDelegate.progressColor ||
        trackColor != oldDelegate.trackColor;
  }
}

// --- Tips (merged from PetTipsTab) ---
class _TipsView extends StatefulWidget {
  const _TipsView();

  @override
  State<_TipsView> createState() => _TipsViewState();
}

class _TipsViewState extends State<_TipsView> {
  late final List<_TipItem> _tips;
  late final List<String> _categories;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tips = const [
      _TipItem(
        title: 'Chocolate is toxic',
        detail:
            "Dogs should not eat chocolate – it's toxic and can trigger seizures.",
        category: 'Nutrition',
        icon: Icons.no_food,
        gradient: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
      ),
      _TipItem(
        title: 'Boost taurine',
        detail:
            'Cats need taurine-rich diets to protect heart and vision health.',
        category: 'Nutrition',
        icon: Icons.emoji_food_beverage,
        gradient: [Color(0xFFf6d365), Color(0xFFfda085)],
      ),
      _TipItem(
        title: 'Brush routinely',
        detail:
            'Brush your pet regularly to reduce shedding and prevent matting.',
        category: 'Grooming',
        icon: Icons.brush,
        gradient: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
      ),
      _TipItem(
        title: 'Trim nails safely',
        detail:
            'Trim nails every 3–4 weeks and reward calm behaviour throughout.',
        category: 'Grooming',
        icon: Icons.cut,
        gradient: [Color(0xFFd4fc79), Color(0xFF96e6a1)],
      ),
      _TipItem(
        title: 'Emergency contacts',
        detail:
            'Save a 24/7 vet, poison hotline, and local animal control number.',
        category: 'Emergency',
        icon: Icons.phone_in_talk,
        gradient: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
      ),
      _TipItem(
        title: 'Learn pet CPR',
        detail:
            'Knowing basic pet CPR can stabilise pets while you rush to the vet.',
        category: 'Emergency',
        icon: Icons.health_and_safety,
        gradient: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
      ),
    ];
    _categories = [
      'All',
      ...{for (final tip in _tips) tip.category},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _tips
        : _tips.where((tip) => tip.category == _selectedCategory).toList();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart care ideas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Filter quick wins by focus area or explore them all.',
            style: TextStyle(color: scheme.outline),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No tips yet for $_selectedCategory',
                      style: TextStyle(color: scheme.outline),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 4,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tip = filtered[index];
                      return _TipCard(item: tip);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TipItem {
  const _TipItem({
    required this.title,
    required this.detail,
    required this.category,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String detail;
  final String category;
  final IconData icon;
  final List<Color> gradient;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.item});

  final _TipItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: item.gradient),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(item.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                item.category,
                                style: TextStyle(color: scheme.outline),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.detail,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Action idea:',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _generateActionIdea(item.category),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              item.category,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _generateActionIdea(String category) {
    switch (category) {
      case 'Nutrition':
        return 'Build a rotating meal plan with protein, vitamins, and hydration reminders.';
      case 'Grooming':
        return 'Schedule a weekly spa session with brushing, ear checks, and paw balm.';
      case 'Emergency':
        return 'Prepare a go-bag with medical records, meds, bandages, and transport carrier.';
      default:
        return 'Create a short checklist that keeps the habit consistent all week.';
    }
  }
}

// --- Breed Description (adapted from PetDescriptionScreen) ---
class _BreedDescriptionView extends StatelessWidget {
  const _BreedDescriptionView();

  @override
  Widget build(BuildContext context) {
    final breeds = <_BreedFeature>[
      const _BreedFeature(
        title: 'German Shepherd',
        subtitle: 'Loyal guardian',
        description:
            'Intelligent working dog that thrives with daily exercise, training, and purposeful tasks.',
        highlights: [
          'High energy',
          'Needs structured training',
          'Excellent family protector',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1537151625747-768eb6cf92b6?auto=format&fit=crop&w=1200&q=80',
      ),
      const _BreedFeature(
        title: 'Golden Retriever',
        subtitle: 'Gentle companion',
        description:
            'Friendly and patient, perfect for families that enjoy outdoor adventures and lots of affection.',
        highlights: [
          'Great with kids',
          'Enjoys swimming',
          'Requires regular grooming',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1507143550189-fed454f93097?auto=format&fit=crop&w=1200&q=80',
      ),
      const _BreedFeature(
        title: 'Siamese Cat',
        subtitle: 'Vocal storyteller',
        description:
            'Elegant feline known for social personality, bright blue eyes, and a need for interactive play.',
        highlights: [
          'Highly social',
          'Sensitive digestion',
          'Needs mental enrichment',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1543852786-1cf6624b9987?auto=format&fit=crop&w=1200&q=80',
      ),
      const _BreedFeature(
        title: 'Holland Lop',
        subtitle: 'Playful house rabbit',
        description:
            'Compact rabbit with lopped ears; enjoys gentle handling, fresh greens, and safe exploratory space.',
        highlights: [
          'Indoor friendly',
          'Chews frequently',
          'Requires litter training',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1518796745738-41048802f99a?auto=format&fit=crop&w=1200&q=80',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: breeds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final breed = breeds[index];
        return _BreedBannerCard(feature: breed);
      },
    );
  }
}

class _BreedFeature {
  const _BreedFeature({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.highlights,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String description;
  final List<String> highlights;
  final String imageUrl;
}

class _BreedBannerCard extends StatelessWidget {
  const _BreedBannerCard({required this.feature});

  final _BreedFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          image: DecorationImage(
            image: NetworkImage(feature.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.32),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x99000000), Color(0x33000000)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    feature.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feature.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: feature.highlights
                        .map(
                          (text) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.26),
                              ),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
