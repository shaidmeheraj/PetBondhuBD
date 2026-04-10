import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLostFoundDashboardPage extends StatefulWidget {
  const AdminLostFoundDashboardPage({super.key});

  @override
  State<AdminLostFoundDashboardPage> createState() => _AdminLostFoundDashboardPageState();
}

class _AdminLostFoundDashboardPageState
    extends State<AdminLostFoundDashboardPage> {
  String _selectedFilter = 'all';

  Future<void> _markReportResolved(
    _AdminPetReport report,
    bool resolved,
  ) async {
    final newStatus = report.isLost
        ? (resolved ? 'found' : 'lost')
        : (resolved ? 'claimed' : 'found');
    final update = <String, dynamic>{
      'status': newStatus,
      'resolved': resolved,
    };
    if (resolved) {
      update['resolvedAt'] = FieldValue.serverTimestamp();
    } else {
      update['resolvedAt'] = FieldValue.delete();
    }

    try {
      await report.reference.update(update);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolved
                ? 'Marked ${report.isLost ? 'lost' : 'found'} report as resolved.'
                : 'Set ${report.isLost ? 'lost' : 'found'} report back to pending.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  Future<void> _deleteReport(_AdminPetReport report) async {
    final label = report.isLost ? 'lost pet report' : 'found pet report';
    final title = report.isLost
        ? (report.data['petName'] ?? 'Lost pet').toString()
        : (report.data['petType'] ?? 'Found pet').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove entry'),
        content: Text('Delete "$title" $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await report.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Widget _buildSummaryCards({
    required int total,
    required int lost,
    required int found,
    required int resolved,
  }) {
    final pending = total - resolved;

    Widget buildTile(String label, int count, Color color) {
      return Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildTile('Total reports', total, Colors.deepPurple),
          const SizedBox(width: 12),
          buildTile('Lost pets', lost, Colors.redAccent),
          const SizedBox(width: 12),
          buildTile('Found pets', found, Colors.green),
          const SizedBox(width: 12),
          buildTile('Pending cases', pending < 0 ? 0 : pending, Colors.orange),
          const SizedBox(width: 12),
          buildTile('Resolved cases', resolved, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String? value) {
    if (value == null || value.isEmpty) {
      return Icon(Icons.pets, size: 40, color: Colors.grey.shade400);
    }

    try {
      if (value.startsWith('data:')) {
        final comma = value.indexOf(',');
        final payload = comma >= 0 ? value.substring(comma + 1) : value;
        final bytes = base64Decode(payload);
        return Image.memory(bytes, fit: BoxFit.cover);
      }
      if (!value.startsWith('http')) {
        final bytes = base64Decode(value);
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    } catch (_) {
      return Icon(Icons.pets, size: 40, color: Colors.grey.shade400);
    }

    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
    );
  }

  Widget _buildReportCard(_AdminPetReport report) {
    final data = report.data;
    final resolved = report.isResolved;
    final color = report.isLost ? Colors.redAccent : Colors.green;
    final statusLabel = report.isLost
        ? (resolved ? 'Reunited' : 'Still Missing')
        : (resolved ? 'Claimed' : 'Awaiting Owner');
    final contact = (data['contactNumber'] ?? data['contact'] ?? 'No contact')
        .toString();
    final primaryTitle = report.isLost
        ? '${(data['petName'] ?? 'Unknown').toString()} · ${(data['petType'] ?? 'Pet').toString()}'
        : 'Found ${(data['petType'] ?? 'Pet').toString()}';
    final locationLabel = report.isLost ? 'Last seen' : 'Where found';
    final locationValue = report.isLost
        ? (data['lastSeenLocation'] ?? 'Unknown').toString()
        : (data['whereFound'] ?? 'Unknown').toString();
    final secondaryLabel = report.isLost ? 'Date lost' : 'Date found';
    final secondaryValue = report.isLost
        ? (data['lastSeenDate'] ?? '').toString()
        : (data['foundDate'] ?? '').toString();
    final reporter = report.isLost
        ? (data['ownerName'] ?? 'Anonymous').toString()
        : (data['finderName'] ?? 'Anonymous').toString();
    final createdAt = _formatDate(data['createdAt']);
    final description = (data['description'] ?? '').toString();
    final image = (data['image'] ?? data['photoUrl'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade200,
                    child: _buildImageWidget(image),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(statusLabel),
                            backgroundColor: color.withOpacity(0.12),
                            labelStyle: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(color: color.withOpacity(0.2)),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (createdAt != null)
                            Chip(
                              label: Text('Reported: $createdAt'),
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: const TextStyle(fontSize: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reporter: $reporter',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '$locationLabel: $locationValue',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (secondaryValue.isNotEmpty)
                        Text(
                          '$secondaryLabel: $secondaryValue',
                          style: const TextStyle(color: Colors.black87),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Contact: $contact',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: Text(resolved ? 'Resolved' : 'Pending'),
                  selected: resolved,
                  selectedColor: Colors.teal.shade100,
                  onSelected: (_) => _markReportResolved(report, !resolved),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDetailsDialog(report),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete report',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteReport(report),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(_AdminPetReport report) {
    final data = report.data;
    final image = (data['image'] ?? data['photoUrl'] ?? '').toString();
    final statusLabel = report.isLost
        ? (report.isResolved ? 'Reunited' : 'Still Missing')
        : (report.isResolved ? 'Claimed' : 'Awaiting Owner');

    final details = <MapEntry<String, String>>[];

    void addDetail(String label, dynamic value) {
      final text = (value ?? '').toString();
      if (text.isEmpty) return;
      details.add(MapEntry(label, text));
    }

    if (report.isLost) {
      addDetail('Pet Name', data['petName']);
      addDetail('Pet Type', data['petType']);
      addDetail('Description', data['description']);
      addDetail('Last Seen Location', data['lastSeenLocation']);
      addDetail('Date Lost', data['lastSeenDate']);
      addDetail('Owner', data['ownerName']);
      addDetail('Contact', data['contactNumber']);
    } else {
      addDetail('Pet Type', data['petType']);
      addDetail('Description', data['description']);
      addDetail('Where Found', data['whereFound']);
      addDetail('Pickup Address', data['pickupAddress']);
      addDetail('Date Found', data['foundDate']);
      addDetail('Reported By', data['finderName']);
      addDetail('Contact', data['contactNumber']);
    }
    addDetail('Status', statusLabel);

    final title = report.isLost
        ? 'Lost ${(data['petName'] ?? 'Pet')}'
        : 'Found ${(data['petType'] ?? 'Pet')}';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.toString()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _buildImageWidget(image),
                  ),
                ),
              if (image.isNotEmpty) const SizedBox(height: 12),
              for (final entry in details) ...[
                Text(
                  entry.key,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(entry.value, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                const Text(
                  'Filter by:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
              stream: FirebaseFirestore.instance
                  .collection('lost_pets')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, lostSnapshot) {
                if (lostSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (lostSnapshot.hasError) {
                  return Center(child: Text('Error: ${lostSnapshot.error}'));
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('found_pets')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, foundSnapshot) {
                    if (foundSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (foundSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${foundSnapshot.error}'),
                      );
                    }

                    final lostDocs = lostSnapshot.data?.docs ?? [];
                    final foundDocs = foundSnapshot.data?.docs ?? [];

                    final reports = <_AdminPetReport>[
                      for (final doc in lostDocs)
                        _AdminPetReport(
                          reference: doc.reference,
                          data: doc.data(),
                          collection: 'lost_pets',
                        ),
                      for (final doc in foundDocs)
                        _AdminPetReport(
                          reference: doc.reference,
                          data: doc.data(),
                          collection: 'found_pets',
                        ),
                    ];

                    reports.sort((a, b) {
                      final aDate =
                          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final bDate =
                          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return bDate.compareTo(aDate);
                    });

                    final totalCount = reports.length;
                    final lostCount =
                        reports.where((report) => report.type == 'lost').length;
                    final foundCount = reports
                        .where((report) => report.type == 'found')
                        .length;
                    final resolvedCount =
                        reports.where((report) => report.isResolved).length;

                    final filteredReports = _selectedFilter == 'all'
                        ? reports
                        : reports
                            .where((report) => report.type == _selectedFilter)
                            .toList();

                    final summaryCard = Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSummaryCards(
                          total: totalCount,
                          lost: lostCount,
                          found: foundCount,
                          resolved: resolvedCount,
                        ),
                      ),
                    );

                    final isFilteredEmpty = filteredReports.isEmpty;
                    final listLength =
                        isFilteredEmpty ? 2 : filteredReports.length + 1;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: listLength,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return summaryCard;
                        }
                        if (isFilteredEmpty) {
                          final message = _selectedFilter == 'all'
                              ? 'No reports yet.'
                              : 'No ${_selectedFilter == 'lost' ? 'lost' : 'found'} reports currently.';
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }
                        final report = filteredReports[index - 1];
                        return _buildReportCard(report);
                      },
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

class _AdminPetReport {
  _AdminPetReport({
    required this.reference,
    required this.data,
    required this.collection,
  }) : type = collection == 'lost_pets' ? 'lost' : 'found';

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;
  final String collection;
  final String type;

  bool get isLost => type == 'lost';

  bool get isResolved {
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (isLost) {
      return status == 'found' || status == 'reunited';
    }
    return status == 'claimed';
  }

  DateTime? get createdAt {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
