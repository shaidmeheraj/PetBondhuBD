import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final PageController _petController = PageController(viewportFraction: 0.84);
  int _petIndex = 0;
  late final Future<List<Map<String, dynamic>>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadUserPets();
  }

  Future<List<Map<String, dynamic>>> _loadUserPets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final db = FirebaseFirestore.instance;
      if (user == null) return [];
      final snapshot = await db.collection('pets').where('ownerId', isEqualTo: user.uid).get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
  // final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('PetBondhuBD', style: TextStyle(color: Colors.deepPurple.shade700)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.deepPurple.shade700),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black54),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.teal.shade300]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(radius: 34, backgroundColor: Colors.white24, child: const Icon(Icons.pets, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back, ${widget.userName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Explore your pets and options', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindDiseasePage())),
                    icon: const Icon(Icons.biotech_outlined),
                    label: const Text('Check Health'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // small stats row (driven from user's pets)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _petsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Expanded(child: _StatCard(icon: Icons.hourglass_top, title: 'Loading', value: '...')),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.hourglass_top, title: '', value: '')),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.hourglass_top, title: '', value: '')),
                    ],
                  ),
                );
              }
              final pets = snapshot.data ?? [];
              final vaccinated = pets.where((p) => (p['vaccinated'] == true)).length;
              final appointments = pets.fold<int>(0, (acc, p) {
                final list = p['appointments'] as List<dynamic>?;
                return acc + (list?.length ?? 0);
              });
              final wellnessGood = pets.where((p) => (p['wellness'] ?? '').toString().toLowerCase() == 'good').length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.verified, title: 'Vaccinated', value: vaccinated.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.favorite, title: 'Wellness Good', value: wellnessGood.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.event, title: 'Appointments', value: appointments.toString())),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // pet carousel (loaded from Firestore)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _petsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()));
              }
              final pets = snapshot.data ?? [];
              if (pets.isEmpty) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No pets found. Add a pet to get started', style: TextStyle(color: Colors.grey.shade700)),
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 170,
                child: PageView.builder(
                  controller: _petController,
                  itemCount: pets.length,
                  onPageChanged: (i) => setState(() => _petIndex = i),
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    final name = pet['name']?.toString() ?? 'Pet';
                    final color = Colors.primaries[index % Colors.primaries.length].shade100;
                    return Transform.scale(
                      scale: _petIndex == index ? 1 : 0.96,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: color),
                          child: Row(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                                child: const Icon(Icons.pets, size: 56, color: Colors.deepPurple),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text((pet['notes'] ?? 'No recent activity').toString(), style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 12),
                                    Row(children: [ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A00F4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), child: const Text('View')), const SizedBox(width: 8), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), side: const BorderSide(color: Color(0xFF6A00F4))), child: const Text('Feed'))])
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
              );
            },
          ),

            const SizedBox(height: 12),

            // actions + overview (non-scrolling inside the page scroll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    // Allow cards to size naturally; no fixed height is used so
                    // the page scrolls vertically when cards grow (accessibility).
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            _ActionCard(
                              title: 'Lost & Found',
                              icon: Icons.location_on,
                              color: Colors.red,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdoptionPetShopPage())),
                            ),
                            _ActionCard(
                              title: 'Emergency',
                              icon: Icons.local_hospital,
                              color: Colors.redAccent,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyContactPage())),
                            ),
                            _ActionCard(
                              title: 'Forum',
                              icon: Icons.forum,
                              color: Colors.deepPurple,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityForumPage())),
                            ),
                            _ActionCard(
                              title: 'Adopt & Shop',
                              icon: Icons.store,
                              color: Colors.orange,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdoptionPetShopPage())),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                  }),

                  const SizedBox(height: 18),
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(children: const [Expanded(child: _OverviewCard(icon: Icons.vaccines, title: 'Next Vaccine', color: Colors.orange)), SizedBox(width: 12), Expanded(child: _OverviewCard(icon: Icons.fastfood, title: 'Food Log', color: Colors.green))]),

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
            )
          ],
        ),
      ),
    );
  }
}

// ================== COMPONENTS ==================

// (Old quick-circle button helpers removed; use action cards or direct navigation from actions)

// Quick circle helpers removed — use action cards instead.

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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small stat card used in the header
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.deepPurple, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Horizontal action cards
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({required this.title, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Open', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
