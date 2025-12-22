import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_settings_profile_page.dart';
import 'admin_emergency_contact_management_page.dart';
import 'admin_community_forum_control_page.dart';
import 'admin_tips_knowledge_hub_page.dart';
// import 'admin_adoption_petshop_management_page.dart'; // legacy combined page (optional, kept commented to avoid unused import)
import 'admin_adoption_management_page.dart';
import 'admin_petshop_management_page.dart';
import 'admin_pet_profile_management_page.dart';
import 'admin_user_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Example dynamic data (later connect to Firebase / API)
  int totalUsers = 0;
  int totalPets = 0;
  int totalPosts = 0;
  int shopItems = 0;
  int lostFound = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final db = FirebaseFirestore.instance;
      final users = await db.collection('users').get();
      final pets = await db.collection('pets').get();
      final posts = await db.collection('posts').get();
      final shop = await db.collection('shop_items').get();
      final lost = await db.collection('lost_found').get();

      setState(() {
        totalUsers = users.size;
        totalPets = pets.size;
        totalPosts = posts.size;
        shopItems = shop.size;
        lostFound = lost.size;
      });
    } catch (e) {
      // ignore and keep zeros
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f5fc),
      appBar: AppBar(
        title: const Text(
          '🐾 Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildAdminPanelSection(context),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadCounts();
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Welcome Back, Admin 👋',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Manage your community and data efficiently',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final stats = [
      {'icon': Icons.people, 'label': 'Total Users', 'value': totalUsers.toString()},
      {'icon': Icons.pets, 'label': 'Total Pets', 'value': totalPets.toString()},
      {'icon': Icons.forum, 'label': 'Total Posts', 'value': totalPosts.toString()},
      {'icon': Icons.store, 'label': 'Shop Items', 'value': shopItems.toString()},
      {'icon': Icons.location_on, 'label': 'Lost & Found', 'value': lostFound.toString()},
    ];

    return Card(
      elevation: 6,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: stats
                  .map((item) => _AnimatedOverviewCard(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        value: item['value'] as String,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanelSection(BuildContext context) {
    final adminPages = [
      {
        'icon': Icons.people,
        'label': 'User Management',
        'page': const AdminUserManagementPage(),
      },
      {
        'icon': Icons.pets,
        'label': 'Pet & Profile Management',
        'page': const AdminPetProfileManagementPage(),
      },
      // Split adoption & pet shop management into two distinct pages
      {
        'icon': Icons.pets,
        'label': 'Adoption Posts Management',
        'page': const AdminAdoptionManagementPage(),
      },
      {
        'icon': Icons.store,
        'label': 'Pet Shop Products Management',
        'page': const AdminPetShopManagementPage(),
      },
      {
        'icon': Icons.menu_book,
        'label': 'Tips & Knowledge Hub',
        'page': const AdminTipsKnowledgeHubPage(),
      },
      {
        'icon': Icons.forum,
        'label': 'Community Forum Control',
        'page': const AdminCommunityForumControlPage(),
      },
      {
        'icon': Icons.local_hospital,
        'label': 'Emergency Contact Management',
        'page': const AdminEmergencyContactManagementPage(),
      },
      {
        'icon': Icons.settings,
        'label': 'Settings & Admin Profile',
        'page': const AdminSettingsProfilePage(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚙️ Admin Controls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        ...adminPages.map(
          (item) => _AnimatedAdminTile(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => item['page'] as Widget));
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedOverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AnimatedOverviewCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}

class _AnimatedAdminTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AnimatedAdminTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedAdminTile> createState() => _AnimatedAdminTileState();
}

class _AnimatedAdminTileState extends State<_AnimatedAdminTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _hovered ? Colors.deepPurple.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(widget.icon, color: Colors.deepPurple),
        title: Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.deepPurple),
        onTap: widget.onTap,
        onLongPress: () => setState(() => _hovered = !_hovered),
      ),
    );
  }
}
