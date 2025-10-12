import 'package:flutter/material.dart';

class DailyCareTrackerTab extends StatefulWidget {
  const DailyCareTrackerTab({super.key});

  @override
  State<DailyCareTrackerTab> createState() => _DailyCareTrackerTabState();
}

class _DailyCareTrackerTabState extends State<DailyCareTrackerTab> {
  final List<String> _items = [
    'Morning walk',
    'Feed breakfast',
    'Medicine (if any)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Care Tracker'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
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
                      // temporary toggle: show snack
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked done: $text')));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () {
          // placeholder: add a new reminder locally
          setState(() {
            _items.add('New task ${_items.length + 1}');
          });
        },
      ),
    );
  }
}
