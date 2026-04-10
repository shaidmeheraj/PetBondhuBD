import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAdoptionManagementPage extends StatefulWidget {
  const AdminAdoptionManagementPage({super.key});

  @override
  State<AdminAdoptionManagementPage> createState() => _AdminAdoptionManagementPageState();
}

class _AdminAdoptionManagementPageState extends State<AdminAdoptionManagementPage> {
  static const _statusAll = 'all';
  static const _statusValues = ['available', 'discussion', 'adopted'];
  final Map<String, Color> _statusColors = const {
    'available': Colors.green,
    'discussion': Colors.amber,
    'adopted': Colors.redAccent,
  };
  final Map<String, String> _statusLabels = const {
    'available': 'Available',
    'discussion': 'In Discussion',
    'adopted': 'Adopted',
  };

  String _statusFilter = _statusAll;

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    return FirebaseFirestore.instance
        .collection('post')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _toggleApprove(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? {};
    final current = (data['approved'] ?? false) == true;
    try {
      await doc.reference.update({'approved': !current});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!current ? 'Marked approved' : 'Marked unapproved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deletePost(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final petName = (doc.data()?['petName'] ?? 'Pet').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Adoption Post'),
        content: Text('Delete "$petName" adoption post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildStatusChips(Map<String, int> counts, int totalCount) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('All ($totalCount)'),
          selected: _statusFilter == _statusAll,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _statusFilter = _statusAll);
          },
        ),
        for (final status in _statusValues)
          ChoiceChip(
            label: Text('${_statusLabels[status]} (${counts[status] ?? 0})'),
            selectedColor: (_statusColors[status] ?? Colors.teal).withOpacity(0.15),
            labelStyle: TextStyle(
              color: _statusFilter == status
                  ? _statusColors[status] ?? Colors.teal
                  : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            selected: _statusFilter == status,
            onSelected: (selected) {
              if (!selected) return;
              setState(() => _statusFilter = status);
            },
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColors[status] ?? Colors.teal;
    final label = _statusLabels[status] ?? status;
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.35)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildList(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No adoption posts yet.'));
        }

        final Map<String, int> counts = {
          for (final status in _statusValues) status: 0,
        };
        for (final doc in docs) {
          final status = (doc.data()['status'] ?? 'available').toString();
          if (_statusValues.contains(status)) {
            counts[status] = (counts[status] ?? 0) + 1;
          }
        }

        final filteredDocs = _statusFilter == _statusAll
            ? docs
            : docs.where((doc) {
                final status = (doc.data()['status'] ?? 'available').toString();
                return status == _statusFilter;
              }).toList();

        if (filteredDocs.isEmpty) {
          final emptyLabel = _statusFilter == _statusAll
              ? 'No adoption posts yet.'
              : 'No ${_statusLabels[_statusFilter]} posts right now.';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChips(counts, docs.length),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(emptyLabel, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStatusChips(counts, docs.length),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = filteredDocs[i];
                  final data = d.data();
                  final petName = (data['petName'] ?? 'Pet').toString();
                  final type = (data['type'] ?? '').toString();
                  final desc = (data['desc'] ?? '').toString();
                  final approved = (data['approved'] ?? false) == true;
                  final status = (data['status'] ?? 'available').toString();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.pets, color: approved ? Colors.green : Colors.teal),
                      title: Text(
                        '$petName${type.isNotEmpty ? ' · $type' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildStatusChip(status),
                          const SizedBox(height: 6),
                          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: approved ? 'Unapprove' : 'Approve',
                            onPressed: () => _toggleApprove(context, d),
                            icon: Icon(
                              approved ? Icons.check_circle : Icons.cancel,
                              color: approved ? Colors.green : Colors.red,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _deletePost(context, d),
                            icon: const Icon(Icons.delete, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Adoption Posts'),
        backgroundColor: Colors.teal,
      ),
      body: _buildList(context),
    );
  }
}
