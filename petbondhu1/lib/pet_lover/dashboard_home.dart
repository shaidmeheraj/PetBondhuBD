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
import 'lost_pet_page.dart';
import 'found_pet_page.dart';

class _PetPalette {
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF2AB3A6);
  static const Color accent = Color(0xFFFFB74D);
  static const Color surface = Color(0xFFF5F3FF);
  static const List<List<Color>> gradients = [
    [Color(0xFF6750A4), Color(0xFF2AB3A6)],
    [Color(0xFF4F8EF8), Color(0xFF7BD1EA)],
    [Color(0xFFFF8A65), Color(0xFFFFD54F)],
    [Color(0xFF8E24AA), Color(0xFF9575CD)],
  ];
}

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
          indicatorColor: _PetPalette.primary.withOpacity(32 / 255),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: FontWeight.w700,
              color: states.contains(WidgetState.selected) ? _PetPalette.primary : Colors.black54,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? _PetPalette.primary : Colors.black38,
              size: states.contains(WidgetState.selected) ? 26 : 24,
            ),
          ),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.white,
          elevation: 10,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Care Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'PetBot',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$salutation, $_name';
  }

  IconData _roleIcon() {
    switch (_role.toLowerCase()) {
      case 'admin':
        return Icons.verified_user;
      case 'shop owner':
        return Icons.store_mall_directory;
      default:
        return Icons.favorite;
    }
  }

  LinearGradient _heroGradient(int seed) {
    final bucket = DateTime.now().hour ~/ 6;
    final paletteIndex = (bucket + seed) % _PetPalette.gradients.length;
    final colors = _PetPalette.gradients[paletteIndex];
    return LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  Map<String, int> _computeMetrics(List<Map<String, dynamic>> pets) {
    final vaccinated = pets.where((p) => (p['vaccinated'] == true)).length;
    final appointments = pets.fold<int>(0, (acc, p) {
      final list = p['appointments'] as List<dynamic>?;
      return acc + (list?.length ?? 0);
    });
    final wellnessGood = pets.where((p) => (p['wellness'] ?? '').toString().toLowerCase() == 'good').length;
    return {
      'total': pets.length,
      'vaccinated': vaccinated,
      'appointments': appointments,
      'wellness': wellnessGood,
    };
  }

  List<_SuggestionData> _generateSuggestions(List<Map<String, dynamic>> pets) {
    final metrics = _computeMetrics(pets);
    final total = metrics['total'] ?? 0;
    final vaccinated = metrics['vaccinated'] ?? 0;
    final appointments = metrics['appointments'] ?? 0;
    final wellness = metrics['wellness'] ?? 0;

    final suggestions = <_SuggestionData>[];

    if (total == 0) {
      suggestions.addAll(const [
        _SuggestionData(
          title: 'Add your first pet',
          subtitle: 'Create a profile to unlock personalized reminders and nutrition plans.',
          icon: Icons.assignment_turned_in,
          color: Color(0xFF81C784),
        ),
        _SuggestionData(
          title: 'Explore adoption stories',
          subtitle: 'Meet pets waiting for a new home and mark your favorites.',
          icon: Icons.volunteer_activism,
          color: Color(0xFF9575CD),
        ),
      ]);
      return suggestions;
    }

    if (vaccinated < total) {
      suggestions.add(const _SuggestionData(
        title: 'Vaccination follow-up',
        subtitle: 'Log the latest vaccine doses and set reminders for boosters.',
        icon: Icons.vaccines,
        color: Color(0xFFFFA726),
      ));
    }

    if (appointments == 0) {
      suggestions.add(const _SuggestionData(
        title: 'Schedule a vet check',
        subtitle: 'Routine wellness visits help spot issues earlier and keep insurance valid.',
        icon: Icons.calendar_month,
        color: Color(0xFF4FC3F7),
      ));
    }

    if (wellness < total) {
      suggestions.add(const _SuggestionData(
        title: 'Boost daily enrichment',
        subtitle: 'Add 15 minutes of sensory play or puzzles to reduce stress.',
        icon: Icons.psychology_alt,
        color: Color(0xFFBA68C8),
      ));
    }

    suggestions.add(const _SuggestionData(
      title: 'Hydration and nutrition',
      subtitle: 'Rotate fresh water twice daily and balance meals with light evening feeds.',
      icon: Icons.water_drop,
      color: Color(0xFF4DB6AC),
    ));

    suggestions.add(const _SuggestionData(
      title: 'Capture milestones',
      subtitle: 'Upload today’s happiest moment to build a shared pet journal.',
      icon: Icons.camera_alt,
      color: Color(0xFFFFB74D),
    ));

    return suggestions;
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
      backgroundColor: _PetPalette.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 78,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: PopupMenuButton<_DashMenuAction>(
            offset: const Offset(0, 18),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white,
            onSelected: _onMenuSelected,
            icon: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _PetPalette.gradients[0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
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
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            Text(
              'Let’s take great care of your companions',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _PetPalette.primary.withOpacity(28 / 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_roleIcon(), size: 16, color: _PetPalette.primary),
                      const SizedBox(width: 6),
                      Text(
                        _role,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _PetPalette.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.search, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _petsFuture,
              builder: (context, snapshot) {
                final pets = snapshot.data ?? [];
                final metrics = _computeMetrics(pets);
                final gradient = _heroGradient((metrics['total'] ?? 0) + 1);
                final featurePet = pets.isNotEmpty ? pets[_petIndex % pets.length] : null;
                final featureName = featurePet?['name']?.toString() ?? 'Your next adventure';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x336750A4), blurRadius: 20, offset: Offset(0, 12)),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(60 / 255),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.pets, size: 34, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back, ${widget.userName}',
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        pets.isEmpty
                                            ? 'Add your first companion to unlock health insights and reminders.'
                                            : 'Today is perfect for a quick check on $featureName’s routine.',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _PetPalette.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindDiseasePage())),
                                  icon: const Icon(Icons.monitor_heart),
                                  label: const Text('Health Scan'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _HeroMetricChip(icon: Icons.pets, label: 'Companions', value: metrics['total']?.toString() ?? '0'),
                                _HeroMetricChip(icon: Icons.vaccines, label: 'Vaccinated', value: metrics['vaccinated']?.toString() ?? '0'),
                                _HeroMetricChip(icon: Icons.event_available, label: 'Appointments', value: metrics['appointments']?.toString() ?? '0'),
                                _HeroMetricChip(icon: Icons.favorite, label: 'Wellness good', value: metrics['wellness']?.toString() ?? '0'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
                        icon: Icons.vaccines_outlined,
                        title: 'Vaccinated',
                        value: vaccinated.toString(),
                        onTap: () => showDetail('Vaccinated Pets', vaccinatedLines),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.spa_outlined,
                        title: 'Wellness Good',
                        value: wellnessGood.toString(),
                        onTap: () => showDetail('Wellness Good', wellnessLines),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_available,
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
                    final desc = pet['desc']?.toString() ?? 'No recent activity yet.';
                    final img = pet['image']?.toString() ?? '';
                    final species = (pet['species'] ?? pet['type'] ?? 'Companion').toString();
                    final age = pet['age'];
                    final weight = pet['weight'];
                    final wellness = (pet['wellness'] ?? 'Balanced').toString();
                    final gradient = LinearGradient(
                      colors: _PetPalette.gradients[(index + 1) % _PetPalette.gradients.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );

                    return AnimatedScale(
                      duration: const Duration(milliseconds: 320),
                      scale: _petIndex == index ? 1 : 0.94,
                      curve: Curves.easeOutBack,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: gradient,
                          boxShadow: const [
                            BoxShadow(color: Color(0x226750A4), blurRadius: 18, offset: Offset(0, 10)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(80 / 255),
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
                                      return const Center(
                                        child: Icon(Icons.pets, size: 56, color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 18, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        _InfoChip(icon: Icons.pets, label: species, color: Colors.white),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      desc,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (age != null) _InfoChip(icon: Icons.cake_outlined, label: '${age.toString()} yrs'),
                                        if (weight != null) _InfoChip(icon: Icons.monitor_weight_outlined, label: '${weight.toString()} kg'),
                                        _InfoChip(icon: Icons.favorite_outline, label: wellness),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: _PetPalette.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            elevation: 0,
                                          ),
                                          child: const Text('Profile'),
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                          ),
                                          child: const Text('Care Log'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
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
                        _QuickAction(title: 'Emergency', icon: Icons.medical_services_outlined, color: const Color(0xFFE57373), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyContactPage()))),
                        _QuickAction(title: 'Community', icon: Icons.forum_outlined, color: _PetPalette.primary, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityForumPage()))),
                        _QuickAction(title: 'Adoption', icon: Icons.volunteer_activism_outlined, color: const Color(0xFF4DB6AC), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdoptionPage()))),
                        _QuickAction(title: 'Pet Shop', icon: Icons.shopping_bag_outlined, color: const Color(0xFFFFC178), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetShopPage()))),
                        _QuickAction(title: 'Care Hub', icon: Icons.monitor_heart_outlined, color: const Color(0xFF7986CB), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetCareHub()))),
                        _QuickAction(title: 'Lost Pet', icon: Icons.search, color: const Color(0xFFEF9A9A), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LostPetPage()))),
                        _QuickAction(title: 'Found Pet', icon: Icons.favorite_outline, color: const Color(0xFFA5D6A7), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoundPetPage()))),
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
                    height: 150,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _petsFuture,
                      builder: (context, snapshot) {
                        final suggestions = _generateSuggestions(snapshot.data ?? []);
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return _SuggestionCard(
                              title: suggestion.title,
                              subtitle: suggestion.subtitle,
                              icon: suggestion.icon,
                              color: suggestion.color,
                            );
                          },
                        );
                      },
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

class _SuggestionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SuggestionData({required this.title, required this.subtitle, required this.icon, required this.color});
}

// ================== COMPONENTS ==================

class _HeroMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroMetricChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(40 / 255),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(56 / 255)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            _PetPalette.primary.withOpacity(30 / 255),
            _PetPalette.secondary.withOpacity(26 / 255),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x1A6750A4), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(180 / 255),
            ),
            child: Icon(icon, color: _PetPalette.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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
      width: 96,
      height: 96,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  action.color.withOpacity(80 / 255),
                  action.color.withOpacity(36 / 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: action.color.withOpacity(96 / 255)),
              boxShadow: [
                BoxShadow(color: action.color.withOpacity(64 / 255), blurRadius: 14, offset: const Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(210 / 255),
                  ),
                  child: Icon(action.icon, size: 22, color: action.color),
                ),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final Color baseColor;
    final Color textColor;
    if (color != null) {
      baseColor = color!;
      textColor = color!.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
    } else {
      baseColor = const Color(0xFF212121).withAlpha(210);
      textColor = const Color(0xFF212121);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color.withAlpha(48), color.withAlpha(24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withAlpha(72)),
        boxShadow: [
          BoxShadow(color: color.withAlpha(64), blurRadius: 16, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withAlpha(190), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (lines.length > 4)
            Text(
              '+ ${lines.length - 4} more',
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
        ],
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
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(56), borderRadius: BorderRadius.circular(14)),
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
