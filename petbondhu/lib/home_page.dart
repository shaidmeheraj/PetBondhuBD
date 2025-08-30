import 'package:flutter/material.dart';
import 'dashboard_home.dart'; // Import the DashboardHome widget
import 'pet_profile_tab.dart'; // Import the PetProfileTab widget
import 'reminders_tab.dart'; // Import the RemindersTab widget
import 'pet_tips_tab.dart'; // Import the PetTipsTab widget
import 'settings_tab.dart'; // Import the SettingsTab widget

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    // Home Tab (Dashboard)
    DashboardHome(),
    const PetProfileTab(),
    const RemindersTab(),
    const PetTipsTab(),
    const SettingsTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pet Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Pet Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
