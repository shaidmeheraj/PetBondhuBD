import 'admin_settings_profile_page.dart';
import 'admin_emergency_contact_management_page.dart';
import 'admin_community_forum_control_page.dart';
import 'admin_tips_knowledge_hub_page.dart';
import 'admin_adoption_petshop_management_page.dart';
import 'admin_lost_found_management_page.dart';
import 'admin_pet_profile_management_page.dart';
import 'admin_user_management_page.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverviewSection(),
          const SizedBox(height: 24),
          _AdminPanelSection(),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _OverviewCard(icon: Icons.people, label: 'Total Users', value: '120'),
                _OverviewCard(icon: Icons.pets, label: 'Total Pets', value: '85'),
                _OverviewCard(icon: Icons.forum, label: 'Total Posts', value: '340'),
                _OverviewCard(icon: Icons.store, label: 'Shop Items', value: '42'),
                _OverviewCard(icon: Icons.location_on, label: 'Lost & Found', value: '7'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _OverviewCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.deepPurple),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AdminPanelSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminPanelButton(
          icon: Icons.people,
          label: 'User Management',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminUserManagementPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.pets,
          label: 'Pet & Profile Management',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminPetProfileManagementPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.location_on,
          label: 'Lost & Found Management',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminLostFoundManagementPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.store,
          label: 'Adoption & Pet Shop Management',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminAdoptionPetShopManagementPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.menu_book,
          label: 'Tips & Knowledge Hub',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminTipsKnowledgeHubPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.forum,
          label: 'Community Forum Control',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminCommunityForumControlPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.local_hospital,
          label: 'Emergency Contact Management',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminEmergencyContactManagementPage(),
              ),
            );
          },
        ),
        _AdminPanelButton(
          icon: Icons.settings,
          label: 'Settings & Admin Profile',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminSettingsProfilePage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdminPanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminPanelButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
