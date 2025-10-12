import 'package:flutter/material.dart';
import 'dashboard_home.dart'; // Import the DashboardHome widget
import 'reminders_tab.dart'; // Import the RemindersTab widget
import 'pet_tips_tab.dart'; // Import the PetTipsTab widget
import 'settings_tab.dart'; // Import the SettingsTab widget
import 'find_disease.dart'; // Import the Find Disease page/tab


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PetLoverHomePage extends StatefulWidget {
  const PetLoverHomePage({super.key});

  @override
  State<PetLoverHomePage> createState() => _PetLoverHomePageState();
}

class _PetLoverHomePageState extends State<PetLoverHomePage> {
  int _selectedIndex = 0;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        role = doc.data()?['role'] ?? 'Pet Lover';
        isLoading = false;
      });
    } else {
      setState(() {
        role = 'Pet Lover';
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      // Home tab with Bengali header and instructions
      Column(
        children: [
          Container(
            color: Colors.deepPurple,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
              ],
            ),
          ),
          Expanded(child: DashboardHome(userName: FirebaseAuth.instance.currentUser?.email ?? "User", role: role ?? "Pet Lover")),
        ],
      ),
  const FindDiseasePage(),
      const RemindersTab(),
      const PetTipsTab(),
      SettingsTab(role: role ?? "Pet Lover"),
    ];

    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.pets),
        label: 'Find Disease',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.medical_services),
        label: 'Reminders',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book),
        label: 'Pet Tips',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    final showNavbar = role == 'Pet Lover' || role == 'Shop Owner' || role == null;
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: showNavbar
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              items: items,
            )
          : null,
    );
  }
}
