import 'package:flutter/material.dart';
import 'lost_pet_alert_page.dart';
import 'daily_care_tracker_tab.dart';
import 'emergency_contact_page.dart';
import 'community_forum_page.dart';
import 'adoption_petshop_page.dart';

class DashboardHome extends StatelessWidget {
  final String userName;
  const DashboardHome({Key? key, this.userName = "User"}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back, $userName & PetBondhuBD 🐶🐱",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _QuickButton(icon: Icons.add, label: "Add Pet", color: Colors.purple),
                  _QuickButton(icon: Icons.pets, label: "View Pet Profile", color: Colors.blue),
                  _QuickButton(icon: Icons.medical_services, label: "Add Reminder", color: Colors.cyan),
                  _LostFoundButton(),
                  _DailyCareButton(),
                  _EmergencyContactButton(),
                  _CommunityForumButton(),
                  _AdoptionPetShopButton(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.vaccines,
                  title: "Next Vaccine Due Tomorrow",
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.fastfood,
                  title: "You logged Bella’s food today",
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: color, size: 32),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LostFoundButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.red.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.location_on, color: Colors.red, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LostPetAlertPage()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Lost & Found', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DailyCareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.teal.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.teal, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => DailyCareTrackerTab()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Daily Care', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmergencyContactButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.red.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.local_hospital, color: Colors.red, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EmergencyContactPage()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Emergency', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CommunityForumButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.deepPurple.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.forum, color: Colors.deepPurple, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CommunityForumPage()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Forum', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AdoptionPetShopButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.orange.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.store, color: Colors.orange, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdoptionPetShopPage()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Adoption & Shop', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _OverviewCard({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
