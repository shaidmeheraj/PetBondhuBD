import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'emergency_contact_page.dart';
import 'community_forum_page.dart';
import 'adoption_page.dart';
import 'petshop_page.dart';
import 'find_disease_web.dart';
import 'settings_tab.dart';
import 'chatbot_page.dart';
import 'pet_care_hub.dart';
import '../main.dart';
import 'my_pets_page.dart';

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
  String _name = 'User';
  String _role = 'Pet Lover';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadUserPets();
    _loadProfileMeta();
  }

  Future<List<Map<String, dynamic>>> _loadUserPets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final db = FirebaseFirestore.instance;
      if (user == null) return [];
      // Load user's pets from 'mypet' collection
      final snapshot = await db.collection('mypet').where('ownerId', isEqualTo: user.uid).get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadProfileMeta() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('settings').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name = (data['name'] as String?) ?? _name;
          _role = (data['role'] as String?) ?? _role;
        });
      }
    } catch (_) {
      // silent; keep defaults
    }
  }

  void _onMenuSelected(_DashMenuAction action) {
    switch (action) {
      case _DashMenuAction.editProfile:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsTab()));
        break;
      case _DashMenuAction.toggleTheme:
        setState(() {
          themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        });
        break;
      case _DashMenuAction.toggleNotifications:
        setState(() {
          _notificationsEnabled = !_notificationsEnabled;
        });
        break;
      case _DashMenuAction.changePassword:
        _showChangePasswordDialog();
        break;
      case _DashMenuAction.myPets:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPetsPage()));
        break;
      case _DashMenuAction.myPosts:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('My Posts coming soon')));
        break;
      case _DashMenuAction.myOrders:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('My Orders coming soon')));
        break;
      case _DashMenuAction.logout:
        FirebaseAuth.instance.signOut();
        // It will fall back to auth gate in main.dart (assuming) or user handles manually
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
        break;
    }
  }

  void _showChangePasswordDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(ctrl.text.trim());
                if (mounted) {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Build display lines for Next Vaccine card: PetName: LAST_DATE → NEXT_DATE
  List<String> _buildNextVaccineLines(List<Map<String, dynamic>> pets) {
    String fmt(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final out = <String>[];
    for (final p in pets) {
      if (p['vaccinated'] == true) {
        final name = (p['name'] ?? 'Pet').toString();
        DateTime? last;
        final raw = p['lastVaccinated'] ?? p['vaccinatedAt'] ?? p['createdAt'];
        if (raw is Timestamp) {
          last = raw.toDate();
        } else if (raw is DateTime) {
          last = raw;
        }
        last ??= DateTime.now();
        final next = last.add(const Duration(days: 365));
        out.add('$name: ${fmt(last)} → ${fmt(next)}');
      }
    }
    if (out.isEmpty) out.add('Add vaccine info to pets');
    return out;
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
        leading: PopupMenuButton<_DashMenuAction>(
          icon: Icon(Icons.menu, color: Colors.deepPurple.shade700),
          onSelected: _onMenuSelected,
          itemBuilder: (context) {
            final isDark = themeModeNotifier.value == ThemeMode.dark;
            final List<PopupMenuEntry<_DashMenuAction>> entries = [
              PopupMenuItem(
                value: _DashMenuAction.editProfile,
                child: Row(children: const [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Profile')]),
              ),
              PopupMenuItem(
                value: _DashMenuAction.toggleTheme,
                child: Row(children: [Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20), const SizedBox(width: 8), Text(isDark ? 'Light Theme' : 'Dark Theme')]),
              ),
              PopupMenuItem(
                value: _DashMenuAction.toggleNotifications,
                child: Row(children: [Icon(_notificationsEnabled ? Icons.notifications_active : Icons.notifications_off, size: 20), const SizedBox(width: 8), Text('Notifications: ${_notificationsEnabled ? 'On' : 'Off'}')]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _DashMenuAction.changePassword,
                child: Row(children: const [Icon(Icons.lock, size: 20), SizedBox(width: 8), Text('Change Password')]),
              ),
              PopupMenuItem(
                value: _DashMenuAction.myPets,
                child: Row(children: const [Icon(Icons.pets, size: 20), SizedBox(width: 8), Text('My Pets')]),
              ),
              PopupMenuItem(
                value: _DashMenuAction.myPosts,
                child: Row(children: const [Icon(Icons.forum, size: 20), SizedBox(width: 8), Text('My Posts')]),
              ),
            ];
            if (_role == 'Shop Owner' || _role == 'Admin') {
              entries.add(
                PopupMenuItem(
                  value: _DashMenuAction.myOrders,
                  child: Row(children: const [Icon(Icons.shopping_bag, size: 20), SizedBox(width: 8), Text('My Orders')]),
                ),
              );
            }
            entries.addAll(const [PopupMenuDivider()]);
            entries.add(
              PopupMenuItem(
                value: _DashMenuAction.logout,
                child: Row(children: const [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Logout')]),
              ),
            );
            return entries;
          },
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

              // Build detail lines for dialogs
              final vaccinatedLines = pets
                  .where((p) => (p['vaccinated'] == true))
                  .map((p) => (p['name'] ?? 'Pet').toString())
                  .toList();
              final wellnessLines = pets
                  .where((p) => (p['wellness'] ?? '').toString().toLowerCase() == 'good')
                  .map((p) => (p['name'] ?? 'Pet').toString())
                  .toList();
              final appointmentLines = <String>[];
              for (final p in pets) {
                final name = (p['name'] ?? 'Pet').toString();
                final appts = p['appointments'] as List?;
                if (appts != null && appts.isNotEmpty) {
                  for (final a in appts) {
                    if (a is Map) {
                      final date = a['date'] ?? a['time'] ?? a['scheduled'] ?? 'Appointment';
                      final note = a['note'] ?? a['details'] ?? '';
                      appointmentLines.add('$name: $date${note.toString().isNotEmpty ? ' – $note' : ''}');
                    } else {
                      appointmentLines.add('$name: ${a.toString()}');
                    }
                  }
                }
              }

              void showDetail(String title, List<String> lines) {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(ctx),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (lines.isEmpty)
                              Text('No details found.', style: TextStyle(color: Colors.grey.shade600))
                            else
                              Expanded(
                                child: ListView.separated(
                                  itemCount: lines.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (_, i) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(lines[i]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.verified,
                        title: 'Vaccinated',
                        value: vaccinated.toString(),
                        onTap: () => showDetail('Vaccinated Pets', vaccinatedLines),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.favorite,
                        title: 'Wellness Good',
                        value: wellnessGood.toString(),
                        onTap: () => showDetail('Wellness Good', wellnessLines),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event,
                        title: 'Appointments',
                        value: appointments.toString(),
                        onTap: () => showDetail('Appointments', appointmentLines),
                      ),
                    ),
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
                    final desc = pet['desc']?.toString() ?? 'No recent activity';
                    final img = pet['image']?.toString() ?? '';
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      if (img.isNotEmpty) {
                                        if (img.startsWith('data:')) {
                                          final bytes = base64Decode(img.split(',').last);
                                          return Image.memory(bytes, fit: BoxFit.cover);
                                        } else {
                                          return Image.network(img, fit: BoxFit.cover);
                                        }
                                      }
                                      return const Icon(Icons.pets, size: 56, color: Colors.deepPurple);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(desc, style: const TextStyle(color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final actions = <_QuickAction>[
                        _QuickAction(title: 'Emergency', icon: Icons.local_hospital, color: Colors.redAccent, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyContactPage()))),
                        _QuickAction(title: 'Forum', icon: Icons.forum, color: Colors.deepPurple, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityForumPage()))),
                        _QuickAction(title: 'Adopt', icon: Icons.pets, color: Colors.teal, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdoptionPage()))),
                        _QuickAction(title: 'Pet Shop', icon: Icons.storefront, color: Colors.orange, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetShopPage()))),
                        _QuickAction(title: 'Care Hub', icon: Icons.health_and_safety, color: Colors.indigo, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetCareHub()))),
                      ];
                      // target small square buttons ~72px, wrap to multiple rows if needed
                        final double spacing = 10;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final a in actions)
                            _MiniActionButton(action: a),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _petsFuture,
                    builder: (context, snap) {
                      final pets = snap.data ?? [];
                      final vaccineLines = _buildNextVaccineLines(pets);

                      String foodLogDetailsShort() {
                        if (pets.isEmpty) return 'No pets yet';
                        final count = pets.length;
                        final meals = count <= 2 ? 'Meals: 2 + snack' : 'Meals: 3 daily';
                        return '$meals\nAM: Protein • PM: Light • Eve: Balanced';
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _RichOverviewCard(
                              icon: Icons.vaccines,
                              color: Colors.orange,
                              title: 'Next Vaccine',
                              lines: vaccineLines,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RichOverviewCard(
                              icon: Icons.fastfood,
                              color: Colors.green,
                              title: 'Food Log',
                              lines: foodLogDetailsShort().split('\n'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  const SizedBox(height: 4),
                  const Text('Smart Care Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _SuggestionCard(
                          title: 'Hydration Reminder',
                          subtitle: 'Ensure fresh water is changed twice daily.',
                          icon: Icons.water_drop,
                          color: Colors.teal,
                        ),
                        _SuggestionCard(
                          title: 'Daily Grooming',
                          subtitle: '5 min brushing reduces shedding & stress.',
                          icon: Icons.brush,
                          color: Colors.indigo,
                        ),
                        _SuggestionCard(
                          title: 'Exercise Goal',
                          subtitle: 'Aim for 30 min active play / walks.',
                          icon: Icons.directions_run,
                          color: Colors.orange,
                        ),
                        _SuggestionCard(
                          title: 'Vet Check Cycle',
                          subtitle: 'Schedule annual wellness examination.',
                          icon: Icons.medical_services,
                          color: Colors.deepPurple,
                        ),
                      ],
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

enum _DashMenuAction {
  editProfile,
  toggleTheme,
  toggleNotifications,
  changePassword,
  myPets,
  myPosts,
  myOrders,
  logout,
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.title, required this.icon, required this.color, required this.onTap});
}

// ================== COMPONENTS ==================

// (Old quick-circle button helpers removed; use action cards or direct navigation from actions)

// Quick circle helpers removed — use action cards instead.

// Overview Card for key info

// Small stat card used in the header
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}

// Compact quick action button for responsive layout
class _MiniActionButton extends StatelessWidget {
  final _QuickAction action;
  const _MiniActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, size: 20, color: action.color),
                ),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Rich overview card with multiple detail lines
class _RichOverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  final Color color;
  const _RichOverviewCard({required this.icon, required this.title, required this.lines, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                )
              ],
            ),
            const SizedBox(height: 8),
            for (final l in lines.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(l, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            if (lines.length > 4)
              Text('+ ${lines.length - 4} more', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _SuggestionCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.22), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
