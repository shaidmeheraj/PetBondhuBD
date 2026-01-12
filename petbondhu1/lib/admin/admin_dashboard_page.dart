import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petbondhu1/admin/admin_settings_profile_page.dart';
import 'package:petbondhu1/admin/admin_emergency_contact_management_page.dart';
import 'package:petbondhu1/admin/admin_community_forum_control_page.dart';
import 'package:petbondhu1/admin/admin_tips_knowledge_hub_page.dart';
// import 'package:petbondhu1/admin/admin_adoption_petshop_management_page.dart'; // legacy combined page (optional, kept commented to avoid unused import)
import 'package:petbondhu1/admin/admin_adoption_management_page.dart';
import 'package:petbondhu1/admin/admin_petshop_management_page.dart';
import 'package:petbondhu1/admin/admin_pet_profile_management_page.dart';
import 'package:petbondhu1/admin/admin_user_management_page.dart';
import 'package:petbondhu1/admin/admin_lost_found_dashboard_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminPalette {
  static const Color primary = Color(0xFF5B4B8A);
  static const Color accent = Color(0xFF8F7CEC);
  static const Color surface = Color(0xFFF5F3FE);
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF5B4B8A), Color(0xFF3CB0A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
      backgroundColor: _AdminPalette.surface,
      appBar: AppBar(
        title: const Text(
          '🐾 Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_active_outlined, color: _AdminPalette.primary),
          ),
        ],
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _AdminPalette.headerGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _AdminPalette.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -10,
            child: Icon(Icons.pets, color: Colors.white.withOpacity(0.12), size: 96),
          ),
          Positioned(
            bottom: -16,
            left: 0,
            child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.10), size: 72),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back, Admin 👋',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor performance, resolve cases, and keep the PetBondhu community thriving.',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: const [
                        _HeaderChip(icon: Icons.insights, label: 'Realtime insights'),
                        _HeaderChip(icon: Icons.security, label: 'Operational control'),
                        _HeaderChip(icon: Icons.verified, label: 'Community trust'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Health Snapshot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _AdminPalette.primary)),
            const SizedBox(height: 8),
            Text(
              'Live metrics across users, pets, and marketplace touchpoints.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 18,
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
        'icon': Icons.location_on,
        'label': 'Lost & Found Dashboard',
        'page': const AdminLostFoundDashboardPage(),
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
      duration: const Duration(milliseconds: 260),
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            _AdminPalette.primary.withOpacity(0.12),
            _AdminPalette.accent.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _AdminPalette.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: _AdminPalette.primary.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _AdminPalette.primary,
                  _AdminPalette.accent,
                ],
              ),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.9))),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hovered ? _AdminPalette.accent.withOpacity(0.35) : Colors.transparent, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (_hovered ? _AdminPalette.accent : _AdminPalette.primary).withOpacity(_hovered ? 0.16 : 0.06),
              blurRadius: _hovered ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _AdminPalette.primary,
                  _AdminPalette.accent,
                ],
              ),
            ),
            child: Icon(widget.icon, color: Colors.white),
          ),
          title: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: const Text('Tap to manage', style: TextStyle(fontSize: 12, color: Colors.black54)),
          trailing: Icon(Icons.chevron_right, color: _hovered ? _AdminPalette.primary : Colors.black26, size: 26),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
