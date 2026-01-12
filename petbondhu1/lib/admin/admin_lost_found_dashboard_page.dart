import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLostFoundDashboardPage extends StatefulWidget {
  const AdminLostFoundDashboardPage({super.key});

  @override
  State<AdminLostFoundDashboardPage> createState() => _AdminLostFoundDashboardPageState();
}

class _AdminLostFoundDashboardPageState extends State<AdminLostFoundDashboardPage> {
  String _selectedFilter = 'all';

  Stream<QuerySnapshot<Map<String, dynamic>>> _lostFoundStream() {
    final base = FirebaseFirestore.instance.collection('lost_found');
    if (_selectedFilter == 'lost') {
      return base.where('type', isEqualTo: 'lost').orderBy('createdAt', descending: true).snapshots();
    }
    if (_selectedFilter == 'found') {
      return base.where('type', isEqualTo: 'found').orderBy('createdAt', descending: true).snapshots();
    }
    return base.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> _markResolved(String docId, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('lost_found').doc(docId).update({'resolved': value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Marked as resolved' : 'Marked as pending')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<void> _deleteRecord(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove entry'),
        content: const Text('This will permanently remove the lost or found report.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('lost_found').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry removed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Filter by:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Lost'),
                  selected: _selectedFilter == 'lost',
                  onSelected: (_) => setState(() => _selectedFilter = 'lost'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Found'),
                  selected: _selectedFilter == 'found',
                  onSelected: (_) => setState(() => _selectedFilter = 'found'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _lostFoundStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No lost or found entries yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final id = docs[index].id;
                    final type = (data['type'] ?? 'lost').toString();
                    final petName = (data['petName'] ?? 'Unknown').toString();
                    final ownerName = (data['ownerName'] ?? 'Not provided').toString();
                    final contact = (data['contact'] ?? 'No contact').toString();
                    final details = (data['details'] ?? '').toString();
                    final location = (data['location'] ?? 'Not set').toString();
                    final resolved = data['resolved'] == true;
                    final reportedAt = _formatDate(data['createdAt']);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: type == 'lost' ? Colors.redAccent : Colors.green,
                                  child: Icon(type == 'lost' ? Icons.report : Icons.volunteer_activism, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${type.toUpperCase()} • $petName',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Reported by: $ownerName', style: const TextStyle(color: Colors.black54)),
                                      Text('Contact: $contact', style: const TextStyle(color: Colors.black54)),
                                      Text('Location: $location', style: const TextStyle(color: Colors.black54)),
                                      if (reportedAt != null)
                                        Text('Reported: $reportedAt', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(details, style: const TextStyle(fontSize: 13)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                FilterChip(
                                  label: Text(resolved ? 'Resolved' : 'Pending'),
                                  selected: resolved,
                                  selectedColor: Colors.green.shade100,
                                  onSelected: (value) => _markResolved(id, !resolved),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Delete entry',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteRecord(id),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  String? _formatDate(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (timestamp is DateTime) {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }
}
