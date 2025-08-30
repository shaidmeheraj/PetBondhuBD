import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RemindersTab extends StatefulWidget {
  const RemindersTab({Key? key}) : super(key: key);

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  final List<Map<String, dynamic>> reminders = [];

  void _addReminder() async {
    String title = '';
    DateTime? dateTime;
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController titleCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Reminder Title'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: Text(dateTime == null ? 'Pick Date & Time' : DateFormat('MMM d, h:mm a').format(dateTime!)),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      dateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                      setState(() {});
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && dateTime != null) {
                  setState(() {
                    reminders.add({
                      'title': titleCtrl.text,
                      'dateTime': dateTime,
                      'done': false,
                    });
                  });
                  Navigator.pop(context);
                }
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

  void _deleteReminder(int index) {
    setState(() {
      reminders.removeAt(index);
    });
  }

  void _markAsDone(int index) {
    setState(() {
      reminders[index]['done'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = reminders.where((r) => r['dateTime'].isAfter(now) && !r['done']).toList();
    final past = reminders.where((r) => r['dateTime'].isBefore(now) || r['done']).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add Reminder',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: upcoming.length,
                itemBuilder: (context, index) {
                  final r = upcoming[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(r['title']),
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(r['dateTime'])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _markAsDone(reminders.indexOf(r)),
                            tooltip: 'Mark as Done',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReminder(reminders.indexOf(r)),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Past Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: past.length,
                itemBuilder: (context, index) {
                  final r = past[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(r['title'], style: const TextStyle(decoration: TextDecoration.lineThrough)),
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(r['dateTime'])),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteReminder(reminders.indexOf(r)),
                        tooltip: 'Delete',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
