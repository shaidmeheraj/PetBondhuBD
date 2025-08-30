import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// For chart, add fl_chart to pubspec.yaml: fl_chart: ^0.64.0
import 'package:fl_chart/fl_chart.dart';

class DailyCareTrackerTab extends StatefulWidget {
  const DailyCareTrackerTab({Key? key}) : super(key: key);

  @override
  State<DailyCareTrackerTab> createState() => _DailyCareTrackerTabState();
}

class _DailyCareTrackerTabState extends State<DailyCareTrackerTab> {
  final List<Map<String, dynamic>> logs = [];

  void _addLog() async {
    String food = 'Breakfast';
    int walk = 0;
    int water = 0;
    DateTime date = DateTime.now();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Daily Care Log'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: food,
                items: ['Breakfast', 'Lunch', 'Dinner']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => food = val ?? 'Breakfast',
                decoration: const InputDecoration(labelText: 'Food Intake'),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Walk/Exercise (min)'),
                onChanged: (val) => walk = int.tryParse(val) ?? 0,
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Water Intake (ml)'),
                onChanged: (val) => water = int.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  logs.add({
                    'date': date,
                    'food': food,
                    'walk': walk,
                    'water': water,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get last7DaysLogs {
    final now = DateTime.now();
    return logs.where((log) => log['date'].isAfter(now.subtract(const Duration(days: 7)))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addLog,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add Log',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Care History (Past 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: last7DaysLogs.length,
                itemBuilder: (context, index) {
                  final log = last7DaysLogs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(DateFormat('MMM d').format(log['date'])),
                      subtitle: Text('Food: ${log['food']}, Walk: ${log['walk']} min, Water: ${log['water']} ml'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Water Intake Chart (Past 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: last7DaysLogs
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['water'] as int).toDouble(),
                                color: Colors.blue,
                              ),
                            ],
                          ))
                      .toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < last7DaysLogs.length) {
                            final date = last7DaysLogs[value.toInt()]['date'] as DateTime;
                            return Text(DateFormat('d').format(date));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
