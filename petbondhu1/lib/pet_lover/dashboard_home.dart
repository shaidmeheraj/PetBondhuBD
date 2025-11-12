import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'emergency_contact_page.dart';
import 'community_forum_page.dart';
import 'adoption_petshop_page.dart';
import 'find_disease_web.dart';
import 'settings_tab.dart';
import 'chatbot_page.dart';

// ================= MAIN DASHBOARD WITH NAVBAR ====================
class DashboardMain extends StatefulWidget {
  final String userName;

  const DashboardMain({
    super.key,
    this.userName = "User",
  });

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final PageController _petCarouselController = PageController(viewportFraction: 0.78);

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(userName: widget.userName),
      const FindDiseasePage(),
      const ChatBotPage(),
      const SettingsTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the currently selected page in the body
      body: _pages[_selectedIndex],
      // Provide a global action to run the backend prediction UI from any tab
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Open the FindDiseasePage which contains the FastAPI-backed flow
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (_) => const FindDiseasePage()),
      //     );
      //   },
      //   label: const Text('Predict'),
      //   icon: const Icon(Icons.biotech),
      //   backgroundColor: Colors.deepPurple,
      // ),
      
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.deepPurple.shade100,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 5,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Colors.deepPurple),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.biotech_outlined),
              selectedIcon: Icon(Icons.biotech, color: Colors.deepPurple),
              label: 'Find Disease',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: Colors.deepPurple),
              label: 'Chatbot',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Colors.deepPurple),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DASHBOARD PAGE ====================
class DashboardHome extends StatefulWidget {
  final String userName;

  const DashboardHome({super.key, this.userName = "User"});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final PageController _petController = PageController(viewportFraction: 0.82);
  int _petIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('PetBondhuBD', style: TextStyle(color: Colors.deepPurple.shade700)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
          )
        ],
      ),
      body: Column(
        children: [
          // Header with gradient and welcome
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.teal.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(radius: 36, backgroundColor: Colors.white24, child: const Icon(Icons.pets, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back, ${widget.userName} 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Your pets are happy to see you today', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindDiseasePage()));
                    },
                    icon: const Icon(Icons.biotech_outlined),
                    label: const Text('Check Health'),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Animated stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(icon: Icons.verified, title: 'Vaccinated', value: '3'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.favorite, title: 'Wellness', value: 'Good'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.event, title: 'Appointments', value: '1'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pet carousel
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _petController,
              itemCount: 3,
              onPageChanged: (i) => setState(() => _petIndex = i),
              itemBuilder: (context, index) {
                final colors = [Colors.orange.shade100, Colors.green.shade100, Colors.pink.shade100];
                final petNames = ['Bella', 'Charlie', 'Milo'];
                return Transform.scale(
                  scale: _petIndex == index ? 1 : 0.94,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: colors[index % colors.length]),
                      child: Row(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/pet${index + 1}.jpg', width: 110, height: 110, fit: BoxFit.cover)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(petNames[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                const Text('Last fed: Today • Walk: 2h ago', style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                  child: const Text('View Profile'),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Overview / Actions section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _ActionCard(title: 'Lost & Found', icon: Icons.location_on, color: Colors.red),
                        _ActionCard(title: 'Emergency', icon: Icons.local_hospital, color: Colors.redAccent),
                        _ActionCard(title: 'Forum', icon: Icons.forum, color: Colors.deepPurple),
                        _ActionCard(title: 'Adopt & Shop', icon: Icons.store, color: Colors.orange),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: _OverviewCard(icon: Icons.vaccines, title: 'Next Vaccine', color: Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _OverviewCard(icon: Icons.fastfood, title: 'Food Log', color: Colors.green)),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.info, color: Colors.deepPurple),
                      title: const Text('Tips & Knowledge'),
                      subtitle: const Text('How to keep your pet healthy this winter'),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ================== COMPONENTS ==================

// Quick action buttons
class _LostFoundButton extends StatelessWidget {
  const _LostFoundButton();

  @override
  Widget build(BuildContext context) {
    return _QuickCircleButton(
      icon: Icons.location_on,
      color: Colors.red,
      label: "Lost & Found",
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdoptionPetShopPage(),
          ),
        );
      },
    );
  }
}

class _EmergencyContactButton extends StatelessWidget {
  const _EmergencyContactButton();

  @override
  Widget build(BuildContext context) {
    return _QuickCircleButton(
      icon: Icons.local_hospital,
      color: Colors.red,
      label: "Emergency",
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmergencyContactPage(),
          ),
        );
      },
    );
  }
}

class _CommunityForumButton extends StatelessWidget {
  const _CommunityForumButton();

  @override
  Widget build(BuildContext context) {
    return _QuickCircleButton(
      icon: Icons.forum,
      color: Colors.deepPurple,
      label: "Forum",
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityForumPage(),
          ),
        );
      },
    );
  }
}

class _AdoptionPetShopButton extends StatelessWidget {
  const _AdoptionPetShopButton();

  @override
  Widget build(BuildContext context) {
    return _QuickCircleButton(
      icon: Icons.store,
      color: Colors.orange,
      label: "Adoption & Shop",
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdoptionPetShopPage(),
          ),
        );
      },
    );
  }
}

// Reusable Quick Circle Buttons
class _QuickCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.15),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: color, size: 30),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Overview Card for key info
class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600)
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
        ]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.deepPurple)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ActionCard({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 140,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Open', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
